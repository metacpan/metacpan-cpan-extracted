#!/usr/bin/perl

BEGIN { $ENV{DO_NOT_WARN_ON_DEFER_PLAN} = 1 }
use lib 'lib', 't/lib';
use Test::Most qw<defer_plan>;

ok 1;
ok 1;
ok 1;
all_done(3);

__END__

# :(

use Test::Command;

my $prog = q{
	use strict;
	use warnings;

	use lib 'lib', 't/lib';
	use Test::Most qw<defer_plan>;

	ok(1);
	die("premature termination");
	ok(1);
	ok(1);
	all_done();
};
stdout_like(['perl', '-e', $prog], qr/1\.\.2\n\Z/);

$prog = q{
	use strict;
	use warnings;

	use lib 'lib', 't/lib';
	use Test::Most qw<defer_plan>;

	ok(1);
	ok(1);
	ok(1);
	all_done();
};
stdout_like(['perl', '-e', $prog], qr/1\.\.3\n\Z/);

$prog = q{
	use strict;
	use warnings;

	use lib 'lib', 't/lib';
	use Test::Most qw<defer_plan>;

	ok(1);
	ok(1);
	ok(1);
	all_done(4);
};
stdout_like(['perl', '-e', $prog], qr/1\.\.4\n\Z/);
all_done(3);
