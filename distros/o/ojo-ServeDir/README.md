(M)ojo::ServeDir
================

[![Build Status](https://travis-ci.org/memowe/Mojo-ServeDir.svg?branch=master)](https://travis-ci.org/memowe/Mojo-ServeDir)

Helper module to serve files from the current working directory. Module usage:

```bash
$ perl -Mojo::ServeDir
```

Command usage:

```bash
$ serve_dir DIRECTORY DAEMON_OPTIONS
```

INSTALLATION
------------

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc ojo::ServeDir

CONTRIBUTORS
------------

- Mohammad S Anwar

LICENSE AND COPYRIGHT
---------------------

This software is Copyright (c) by [Mirko Westermeier][mirko] ([\@memowe][mgh], [mirko@westermeier.de][mmail]).

Released under the MIT (X11) license. See [LICENSE][mit] for details.

[mirko]: http://mirko.westermeier.de
[mgh]: https://github.com/memowe
[mmail]: mailto:mirko@westermeier.de
[mit]: LICENSE
