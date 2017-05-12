#!perl

# checking methods:
# top_day, top_week, top_month, flop_day, flop_week, flop_month

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 168;

SKIP: {
    eval 'use Sub::Override';
    $@ && skip 'Sub::Override required for this test' => 168;

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

    my @methods = qw(
        top_day  top_week  top_month
        flop_day flop_week flop_month
    );

    foreach my $method (@methods) {
        diag("testing $method");

        my $fml     = WWW::FMyLife->new();
        my @data = $fml->$method();

        foreach my $data (@data) {
            isa_ok( $data, 'WWW::FMyLife::Item', 'Item is an object' );
        }

        # checking one of the items
        my $item       = shift @data;
        my @attributes = qw(
            author category date agree deserved text
        );

        SKIP: {
            defined $item || skip 'Item not defined... weird' => 8;

            isa_ok( $item, 'WWW::FMyLife::Item' );

            foreach my $attribute (@attributes) {
                ok( $item->$attribute, "Item has $attribute" );
            }

            if ( $item->comments_flag ) {
                ok( $item->comments, 'Item has comments' );
            } else {
                ok( ! $item->comments, 'Item does not have comments' );
            }
        }

        # types of getting the items
        my %format_types = (
            text   => sub {
                is( ref \shift, 'SCALAR', 'Item (as flat) is a string of text' )
            },
            object => sub {
                isa_ok( shift, 'WWW::FMyLife::Item', 'Item is an object' )
            },
            data   => sub {
                is( ref shift, 'HASH', 'Item is a hashref' );
            },
        );

        while ( my ( $format, $type_check ) = each %format_types ) {
            @data = $fml->$method( { as => $format } );

            foreach my $data (@data) {
                $type_check->($data);
            }
        }
    }
}

