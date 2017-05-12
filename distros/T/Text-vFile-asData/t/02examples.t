#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Find;
use IO::File;

# Make sure the examples in the examples/ hierarchy all parse and roundtrip
my @samples = ();
find(\&wanted, 'examples');

sub wanted {
    push @samples, $File::Find::name if -f $_ and $_ ne 'README';
    $File::Find::prune = 1 if -d $_ and $_ eq '.svn';
}

my $class = 'Text::vFile::asData';

if (eval "require Test::Differences; 1") {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}

require_ok( $class );

for my $preserve (0, 1) {
    diag "preservation is " . ($preserve ? "on" : "off");
    foreach my $file (@samples) {
        my $parsed = $class->new->preserve_params( $preserve )
          ->parse( IO::File->new($file) );
        ok( $parsed, "parsed $file" );
        my @generated = $class->new->generate_lines( $parsed );
        ok( scalar @generated, "generated vCal" );
        is_deeply( $parsed, $class->new->preserve_params( $preserve )
                     ->parse_lines( @generated ),
                   "and it round tripped")
          or do {
              print "# generated:\n", map { "# $_\n" } @generated;
              my $fh = IO::File->new( $file );
              print "# from:\n", map { "# $_" } <$fh>;
          };
    }
}

done_testing();
