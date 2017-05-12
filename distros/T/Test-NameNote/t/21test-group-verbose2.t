use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Slurp;
use Test::Script::Run qw(run_not_ok last_script_stderr);
BEGIN {
    eval 'use Test::Group 0.15';
    plan skip_all => 'Test::Group >= 0.15 not installed' if $@;

    plan tests => 5;
}

my $tmp = tempdir( CLEANUP => 1 );

write_file "$tmp/script", <<'END';
    use strict;
    use warnings;

    use Test::NameNote;
    use Test::Group;
    use Test::More tests => 1;

    Test::Group->verbose(2);

    test foo => sub {
        my $x = Test::NameNote->new('x');
        ok 1, "will pass";
        my $y = Test::NameNote->new('y');
        ok 0, "will fail";
    };
END

run_not_ok("$tmp/script");
like last_script_stderr(),
     qr/ok 1\.1 will pass \(x\)/,
     "T::G verbose test 1";
like last_script_stderr(),
     qr/not ok 1\.2 will fail \(x,y\)/,
     "T::G verbose test 2";
like last_script_stderr(),
     qr/Failed test 'will fail \(x,y\)'/,
     "notes in T::G fail msg";
like last_script_stderr(),
     qr/\bin .+\bscript at line 14\./,
     "sub-test lineno correct";
