# WWW-PushBullet [![Build Status](https://secure.travis-ci.org/sebthebert/WWW-PushBullet.png?branch=master)](http://travis-ci.org/sebthebert/WWW-PushBullet) [![Coverage Status](https://coveralls.io/repos/sebthebert/WWW-PushBullet/badge.png)](https://coveralls.io/r/sebthebert/WWW-PushBullet)

# About

This is a Perl module and program giving easy access to [PushBullet](https://www.pushbullet.com/) API from Perl.


# Installation

## Requirements

You need a PushBullet API key. 
You can get your API key in your [PushBullet account settings](https://www.pushbullet.com/account).

You also need this Perl modules:

  * [Data::Dump](https://metacpan.org/release/Data-Dump)
  * [File::Slurp](https://metacpan.org/release/File-Slurp)
  * [FindBin](https://metacpan.org/pod/FindBin)
  * [Getopt::Long](https://metacpan.org/release/Getopt-Long)
  * [JSON](https://metacpan.org/release/JSON)
  * [LWP](https://metacpan.org/release/libwww-perl)
  * [Pod::Usage](https://metacpan.org/release/Pod-Usage)

## Manual installation

Get the latest release of WWW::PushBullet on GitHub.

    https://github.com/sebthebert/WWW-PushBullet/releases
    
Extract sources from the file you get:

    tar xvfz WWW-PushBullet-<version>.tar.gz
    
Generate a Makefile:

    cd WWW-PushBullet-<version>
    perl Makefile.PL 

Install the package:
    
    make
    make test
    make install

## Installation from CPAN Minus

The easiest way to install WWW::PushBullet is [CPAN Minus](https://github.com/miyagawa/cpanminus):

    cpanm WWW::PushBullet


# Usage

    pushbullet address [ -k <pushbullet_apikey> ] [ -d <device_iden> ]
        --name 'address name' --address 'complete address'
    
    pushbullet contacts [ -k <pushbullet_apikey> ]
    
    pushbullet devices [ -k <pushbullet_apikey> ]
    
    pushbullet file [ -k <pushbullet_apikey> ] [ -d <device_iden> ] 
        --file filename [ --body 'file description' ]
    
    pushbullet link [ -k <pushbullet_apikey> ] [ -d <device_iden> ]
        --title 'your title' --url 'http://address'
    
    pushbullet list [ -k <pushbullet_apikey> ] [ -d <device_iden> ]
        --title 'your title' --item item1 --item item2 --item item3
    
    pushbullet note [ -k <pushbullet_apikey> ] [ -d <device_iden> ]
        --title 'your title' --body 'your body message'

To obtain the complete list of pushbullet command options:

    pushbullet --help


# Configuration

You can configure default parameters in a JSON format configuration file:

    {
        "apikey":"",
        "proxy":"",
        "default_device_iden":[],
        "default_address":"1600 Amphitheatre Pkwy, Mountain View, CA 94043, Etats-Unis",
        "default_body":"This is a default title",
        "default_name":"GooglePlex",
        "default_title":"This is a default title",
        "default_url":"https://github.com/sebthebert/WWW-PushBullet"
    }

This configuration file is by default **./conf/pushbullet.json** but you can also specify another file with the **-c/--config** option.

If you don't specify device_iden (**-d/--device** or in configuration file), it will **push to all devices** of this apikey account.
