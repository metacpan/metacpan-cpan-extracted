#!perl

use strict;
use Config;
use File::Spec::Functions;
use FindBin qw( $Bin );
use Readonly;
use Test::Exception;
use Test::More tests => 6;
use Text::RecordParser;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

require_ok 'Text::RecordParser::Object';

my $file = catfile( $TEST_DATA_DIR, 'simpsons.csv' );
my $p    = Text::RecordParser->new( $file );
my $r;
ok( $r = $p->fetchrow_object, 'Got object' );
isa_ok( $r, 'Text::RecordParser::Object', 'Correct class' );
ok( $r->can('Address') && 1, 'Has the "Address" method' );
is( $r->Address, '747 Evergreen Terrace', "Address is good");
throws_ok { $r->Address('900 Oakhill Circle') } 
    qr/cannot alter/,
    "Method is read-only";
