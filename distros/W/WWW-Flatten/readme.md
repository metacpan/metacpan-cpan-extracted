WWW::Flatten
---------------

__This software is considered to be alpha quality and isn't recommended for
regular usage.__

WWW::Flatten is a web crawling tool for freezing pages into standalone.
I believe this works better than wget or "Saving as, complete" in browsers.

- Covers assets beyond CSSs.
- Publish-ready name of files.

## INSTALLATION

    $ cpanm WWW::Flatten

## USAGE

wwwflatten command is available. You can brows out directory localy or upload it
to web servers as is.

    $ wwwflatten --basedir ./out/ http://github.com/

Or the following example generates mojolicious app at once.

    $ wwwflatten --mojo-app --basedir ./out/ http://github.com/
    $ ./out/myapp.pl daemon

Then you can see the archive in browser with port 3000

    http://127.0.0.1:3000/

The app is also portable so it can be deployed to app servers.

See also [Command line API]

[Command line API]:http://search.cpan.org/perldoc?wwwflatten

## CLASS USAGE

This tool is powerd by a class based perl module included in the repository.
With the module, you can easily make a custom ruling crawler for your demand.

See also [WWW::Flatten] API

[WWW::Flatten]:http://search.cpan.org/perldoc?WWW::Flatten

## REPOSITORY

[https://github.com/jamadam/WWW-Flatten]
[https://github.com/jamadam/WWW-Flatten]:https://github.com/jamadam/WWW-Flatten

## SEE ALSO

[https://github.com/jamadam/WWW-Crawler-Mojo]
[https://github.com/jamadam/WWW-Crawler-Mojo]:https://github.com/jamadam/WWW-Crawler-Mojo

## COPYRIGHT AND LICENSE

Copyright (c) [jamadam]

This program is free software; you can redistribute it and/or
modify it under the [same terms as Perl itself].

[jamadam]: http://blog2.jamadam.com/
[same terms as Perl itself]:http://dev.perl.org/licenses/
