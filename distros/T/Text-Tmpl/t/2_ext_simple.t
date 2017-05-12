use strict;
use Test;

BEGIN { plan tests => 4 }

use IO::File;
use Text::Tmpl;

use constant TEMPLATE => 't/2_ext_simple.tmpl';
use constant COMPARE  => 't/2_ext_simple.comp';

my($return, $compare, $output);

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

$return = $context->register_simple('poot', \&simple_tag_poot);
ok($return, 1);

$return = $context->alias_simple('poot', 'toop');
ok($return, 1);

$return = $context->alias_simple('echo', '=');
ok($return, 1);

$context->set_strip(0);

$context->remove_simple('echo');
$context->remove_simple('poot');

$output = $context->parse_file(TEMPLATE);

ok($output, $compare);

sub simple_tag_poot {
    my($context, $name, @args) = @_;

    return 'pootpoot';
}
