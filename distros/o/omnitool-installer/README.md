# NAME

omnitool::installer - Install the OmniTool Web Application Framework

Provides the 'omnitool\_installer' script to install OmniTool on your system.

# SYNOPSIS

    # To provide installation details interactively then install:
    omnitool_installer

    # Safer approach: provide the installation details interactively and save config file:
    omnitool_installer --save-config-file-only=/some/path/ot_install.config
    # then run
    omnitool_installer --config-file=/some/path/ot_install.config

        # Be sure to delete/protect ot_install.config

    # To see help and exit:
    omnitool_installer --help

# DESCRIPTION

OmniTool allows you to build web application suites very quickly and with minimal code.  It is
designed to simplify and speed up the development process, reducing code requirements to only
the specific features and logic for the target application.  The resulting applications are
mobile-responsive and API-enabled with no extra work by the developers.

For lots more information on how this works, including demos, examples, and lots of documentation,
please visit [http://www.omnitool.org/](http://www.omnitool.org/)

The GitHub Repo for OmniTool is [https://github.com/ericschernoff/omnitool](https://github.com/ericschernoff/omnitool)

## PREREQUISITES

OmniTool has been developed and tested with the following base components:

- - Ubuntu 16.04 Server
- - Perl 5.22
- - Git 2.10
- - MySQL 5.7 or MariaDB 10.3 (at least the client libraries if separate DB server)
- - Apache 2.4

You can very likely make it work on FreeBSD 10.1+ or a recent release of RHEL, Fedora, or CentOS.  I am not able
to provide detailed instructions on each of these -- volunteers would be very welcome!

Prior to installation, the following packages will need to be installed via 'sudo apt install':

- - build-essential
- - zlib1g-dev
- - libssl-dev
- - cpanminus
- - perl-doc
- - mysql-server
- - libmysqlclient-dev
- - apache2

Then, you will need to enable a few Apache modules:

> sudo a2enmod proxy ssl headers proxy\_http rewrite

Again, these are Ubuntu 16.04 commands.  I am quite sure you can make this work with the other BSD, Linux
flavors, as well as with Nginix instead of Apache if you prefer.

## ACKNOWLEDGEMENTS

I am very appreciative to my employer, Cisco Systems, Inc., for allowing this software to be
released to the community as open source.  (IP Central ID: 153330984).

I am also grateful to Mohsen Hosseini for allowing me to include his most excellent Ace
Admin as part of this software.

# LICENSE

MIT License

Copyright (c) 2017 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# AUTHOR

Eric Chernoff &lt;ericschernoff@gmail.com>
