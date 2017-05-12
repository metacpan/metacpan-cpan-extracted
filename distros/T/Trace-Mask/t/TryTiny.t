use Test2::Require::Module Carp => '1.03';
use Test2::Require::Module 'Try::Tiny' => '0.03';
use Test2::Bundle::Extended;
use Test2::Tools::Spec;

use Trace::Mask::TryTiny;
use Trace::Mask::Carp qw/longmess/;

use Try::Tiny;

diag("Try::Tiny Version: " . Try::Tiny->VERSION . "\n");

sub base {
    my %out;

    try {
        $out{try_line} = __LINE__ + 1;
        $out{try} = longmess('inside try');
        die "should not see this";
    }
    catch {
        $out{catch_line} = __LINE__ + 1;
        $out{catch} = longmess('inside catch');
    }
    finally {
        $out{finally_line} = __LINE__ + 1;
        $out{finally} = longmess('inside finally');
    };

    return \%out;
};

my $file = __FILE__;
my $line = __LINE__ + 1;
my $traces = base();

is($traces->{try}, <<EOT, "Masked frames that called the try block (wrapped)");
inside try at $file line $traces->{try_line}.
\tmain::base() called at $file line $line
EOT

is($traces->{catch}, <<EOT, "Masked frames that called the catch block (wrapped)");
inside catch at $file line $traces->{catch_line}.
\tmain::base() called at $file line $line
EOT

is($traces->{finally}, <<EOT, "Masked frames that called the finally block (wrapped)");
inside finally at $file line $traces->{finally_line}.
\tmain::base() called at $file line $line
EOT


# Now do it again without a wrapping sub

my %out;
try {
    $out{try_line} = __LINE__ + 1;
    $out{try} = longmess('inside try');
    die "should not see this";
}
catch {
    $out{catch_line} = __LINE__ + 1;
    $out{catch} = longmess('inside catch');
}
finally {
    $out{finally_line} = __LINE__ + 1;
    $out{finally} = longmess('inside finally');
};

is($out{try}, <<EOT, "Masked frames that called the try block (unwrapped)");
inside try at $file line $out{try_line}.
EOT

is($out{catch}, <<EOT, "Masked frames that called the catch block (unwrapped)");
inside catch at $file line $out{catch_line}.
EOT

is($out{finally}, <<EOT, "Masked frames that called the finally block (unwrapped)");
inside finally at $file line $out{finally_line}.
EOT

done_testing;
