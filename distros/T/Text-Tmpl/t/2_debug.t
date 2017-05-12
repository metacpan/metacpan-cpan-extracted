use strict;
use Test;

BEGIN { plan tests => 1 }

use IO::File;
use Text::Tmpl;

use constant TEMPLATE => 't/2_debug.tmpl';
use constant COMPARE  => 't/2_debug.comp';

my($compare, $output);

my $context = new Text::Tmpl;
if (! defined $context) {
    ok(0);
    exit(0);
}
my $comp_fh = new IO::File COMPARE, 'r';
if (! defined $comp_fh) {
    ok(0);
    exit(0);
}

{
    local $/ = undef;
    $compare = <$comp_fh>;
}

$comp_fh->close;

$context->set_strip(1);

$context->set_value('var1', 'value1');
$context->set_value('var2', 'value2');
foreach my $inum (1 .. 2) {
    my $iter = $context->loop_iteration('loop1');
    $iter->set_value('iter' => $inum);
}

$output = $context->parse_file(TEMPLATE);

ok($output, $compare);
