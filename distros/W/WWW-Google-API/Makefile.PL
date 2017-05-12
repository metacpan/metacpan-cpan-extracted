use strict;
use warnings;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name            ('WWW-Google-API');
author          ('John Cappiello <jcap@cpan.org>');
license         ('perl');
version_from    ('lib/WWW/Google/API.pm');

# Dependencies
requires('Class::Accessor'   => 0.00);
requires('HTTP::Request'     => 0.00);
requires('LWP::UserAgent'    => 0.00);
requires('XML::Atom::Entry'  => 0.00);
requires('XML::Atom::Util'   => 0.00);
requires('YAML::Syck'        => 0.00);
requires('Test::Deep'        => 0.00);

if (!-e $ENV{HOME}."/.gapi") {
  $ENV{GAPI_KEY}  = prompt("Google API Key:") if not $ENV{GAPI_KEY};
  $ENV{GAPI_USER} = prompt("Google API User:") if not $ENV{GAPI_USER};
  $ENV{GAPI_PASS} = prompt("Google API Pass:") if not $ENV{GAPI_PASS};
}

WriteAll;
