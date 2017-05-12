#!/usr/bin/perl
#

use lib '/tmp/xml-api/lib';
use Benchmark qw(:all);
use XML::API;
use XML::APIOLD;

my $new  = XML::API->new;
my $new2 = XML::API->new;
$new->x_open;
$new2->y_open;

my $old  = XML::APIOLD->new;
my $old2 = XML::APIOLD->new;
$old->x_open;
$old2->y_open;

if ( $ARGV[0] == 1 ) {
    timethese(
        100000,
        {
            old => sub {
                XML::APIOLD::Element->new( element => 'e' );
            },
            new => sub {
                XML::API::Element->new( element => 'e' );
            },
        }
    );
}

if ( $ARGV[0] == 2 ) {
    timethese(
        10000,
        {
            old => sub {

                #        "$old";
                #            $old->_add($old2);
                $old->_add(2);
            },
            new => sub {

                #        "$new";
                #            $new->_add($new2);
                $new->_add(2);
            },
        }
    );
}

if ( $ARGV[0] == 3 ) {
    timethese(
        10000,
        {
            old => sub {
                $old->x(1);
            },
            new => sub {
                $new->x(1);
            },
        }
    );

    timethese(
        10,
        {
            old => sub {
                print $old;
            },
            new => sub {
                "$new";
            },
        }
    );
}

