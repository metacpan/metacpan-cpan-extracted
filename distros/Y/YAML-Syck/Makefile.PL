use strict;
use lib '.';
use inc::Module::Install;

my $bad;
if (eval { require YAML; $YAML::VERSION < 0.60 }) {
    print "*** Pre-0.60 version of YAML.pm ($YAML::VERSION) detected.\n";
    $bad++;
}
if (eval { require YAML::Syck; $YAML::Syck::VERSION < 0.60 }) {
    print "*** Pre-0.60 version of YAML::Syck ($YAML::Syck::VERSION) detected.\n";
    $bad++;
}

if ($bad and !is_admin()) {
    print << '_';

*** WARNING ***

YAML::Syck version >=0.60 breaks compatibility with earlier versions of
YAML::Syck and YAML.pm (<0.60) when serializing blessed references.

See the COMPATIBILITY file for more information.

_

    exit() unless prompt("Continue installing YAML::Syck?", 'y') =~ /^y/i;
}

name            'YAML-Syck';
license         'MIT';
all_from        'lib/YAML/Syck.pm';
cc_inc_paths    '.';
cc_files        (glob("*.c"), (-e 'Syck.c' ? () : 'Syck.c'));

# cc_optimize_flags '-g3';

can_cc or die "This module requires a C compiler";

include_deps    'Test::More';
build_requires  'Devel::Leak' if defined $ENV{'AUTOMATED_TESTING'};
homepage        'http://search.cpan.org/dist/YAML-Syck';
repository      'http://github.com/toddr/YAML-Syck';
bugtracker      'https://rt.cpan.org/Public/Dist/Display.html?Name=YAML-Syck';
tests           't/*.t t/*/*.t';
WriteAll;
