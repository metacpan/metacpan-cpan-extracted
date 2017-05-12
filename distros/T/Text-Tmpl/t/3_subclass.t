use strict;
use Test;

BEGIN { plan tests => 10 }

package Text::Tmpl::TestSubClass;

use Text::Tmpl;

@Text::Tmpl::TestSubClass::ISA = qw(Text::Tmpl);

sub test_sub {
    my $self = shift || return(0);
    $self->set_value('test_sub', 'poot');
    return(1);
}

sub set_value {
    my $self = shift || return(0);
    my $var  = shift || return(0);
    my $val  = shift || return(0);

    return $self->SUPER::set_value($var, 'subclass-' . $val);
}

package main;

use IO::File;

use constant TEMPLATE => 't/3_subclass.tmpl';
use constant COMPARE  => 't/3_subclass.comp';

my($return, $subcontext, $output, $compare);

my $context = new Text::Tmpl::TestSubClass;
if (! defined($context)) {
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

ok(1);

$return = $context->set_strip(0);
ok(1);

$return = $context->test_sub;
ok($return);

$return = $context->set_value('foo', 'bar');
ok($return);

$subcontext = $context->loop_iteration('foo');
ok($return);

$subcontext = $context->fetch_loop_iteration('foo', 0);
ok(defined $subcontext);

$return = $subcontext->set_value('bar', 'baz');
ok($return);

$return = $subcontext->test_sub;
ok($return);

$output = $context->parse_file(TEMPLATE);
ok(defined $output);

ok($output, $compare);
