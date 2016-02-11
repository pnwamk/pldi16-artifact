# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT

sudo apt-get update
sudo apt-get install -y git 

wget http://mirror.racket-lang.org/installers/6.2.1/racket-minimal-6.2.1-i386-linux-ubuntu-precise.sh

sh racket-minimal-6.2.1-i386-linux-ubuntu-precise.sh --dest ./racket-6.2.1

export PATH=$PATH:`pwd`/racket-6.2.1/bin/

racket -v # print version

raco pkg install --multi-clone convert --auto --clone typed-racket git://github.com/andmkent/typed-racket?path=typed-racket-lib#rtr-prototype
raco pkg install --auto --clone math git://github.com/dkempe/math?path=math-lib
raco pkg install --auto --clone math git://github.com/dkempe/math?path=math-test

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise32"
  config.vm.provision "shell",  inline: $script, :privileged => false
end
