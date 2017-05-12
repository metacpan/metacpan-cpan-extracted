#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Getopt::Long;
use XML::LibXML;

GetOptions(
    'create' => \my $create,
);

my $xsd = $ARGV[0];

my $tree = XML::LibXML->new->parse_file( $xsd )->getDocumentElement;

my @simpleTypes = $tree->getElementsByTagName( 'xs:simpleType' );

for my $node ( @simpleTypes ) {
    print $node->toString,"\n";
}

if ( $create ) {
    my $dir = File::Spec->catdir( dirname( __FILE__ ), '..', 't' );
    for my $node ( @simpleTypes ) {
        my $name = $node->findvalue('@name');

        next if !$name;

        my $file = File::Spec->catfile( $dir, $name . '.t' );
        open my $fh, '>', $file or next;
        print $fh test_header();
        print $fh $node->toString;
        print $fh test_footer();
        close $fh;
    }
}

sub test_header {
qq~#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use TypeLibrary::FromXSD::Element;

my \$xsd_element = qq!~;
}

sub test_footer {
qq~!;

my \$element     = TypeLibrary::FromXSD::Element->new( \$xsd_element );

my \$check   = qq!!;
is \$element->type, \$check;

done_testing(); 
~;
}
