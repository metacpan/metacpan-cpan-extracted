use strict;
use warnings;
use Test::More;
use Test::Differences;
use Test::Name::FromLine;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

sub x ($) { my $s = shift; $s =~ s{^\s+|\s+$}{}g; $s }
sub test_test (&) { # from Test::Test::More written by id:wakabatan
	my $code = shift;
	open my $file1, '>', \(my $s = '');

	{
		my $builder = Test::Builder->create;
		$builder->output($file1);
		no warnings 'redefine';
		local *Test::More::builder = sub { $builder };
		$code->();
	}

	close $file1;

	return { output => x $s };
}

my $base_dir = getcwd();
my $dir = tempdir CLEANUP => 1;
chdir $dir or die $!;

is test_test {
	is 1, 1;
} -> {output}, x q{
ok 1 - L32: is 1, 1;
}, 'is 1, 1 => ok';

chdir $base_dir or die $!;

done_testing;
