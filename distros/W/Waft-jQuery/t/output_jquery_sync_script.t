
use Test;
BEGIN { plan tests => 1 };

use strict;
use vars qw( @ISA );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;
require Waft::jQuery;

push @ISA, qw( Waft::jQuery Waft );

my $javascript;

sub output { (undef, $javascript) = @_ }

$ENV{SERVER_NAME} = 'localhost';
$ENV{SERVER_PORT} = 80;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{SCRIPT_NAME} = 'test.cgi';

my $obj = __PACKAGE__->new->initialize;

$obj->{foo} = 'bar';
$obj->set_values( baz => qw( foo bar ) );
$obj->output_jquery_sync_script;

ok( $javascript =~ / 'baz-foo-bar\x20foo-bar' /xms );
