# NAME

Test::WWW::Mechanize::Dancer - Wrapper to easily use Test::WWW::Mechanize with your Dancer apps

# VERSION

version 0.0100

# SYNOPSIS

    use MyDancerApp;
    use Test::WWW::Mechanize::Dancer;

    # Get your standard Test::WWW::Mechanize object
    my $mech = Test::WWW::Mechanize::Dancer->new(
        # settings here if required
    )->mech;
    # Run standard Test::WWW::Mechanize tests
    $mech->get_ok('/');

# DESCRIPTION

This is a simple wrapper that lets you test your Dancer apps using
Test::WWW::Mechanize.

# SETTINGS

## appdir

Probably the main thing you will want to set, `appdir` sets the base
directory for the app.  `confdir`, `views`, and `public`, will be 
set to `appdir`, `appdir`/views, and `appdir`/public
respectively if not set explicitly.

The `appdir` defaults to the current working directory, which works
in most testing cases.

## agent

Allows you to set the user agent of the Mechanizer.

## confdir

Set the dancer confdir.  Will default to appdir if unspecified.

## envdir

Allows you to set the directory where Dancer should look for the config files
for each environment.  Defaults to 'environments' under appdir.  Note if your
app uses $ENV{DANCER\_ENVDIR} you should explicitly pass that value using this
option.

## environment

Allows you to set the Dancer environment to run your app in.  Defaults to
'test'

## mech\_class

Allows you to override the class used to instantiate the user agent object.
Use this to invoke your own class with project-specific test-helper methods.
Defaults to 'Test::WWW::Mechanize::PSGI' - which your class should inherit
from.  Note, it is your responsibility to 'require' the class.

## public

Set the public directory for your dancer app.  Defaults to `appdir`/public

## views

Set the views directory for your dancer app.  Defaults to `appdir`/views

# AUTHORS

- William Wolf <throughnothing@gmail.com>
- Grant McLean <grantm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by William Wolf.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
