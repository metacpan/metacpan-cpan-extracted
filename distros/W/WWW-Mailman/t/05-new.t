use strict;
use warnings;
use Test::More;
use WWW::Mailman;
use File::Temp qw( tempdir );
use File::Spec;

$WWW::Mailman::VERSION ||= 'undefined';

plan tests => 6;

ok( !eval { WWW::Mailman->new( bonk => 'zlonk' ); 1 },
    "new() fails with unknown parameters" );
like(
    $@,
    qr/^Unknown constructor parameters: bonk /,
    'Expected error message'
);

my $mm = WWW::Mailman->new();
isa_ok( $mm,                    'WWW::Mailman' );
isa_ok( $mm->robot->cookie_jar, 'HTTP::Cookies' );

my $mech = WWW::Mechanize->new();
$mm = WWW::Mailman->new( robot => $mech );
is( $mm->robot, $mech, "Setup our own robot" );

my $dir = tempdir( CLEANUP => 1 );
my $file = File::Spec->catfile( $dir, 'somefile' );
$mm = WWW::Mailman->new( cookie_file => $file );
is( $mm->robot->cookie_jar->{file}, $file, "Setup our own cookie savefile" );

