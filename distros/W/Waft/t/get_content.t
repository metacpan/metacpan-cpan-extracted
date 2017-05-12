
BEGIN { if ( $] < 5.006 ) { local $ENV{PERL_DL_NONLAZY}; require B } }

use Test;
BEGIN { plan tests => 1 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use lib 't/get_content';
require Waft::Test::GetContent;

my $obj = Waft::Test::GetContent->new;

my $content = $obj->get_content( sub {
    $obj->call_template('default.html');
} );

ok($content, '123');
