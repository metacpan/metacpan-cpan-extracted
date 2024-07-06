# Text::Template::Tiny

![Version](https://img.shields.io/github/v/release/sciurius//perl-Text-Template-Tiny)
![GitHub issues](https://img.shields.io/github/issues/sciurius//perl-Text-Template-Tiny)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
![Language Perl](https://img.shields.io/badge/Language-Perl-blue)

This is a very small and limited template processor. The only thing it
can do is substitute variables in a text.

Often that is all you need :-).

# EXAMPLE

    use Text::Template::Tiny;

    # Create a template processor, with preset subtitutions.
    my $xp = Text::Template::Tiny->new(
      home    => $ENV{HOME},
      lib     => {
	      dev => "/tmp/mylib",
	      std => "/etc/mylib",
	  },
      version => 1.02,
    );

    # Add some more substitutions.
    $xp->add( app => "MyApp" );

    # Apply it.
    print $xp->expand(<<EOD);
    For [% app %] version [% version %], the home of all operations
    will be [% home %], and the library is [% lib.std %].
    EOD

    # Same, with additional substitutions for this call only.
    print $xp->expand( <<EOD, { app => "ThisApp" } );
    For [% app %] version [% version %], the home of all operations
    will be [% home %], and the library is [% lib.std %].
    EOD

# INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION


Development of this module takes place on GitHub:
https://github.com/sciurius//perl-Text-Template-Tiny.

You can find documentation for this module with the perldoc command.

    perldoc Text::Template::Tiny

Please report any bugs or feature requests using the issue tracker on
GitHub.

    Search CPAN
        http://search.cpan.org/dist/Text-Template-Tiny


COPYRIGHT AND LICENCE

Copyright (C) 2008,2024 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

