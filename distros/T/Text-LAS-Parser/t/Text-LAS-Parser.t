# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-LAS-Parser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('Text::LAS::Parser') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use IO::File;
use File::Spec;

my ( $las, $line );

ok( $las = Text::LAS::Parser->new( new IO::File( &get_path( 'ok_2.0_nowrap.las' ), 'r' ) ),
    'Construct with a minimum LAS example' );
ok( $line = $las->read_Section_A( 'null' ),
    'Read a data line contains null value' );
ok( $$line[0] eq '100.00' && $$line[1] eq 'null',
    'Check values read' );
ok( $line = $las->read_Section_A( 'null' ),
    'Read a data line' );
ok( $$line[0] eq '101.00' && $$line[1] eq '-234.567',
    'Check values read' );
ok( ! $las->read_Section_A( 'null' ),
    'Try reading a data line after the file end' );

sub get_path {
    my $file = shift;
    my ( $volume, $dirs ) = File::Spec->splitpath( $0 );
    return File::Spec->catpath( $volume, $dirs, $file );
}