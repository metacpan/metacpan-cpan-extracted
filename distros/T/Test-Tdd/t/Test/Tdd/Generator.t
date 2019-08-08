use strict;
use warnings;
use lib qw(./lib ./example/lib);

use Test::Tdd::Generator;
use Test::Spec;
use Test::Differences;
use Module::Untested;
use Module::NoPermission::Untested;
use Module::ImmutableMooseClass;
use File::Spec;

open(my $ORIGSTDOUT, ">&", STDOUT) and close(STDOUT);
open STDOUT, '>', File::Spec->devnull();

describe 'Test::Tdd::Generator' => sub {
	before each => sub {
		system("rm -rf example/t/Module");
		system("rm -rf /tmp/t");
		system('chmod -R 555 example/lib/Module/NoPermission/t');
	};

	it 'finds test folder' => sub {
		my ($test_path, $lib_path) = Test::Tdd::Generator::_find_test_and_lib_folders("example/lib/Module/Untested.pm");
		is($test_path, "example/t");
		is($lib_path, "example/lib");
	};

	describe 'global variables' => sub {
		it 'gets global variables' => sub {
			$Global::FOO = "foo";
			$Global::BAR = "bar";

			my $result = Test::Tdd::Generator::_get_globals(['Global::']);

			eq_or_diff($result->{'Global::'}, {'FOO' => 'foo', 'BAR' => 'bar'});
		};

		it 'gets a specific global variable' => sub {
			$Global::FOO = "foo";

			my $result = Test::Tdd::Generator::_get_globals(['Global::FOO']);

			is($result->{'Global::FOO'}, 'foo');
		};

		it 'gets nested globals' => sub {
			$Nested::Global::FOO = "foo";

			my $result = Test::Tdd::Generator::_get_globals(['Nested::']);

			eq_or_diff($result->{'Nested::'}, {'Global::' => {'FOO' => 'foo'}});
		};

		it 'expands globals' => sub {
			$Global::FOO = undef;

			Test::Tdd::Generator::expand_globals({'Global::' => {'FOO' => 'foo'}});

			is($Global::FOO, 'foo');
		};

		it 'expands nested globals' => sub {
			$Nested::Global::FOO = undef;

			Test::Tdd::Generator::expand_globals({'Nested::' => {'Global::' => {'FOO' => 'foo'}}});

			is($Nested::Global::FOO, 'foo');
		};
	};

	describe 'test generation' => sub {
		before each => sub {
			my $counter = Module::ImmutableMooseClass->new(counter => 5);
			Module::Untested::untested_subroutine("baz", 123, $counter);
		};

		it 'creates a test file' => sub {
			ok(-e "example/t/Module/Untested.t");
		};

		it 'creates a test in the test file' => sub {
			open FILE, "example/t/Module/Untested.t";
			my $content = join "", <FILE>;
			close FILE;

			ok($content =~ /it 'returns params plus foo'/);
			ok($content =~ /my \$input = Test::Tdd::Generator::load_input\(dirname\(__FILE__\) . "\/input\/Untested_returns_params_plus_foo\.dump"\)/);
			ok($content =~ /Module::Untested::untested_subroutine\(@\{\$input->\{args\}\}\)/);
			ok($content =~ /is\(\$result, "fixme"\)/);
		};

		it 'dumps params to a file' => sub {
			my $input = Test::Tdd::Generator::load_input("example/t/Module/input/Untested_returns_params_plus_foo.dump");
			is($input->{args}[0], "baz");
			is($input->{args}[1], 123);
			is($input->{args}[2]->counter, 5);
		};

		xit 'dies for duplicated test' => sub {
			my $err;
			eval {Module::Untested::untested_subroutine("baz", 123);} or do {
				$err = $@;
			};
			ok($err =~ /Test 'returns params plus foo' already exists on example\/t\/Module\/Untested\.t/);
		};

		it 'appends additional tests' => sub {
			Module::Untested::another_untested_subroutine("ya");

			open FILE, "example/t/Module/Untested.t";
			my $content = join "", <FILE>;
			close FILE;

			ok($content =~ /it 'returns the first param'/);
			ok($content =~ /it 'returns params plus foo'/);
		};

		it 'dumps globals to a file' => sub {
			$Example::VARIABLE = undef;

			my $input = Test::Tdd::Generator::load_input("example/t/Module/input/Untested_returns_params_plus_foo.dump");
			Test::Tdd::Generator::expand_globals($input->{globals});

			is($Example::VARIABLE, 'foo');
		};

		it 'expands globals on the test' => sub {
			open FILE, "example/t/Module/Untested.t";
			my $content = join "", <FILE>;
			close FILE;

			ok($content =~ /Test::Tdd::Generator::expand_globals\(\$input->\{globals\}\)/);
		};

		xit 'creates a test in the test file in /tmp when there is no permission to create on the actual folder' => sub {
			Module::NoPermission::Untested::untested_subroutine("qux");

			open FILE, "/tmp/t/Untested.t";
			my $content = join "", <FILE>;
			close FILE;

			ok($content =~ /it 'creates test on tmp'/);

			my $input = Test::Tdd::Generator::load_input("/tmp/t/input/Untested_creates_test_on_tmp.dump");
			is($input->{args}[0], "qux");
		};

		it 'serializes lambdas' => sub {
			my $lambda = sub { return "foo" };
			Module::Untested::another_untested_subroutine($lambda);

			my $input = Test::Tdd::Generator::load_input("example/t/Module/input/Untested_returns_the_first_param.dump");
			is($input->{args}[0]->(), "foo");
		};

		it 'serializes lambdas with out-of-scope variables' => sub {
			my $foo = "bar";
			my $lambda = sub { return $foo };
			Module::Untested::another_untested_subroutine($lambda);

			my $input = Test::Tdd::Generator::load_input("example/t/Module/input/Untested_returns_the_first_param.dump");

			# it will be undef but at least the deserialization doesn't die
			is($input->{args}[0]->(), undef);
		};

		it 'ignores Devel::Peek dumps' => sub {
			print STDERR "this one is fine\n";
			my $lambda = sub {
				use Devel::Peek;
				Devel::Peek::Dump("foo");
				print STDERR "this one is also fine\n";
			};
			Module::Untested::another_untested_subroutine($lambda);

			open(STDOUT, ">&=" . fileno($ORIGSTDOUT));
			my $input = Test::Tdd::Generator::load_input("example/t/Module/input/Untested_returns_the_first_param.dump");
			$input->{args}[0]->(); # no assertion, just check Devel::Peek outputs are not on the console
			open STDOUT, '>', File::Spec->devnull();
		};
	};
};

runtests;