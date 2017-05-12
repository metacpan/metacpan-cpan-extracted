use strict;
use Test;

BEGIN { plan tests => 4 }

use IO::File;
use Text::Tmpl;

use constant TEMPLATE => 't/2_ext_pair.tmpl';
use constant COMPARE  => 't/2_ext_pair.comp';

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

$return = $context->register_pair(0, 'poot', 'endpoot', \&tag_pair_poot);
ok($return, 1);

$return = $context->alias_pair('poot', 'endpoot', 'toop', 'endtoop');
ok($return, 1);

$return = $context->alias_pair('comment', 'endcomment', 'foo', '/foo');
ok($return, 1);

$context->remove_pair('poot');
$context->remove_pair('comment');

$context->set_strip(0);

$output = $context->parse_file(TEMPLATE);

ok($output, $compare);

sub tag_pair_poot {
    my($context, $name, @args) = @_;

    $context->set_value('poot', 'pootpoot');

    return;
}
