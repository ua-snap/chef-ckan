Chef-CKAN
=========

This project builds a Virtual Machine with the latest CKAN ready to go. This is
only intended for development.

## Quickstart

Install [Vagrant](http://www.vagrantup.com/), clone this repository, then:

    $ vagrant up

This will download the VM image, install and configure CKAN and all its
dependencies, and run its tests. Go grab a coffee and let it run.

Caveats:

 * Current-ish (~2.2) build is [broken](https://github.com/ckan/ckan/pull/291), so let the provisioner fail, then copy the ```diff.patch``` file in this repo to the ```/root``` director of the VM and run ```vagrant provision``` again.  It should complete.
 * This provisioning cycle needs to be improved to work against CKAN master.
 * The nosetests mostly fail.
 * Local file storage isn't set up (?).

## Running the CKAN instance

After it's finished, do:

```bash
    $ vagrant ssh
    $ source ~/pyenv/bin/activate
    $ cd ~/pyenv/src/ckan
    $ paster serve development.ini
```

You can check http://localhost:5000 to see if everything went well. You should
see your newly created CKAN installation. Now you can start playing :)

I would start creating an admin user. Follow CKAN's [Post-Installation
Setup](http://docs.ckan.org/en/ckan-1.8/post-installation.html). 

Enjoy!
