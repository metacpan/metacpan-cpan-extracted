#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Config;
use Errno 'ENOENT';
use File::Spec::Functions 'file_name_is_absolute';

use lib "t/lib";
use TestUtils;

my $perl = file_name_is_absolute($^X) ? $^X : $Config{perlpath};

subtest return0 => sub {
	use autocroak;
	my $ex = exception { system $perl, qw/-e exit(0)/ };
	is($ex, undef);
};

subtest return1 => sub {
	use autocroak;
	my $ex = exception { system $perl, qw/-e exit(1)/ };
	my $error = $^O ne 'MSWin32' ? qr/unexpectedly returned exit value 1/ : qr/returned \d+/;
	like($ex, qr/^Could not call system ".+": $error/);
};

subtest signal6 => sub {
	use autocroak;
	plan skip_all => 'Poor signal support' unless $Config{d_sigaction};
	my $ex = exception { system $perl, qw/-MPOSIX -e POSIX::abort()/ };
	like($ex, qr/^Could not call system ".+": died with signal ABRT/);
};

subtest nonexistent => sub {
	use autocroak;
	no warnings 'exec';
	my $ex = exception { system '/usr/bin/nonexistent', '1' };
	like($ex, error_for(qr/call system ".+"/, ENOENT));
};

done_testing;
