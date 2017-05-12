use strict;
use Test;

BEGIN { plan tests => 2 }

use Text::Tmpl;

my($return, $okay, $loop_number, $subcontext);
my $context = new Text::Tmpl;

$return = $context->set_values({ ( 1 .. 5000 ) });
ok($return);

$okay = 1;
foreach (1 .. 5000) {
    $subcontext = $context->loop_iteration( 'loop1' );
    if (! defined($subcontext)) {
        $okay = 0;
        last;
    }
}
ok($okay);
