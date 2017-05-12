use strict;
use warnings;

# This test was generated via Dist::Zilla::Plugin::Test::Compile 2.018

use Test::More 0.88;



use Capture::Tiny qw{ capture };

my @module_files = qw(
XML/Filter/Distributor.pm
XML/Filter/DocSplitter.pm
XML/Filter/Merger.pm
XML/Filter/Tee.pm
XML/SAX/ByRecord.pm
XML/SAX/EventMethodMaker.pm
XML/SAX/Machine.pm
XML/SAX/Machines.pm
XML/SAX/Machines/ConfigDefaults.pm
XML/SAX/Machines/ConfigHelper.pm
XML/SAX/Manifold.pm
XML/SAX/Pipeline.pm
XML/SAX/Tap.pm
);

my @scripts = qw(

);

# no fake home requested

my @warnings;
for my $lib (@module_files)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Mblib', '-e', qq{require q[$lib]});
    };
    is($?, 0, "$lib loaded ok");
    warn $stderr if $stderr;
    push @warnings, $stderr if $stderr;
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};



done_testing;
