
use Test;
BEGIN { plan tests => 6 };

use strict;
use vars qw( @ISA );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Waft with => '::JS';

my $javascript;

sub output { (undef, $javascript) = @_ }

$ENV{REQUEST_METHOD} = 'GET';
$ENV{SCRIPT_NAME} = q{/test"'\.cgi};

my $obj = __PACKAGE__->new->initialize;

$obj->set_page(q{default"'\.html});
$obj->{foo} = q{"bar'};
$obj->set_values( baz => ('<foo>', "b\x0Da\x0Ar") );
$obj->output_js_make_url_script;

ok( $javascript =~ / 'default\\"\\'\\\\\.html' /xms );
ok( $javascript =~ / 'foo' /xms );
ok( $javascript =~ / ['\\"bar\\''] /xms );
ok( $javascript =~ / 'baz' /xms );
ok( $javascript =~ / ['\\x3Cfoo\\x3E',\x20'b\\ra\\nr'] /xms );
ok( $javascript =~ / 'test\\"\\'\\\\.cgi' /xms );
