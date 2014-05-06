include_recipe "git"
include_recipe "python"
include_recipe "postgresql::server"
include_recipe "postgresql::libpq"
include_recipe "java"

USER = node[:user]
REPOSITORY = node[:repository]
HOME = "/home/#{USER}"
ENV['VIRTUAL_ENV'] = "#{HOME}/pyenv"
ENV['PATH'] = "#{ENV['VIRTUAL_ENV']}/bin:#{ENV['PATH']}"
SOURCE_DIR = "#{ENV['VIRTUAL_ENV']}/src"
CKAN_DIR = "#{SOURCE_DIR}/ckan"

# Create user
user USER do
  home HOME
  supports :manage_home => true
end

# Install Python
python_virtualenv ENV['VIRTUAL_ENV'] do
  interpreter "python2.7"
  owner USER
  group USER
  options "--no-site-packages"
  action :create
end

# Create source dir
directory SOURCE_DIR do
  owner USER
  group USER
end

# Clone CKAN
git CKAN_DIR do
  user USER
  group USER
  repository REPOSITORY
  reference "5df8e6492bdd32862b159d6bc9ff99892973dde6" #@2.2
  enable_submodules true
end

# # Patch: 
# https://github.com/ckan/ckan/pull/291
#execute "Apply patch to a CKAN submodule..." do
#  cwd CKAN_DIR
 # command "patch -p1 ckanext/stats/__init__.py < ~/diff.patch"
#end

# Install CKAN Package
python_pip CKAN_DIR do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
  options "--exists-action=i -e"
  action :install
end

# Install CKAN's requirements
python_pip "#{CKAN_DIR}/pip-requirements-docs.txt" do
  user USER
  group USER
  virtualenv ENV['VIRTUAL_ENV']
  options "-r"
  action :install
end

# Create Database
pg_user "ckanuser" do
  privileges :superuser => true, :createdb => true, :login => true
  password "pass"
end

pg_database "ckan_dev" do
  owner "ckanuser"
  encoding "utf8"
  locale "en_US.utf8"
  template "template0"
end

execute "Create development ini file" do
  user USER
  cwd CKAN_DIR
  command "paster make-config ckan /home/vagrant/pyenv/src/ckan/development.ini"
end

# Configure database variables
execute "Set up database's urls" do
  user USER
  cwd CKAN_DIR
  command "sed -i -e 's/.*sqlalchemy.url.*/sqlalchemy.url=postgresql:\\/\\/ckanuser:pass@localhost\\/ckan_dev/;' development.ini"
end

# Install and configure Solr
package "solr-jetty"
template "/etc/default/jetty" do
  variables({
    :java_home => node["java"]["java_home"]
  })
end
execute "setup solr's schema" do
  command "sudo ln -f -s #{CKAN_DIR}/ckan/config/solr/schema-2.0.xml /etc/solr/conf/schema.xml"
  action :run
end

service "jetty" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end

# Create configuration file
execute "make paster's config file and setup solr_url and ckan.site_id" do
  user USER
  cwd CKAN_DIR
  command "paster make-config ckan development.ini --no-interactive && sed -i -e 's/.*solr_url.*/solr_url=http:\\/\\/127.0.0.1:8983\\/solr/;s/.*ckan\\.site_id.*/ckan.site_id=vagrant_ckan/' development.ini"
  creates "#{CKAN_DIR}/development.ini"
end

# Generate database
execute "create database tables" do
  user USER
  cwd CKAN_DIR
  command "paster --plugin=ckan db init"
end

# These don't work.
# execute "running tests with SQLite" do
#   user USER
#   cwd CKAN_DIR
#   command "nosetests --ckan ckan"
# end
