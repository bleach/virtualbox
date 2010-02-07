# VirtualBox Ruby Gem

The VirtualBox ruby gem is a library which allows anyone to control VirtualBox
from ruby code! Create, destroy, start, stop, suspend, and resume virtual machines.
Also list virtual machines, list hard drives, network devices, etc.

## Installation and Requirements

First you need to install [VirtualBox](http://www.virtualbox.org/) which is available for
Windows, Linux, and OS X. After installation, install the gem:

    sudo gem install virtualbox

The gem assumes that `VBoxManage` will be available on the `PATH`. If not, before using
the gem, you must set the path to your `VBoxManage` binary:

    VirtualBox::Command.vboxmanage = "/path/to/my/VBoxManage"

## Basic Usage

The virtualbox gem is modeled after ActiveRecord. If you've used ActiveRecord, you'll
feel very comfortable using the virtualbox gem.

There is a [quick getting started guide](http://mitchellh.github.com/virtualbox/file.GettingStarted.html) to
get you acquainted with the conventions of the virtualbox gem.

Complete documentation can be found at [http://mitchellh.github.com/virtualbox](http://mitchellh.github.com/virtualbox).

Below are some examples:

    require 'virtualbox'

    vm = VirtualBox::VM.find("my-vm")

    # Let's first print out some basic info about the VM
    puts "Memory: #{vm.memory}"

    vm.storage_controllers.each do |sc|
      sc.attached_devices.each do |device|
        puts "Attached Device: #{device.uuid}"
      end
    end

    # Let's modify the memory and name...
    vm.memory = 360
    vm.name = "my-renamed-vm"

    # Save it!
    vm.save

Or here is an example of creating a hard drive:

    require 'virtualbox'

    hd = VirtualBox::HardDrive.new
    hd.location = "foo.vdi"
    hd.size = 2000 # megabytes
    hd.save

## Known Issues or Uncompleted Features

VirtualBox has a _ton_ of features! As such, this gem is still not totally complete.
You can see the features that are still left to do in the TODO file.

## Reporting Bugs or Feature Requests

Please use the [issue tracker](https://github.com/mitchellh/virtualbox/issues).

## Contributing

If you'd like to contribute to VirtualBox, the first step to developing is to
clone this repo, get [bundler](http://github.com/carlhuda/bundler) if you
don't have it already, and do the following:

    bundle install
    bundle lock
    rake

This will run the test suite, which should come back all green! Then you're good to go!