use strict;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use Test::More;

BEGIN {
    if (not eval "use Capture::Tiny ':all'; 1") {
        plan skip_all => "requires Capture::Tiny";
    }
    plan tests => 1;
}

my ($out, $err) = capture {
    system $^X, '-Ilib', "$t/script/hello.pl";
};
die "Run failed:\nstdout: $out\nstderr:$err\n" unless 0 == $?;

ok $out =~ /^Goodbye, World!\n/m;
