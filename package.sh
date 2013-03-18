#!/bin/bash
vagrant package --vagrantfile Vagrantfile.pkg --include plugin/symfony.rb,plugin/commands.rb --output symfony.box
