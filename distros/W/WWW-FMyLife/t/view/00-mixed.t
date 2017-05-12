#!perl

# checking usage of the last, top and flop methods

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 366;

SKIP: {
    eval 'use Sub::Override';
    $@ && skip 'Sub::Override required for this test' => 366;

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

    my @methods = qw( last top flop );
    foreach my $method (@methods) {
        diag("testing $method");

        my $fml  = WWW::FMyLife->new();
        my @data = $fml->$method();

        cmp_ok( scalar @data, '==', 15, "Got last 15 of $method" );
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
        my @format_types = ( qw( text object data ) );

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
            my %check_types = (
                'Testing with formating only'     => { as => $format            },
                'Testing with formating and page' => { as => $format, page => 2 },
            );

            foreach my $check_type ( keys %check_types ) {
                diag("$check_type :: $format");

                @data = $fml->last( $check_types{$check_type} );
                cmp_ok( scalar @data, '==', 15, "Got last 15 of $method" );

                foreach my $data (@data) {
                    $type_check->($data);
                }
            }
        }


        SKIP: {
            eval 'use Test::MockObject::Extends';
            $@ && skip 'Test::MockObject required for this test', 2;

            my $agent    = $fml->agent();
            my $mock_obj = Test::MockObject::Extends->new( $fml->agent() );

            $mock_obj->mock( 'is_success', sub { 1 } );
            $mock_obj->mock(
                'decoded_content',
                sub {
                    '<root><pages>2</pages></root>'
                }
            );

            $mock_obj->mock(
                'post',
                sub {
                    my $asked_url  = $_[1];
                    my $needed_url = "http://api.betacie.com/view/$method/3";
                    is( $asked_url, $needed_url, 'Asking for pages correctly' );
                    return $mock_obj;
            } );

            $fml->$method(3);
            $fml->$method( { page => 3 } );
        }
    }
}


