use strict;
use Test;

BEGIN { plan tests => 1 }

use IO::File;
use Text::Tmpl;

use constant TEMPLATE => 't/2_if.tmpl';
use constant COMPARE  => 't/2_if.comp';

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

$context->set_strip(0);
$context->set_value('true',   Text::Tmpl::TEMPLATE_TRUE);
$context->set_value('false',  Text::Tmpl::TEMPLATE_FALSE);
$context->set_value('string', 'foobarbaz');

$output = $context->parse_file(TEMPLATE);

ok($output, $compare);
