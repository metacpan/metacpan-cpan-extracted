This is the Windows formatted version of the file 'README'.

+----------------------------------------------------------------------+
| new.spirit                                                           |
| Copyright (c) 1999-2001 dimedis GmbH, All Rights Reserved            |
+----------------------------------------------------------------------+
| new.spirit is free Perl software; you can redistribute it and/or     |
| modify it under the same terms as Perl itself.                       |
+----------------------------------------------------------------------+

$Id: README,v 1.7 2003/08/07 08:32:42 joern Exp $

new.spirit is a Perl based software development environment for creating
powerful dynamic databased web applications. It runs on any Perl enabled
server system. You access new.spirit through any JavaScript enabled
internet browser.


PREREQUISITS:
-------------
  - Perl 5.004_04 or higher
    (tested under Versions 5.004_04, 5.005_03, 5.6.0 and
     ActiveState Perl Build 519 on Windows NT 4.0).
     Refer to the release notes for platform specific hints.

  - You will need the following Perl Modules
    - GDBM_File or DB_File or SDBM_File (not recommended)
    - CIPP Version 2.27 or higher
    - DBI version 0.97 or higher
    - a appropriate DBD module for your database architecture

    All these modules are available on CPAN (http://www.cpan.org/).
    Some modules are shipped with new.spirit, as source code tarballs.
    They may be outdated but are tested in our development environment.
    They are located in the perlmodules directory of this distribution.

  - A webserver with CGI support. Apache is recommended.


UNIX INSTALLATION INSTRUCTIONS:
-------------------------------

- Copy the tar.gz distribution file to a place on your
  server, e.g. /tmp/new.spirit-x.x.x.x.tar.gz

- Create a user and group for all new.spirit files,
  for example 'spirit:spirit' (or decide which existent
  user should own the new.spirit files).

- Decide, where new.spirit should be installed,
  for example '/usr/local/new.spirit'

- Switch to user 'root' and follow these steps:

    cd /usr/local
    mkdir new.spirit
    chown spirit:spirit new.spirit
    chmod 770 new.spirit
    chmod g+s new.spirit

- Now switch to user 'spirit' and extract the tar file.

    su spirit
    cd /usr/local
    tar xvfz /tmp/new.spirit-x.x.x.x.tar.gz

- Now install all Perl modules needed by new.spirit, unless
  they are already installed. Most likely you need to install
  CIPP, which is shipped with new.spirit, inside the
  perlmodules directory:
  
    cd new.spirit/perlmodules
    tar xvfz CIPP-x.xx.tar.gz
    cd CIPP-x-xx
    perl Makefile.PL
    make test
    su
    make install
    exit

- If all Perl modules are installed, change as user spirit to
  the new.spirit main directory and execute the installation program:
  
    cd ../..
    perl install.pl

- Follow the instructions of the installer. The program will ask
  you for the webserver mappings, under which the new.spirit htdocs
  and cgi-bin directories are accessable. It also checks, if all
  Perl modules needed by new.spirit are installed on your system.
  If modules are missing, please install them and start the installer
  again.
  
  The installer initializes the ./etc/passwd file with the spirit
  account (password is 'spirit'), if it does not already exist.
  The first thing you should do after logging into new.spirit is
  changing this default password to somewhat safer.
  
  You can start the installer any time to change the webserver
  mappings or to create a new etc/passwd file (using the -p
  option). "perl install.pl --help" give more information about
  possible command line options.
  
- Configure your webserver according to the information you gave
  the installer. The webserver process must run at least with the
  group id of the new.spirit files, because new.spirit needs write
  access to some of its files.

- Restart your webserver. Now you can access new.spirit under the
  htdocs Mapping you configured using the installer. Login as
  user 'spirit', password 'spirit' and change the password. Create
  a project and have fun! ;)
  

WINDOWS INSTALLATION INSTRUCTIONS:
----------------------------------

- Copy the .zip or .tar.gz distribution file to a place on your
  server, e.g. /tmp/new.spirit-x.x.x.x.zip

- Extract the archive to a directory, where new.spirit should
  reside. Please note, that the archive is already prefixed with
  the directory 'new.spirit'.

- Install the Perl modules needed by new.spirit, e.g. CIPP.
  Refer to the Unix instructions above for details.

- Change to the new.spirit directory and execute the installer
  using 'perl install.pl'. Please refer to the UNIX chapter
  of install.pl above for further details.

- Configure your webserver according to the information you gave
  the installer. Ensure that files with the extension .cgi are
  executed by the Perl interpreter and that the webserver process
  has write access to all files in the new.spirit directory.

- Restart your webserver. Now you can access new.spirit under the
  htdocs Mapping you configured using the installer. Login as
  user 'spirit', password 'spirit' and change the password. Create
  a project and have fun! ;)


