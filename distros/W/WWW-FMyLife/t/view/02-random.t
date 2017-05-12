#!perl

# checking usage of 'random' method

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 8;

SKIP: {
    eval 'use Sub::Override';
    $@ && skip 'Sub::Override required for this test' => 8;

    my $data_file = File::Spec->catfile( qw/ t data eg.xml / );
    my $xml_data  = q{};

    open my $fh, '<', $data_file or die "Can't open file $data_file: $!\n";
    {
        local $/ = undef;
        $xml_data = <$fh>;
    }
    close $fh or die "Can't close file: $data_file\n";
    chomp $xml_data;

    Sub::Override->new( 'WWW::FMyLife::_fetch_data' => sub { $xml_data } );

    my $fml  = WWW::FMyLife->new();
    my $item = $fml->random();

    isa_ok( $item, 'WWW::FMyLife::Item', 'Item is an object' );

    # checking the item
    my @attributes = qw(
        author category date agree deserved text
    );

    foreach my $attribute (@attributes) {
        ok( $item->$attribute, "Item has $attribute" );
    }

    if ( $item->comments_flag ) {
        ok( $item->comments, 'Item has comments' );
    } else {
        ok( ! $item->comments, 'Item does not have comments' );
    }

}

