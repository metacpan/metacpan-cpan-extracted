use Test2::Bundle::Extended;
use Test2::Tools::Spec;

use Trace::Mask::Test;
use Trace::Mask::Reference qw/trace/;

ref_ok(NA(), 'CODE', "NA gives us a coderef");

test_tracer(
    trace => \&trace,
    convert => sub {
        my $stack = shift;
        delete $_->[2] for @$stack;
        return $stack;
    },
    name => 'my tracer (reference)',
);

done_testing;
