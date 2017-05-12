use strict;
use Test;

BEGIN { plan tests => 1 }

use Text::Tmpl;

my($return, $subcontext, $okay);
my $context = new Text::Tmpl;

$subcontext = $context;
$okay = 1;
foreach (1 .. 5000) {
    $subcontext = $subcontext->loop_iteration( 'loop1' );
    if (! defined $subcontext) {
        $okay = 0;
        last;
    }
    $return = $subcontext->set_value( 'value1', $_ );
    if (! $return) {
        $okay = 0;
        last;
    }
}

ok($okay);
