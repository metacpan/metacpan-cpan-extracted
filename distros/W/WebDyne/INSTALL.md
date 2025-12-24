INSTALL

# Installation via CPAN #

You can install the base WebDyne module, and all prerequisites, with:  

    $ perl -MCPAN -e 'install WebDyne'

 or alternatively on modern systems:  

    $ cpanm WebDyne

 This assumes you have already setup and initialised CPAN appropriately for your environment. Note that WebDyne will not be automatically usable after this \- you must modify your Web server
 configuration to make it active or install the Plack PSGI version \(see below). You may do this manually \(referring to the documentation available in the doc directory, or at  [https://webdyne.org](https://webdyne.org) ) or via an installer module which will do the work for you. 

# Installation of the PSGI \(Plack) version #

To use the PSGI version of WebDyne install the Plack module via:  

    $ cpanm Plack

  You can then start the WebDyne server via the command  

    $ webdyne.psgi --test

  To validate it is working. See instruction at  [https://webdyne.org](https://webdyne.org)  for additional usage information

# Installation of the Apache Version #

The base WebDyne module comes with an installer module for Apache. It will be installed into whichever bin location \(usually  `/usr/local/bin` ) your CPAN configuration defaults to. You can run the installer with the command:  

    $ wdapacheinit

 It will use reasonable defaults to try and locate and update your Apache config, Webdyne cache dir. etc. If you need to alter the defaults run  `wdapacheinit --help`  to review options

# Installation via Manual Build #

You can download and install the base WebDyne module with the following commands after it is unpacked:  

    $ perl Makefile.PL
    $ make 
    $ make test 
    $ make install

 You will need to download and install all prerequisite modules manually. Modules required should be listed when you run the  `perl Makefile.PL`  command. Similarly to the CPAN install you will either need to adjust your Web server configuration manually to serve WebDyne pages, or run/download the appropriate installer or Plack
 module.