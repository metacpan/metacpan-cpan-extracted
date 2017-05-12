
use Test;
BEGIN { plan tests => 3 };

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
$ENV{SCRIPT_NAME} = q{/test"'\.cgi};

my $obj = __PACKAGE__->new->initialize;

$obj->set_page(q{default"'\.html});
$obj->{foo} = q{"bar'};
$obj->set_values( baz => ('<foo>', "b\x0Da\x0Ar") );
$obj->output_jquery_request_script('get');

ok( $javascript =~ / 'default\\"\\'\\\\\.html' /xms );
ok( $javascript =~ / 'baz-\\x3Cfoo\\x3E-b\\ra\\nr\x20foo-\\"bar\\'' /xms );
ok( $javascript =~ / 'test\\"\\'\\\\.cgi' /xms );
