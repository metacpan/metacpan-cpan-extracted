# Win32-SqlServer-DTS

Although it's possible to use all features here by using only [Win32::OLE](https://github.com/jandubois/win32-ole) module, Win32-SqlServer-DTS (being more specific, it's childs classes) provides a much easier interface (pure Perl) and (hopefully) a better documentation. 
Since it's build over Win32::OLE module, Win32-SqlServer-DTS will only work with ActivePerl distribution running in a Microsoft Windows operational system.

The API for this class will give only read access to a package attributes. No write methods are available are directly available at this time, but could be executed since at each Win32-SqlServer-DTS object created a related object is passed as an reference to new object. This related object is a MS SQL Server Win32-SqlServer-DTS object and has all methods and properties as defined by the MS API. This object reference is kept as an "private" property called sibling and generally can be obtained with a get_sibling method call. Once the reference is recovered, all methods from it are available.

## Why having all this trouble?

You may be asking yourself why having all this trouble to write such API as an layer to access data thought [Win32::OLE](https://github.com/jandubois/win32-ole) module.

The very simple reason is: MS SQL Server 2000 API is terrible to work with (lots and lots of indirection), the documentation is not as good as it should be and one has to convert examples from it of VBScript code to Perl. 
Win32-SqlServer-DTS API was created to provide an easier (and more "perlish") way to fetch data from a MS SQL Server DTS package. One can use this API to easily create reports or implement automatic tests using a module as [Test::More](http://github.com/Test-More/test-more/) (see EXAMPLES directory in the tarball distribution of this module).

## Installation

To install this module type the following:

```
perl Makefile.PL
make
make test
make install
```

## Enabling extended tests

Extended tests will connect to a MS SQL Server database to fetch Win32-SqlServer-DTS package information and therefore tests the methods.

Enabling extended test is a good idea: in fact, executing only the simple tests will not test much thing and mocking Win32-SqlServer-DTS objects is not a simple task. If you're going to extended or modify the Win32-SqlServer-DTS API, is a very good idea to enable extended tests.

To enable the extended tests is necessary to:

1. Save the DTS package sample ("test_all.dts") that comes with the module tarball in the database.
2. Edit the XML file "test-config.xml". If your server uses trusted method to authenticate then the only thing that needs to be edit is the servername. Otherwise, add the <user>user</user> and <password>password</password> inside the "credential" tag. Of course, do not forget to use valid user and password information. The "test_conf.dtd" should help you a bit if you are able to use a XML validator.

## Dependencies

This module requires these other modules to work:

- Carp
- Class::Accessor
- Data::Dumper
- Win32::OLE
- Hash::Util
- XML::Simple

## Support and documentation

After installing, you can find documentation for this module with the perldoc command.

```
perldoc Win32::SqlServer::DTS
```
## Copyright and licence

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

