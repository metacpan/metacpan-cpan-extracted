use v5.40;
use Test2::V1 -ipP;

use Path::Tiny qw(path);
use Thunderhorse::Config;

################################################################################
# This tests whether Thunderhorse::Config loads files properly
################################################################################

package TestReader {
	use Mooish::Base -standard;

	extends 'Gears::Config::Reader';

	sub handled_extensions ($self)
	{
		return qw(test);
	}

	sub parse ($self, $config, $filename)
	{
		my $contents = $self->_get_contents($filename);
		my %result;

		foreach my $line (split /\n/, $contents) {
			next if $line =~ /^\s*$/;
			next if $line =~ /^\s*#/;

			if ($line =~ /^\s*(\w+)\s*=\s*(.+?)\s*$/) {
				$result{$1} = $2;
			}
		}

		return \%result;
	}
};

package TestApp {
	use Mooish::Base -standard;
	extends 'Thunderhorse::App';
};

subtest 'should load config files without PAGI_ENV' => sub {
	my $config = Thunderhorse::Config->new(
		readers => [
			Gears::Config::Reader::PerlScript->new,
			TestReader->new,
		],
	);

	$config->load_from_files('t/config/base', undef);

	is $config->config, {
		base => 'value',
		number => 42,
		nested => {
			key => 'nested_value',
		},
		test_key => 'test_value',
		another => '123',
		},
		'base config loaded correctly';
};

subtest 'should load production environment config with deep merge' => sub {
	my $config = Thunderhorse::Config->new(
		readers => [
			Gears::Config::Reader::PerlScript->new,
		],
	);

	$config->load_from_files('t/config/merge', 'production');

	is $config->config, {
		base => 'production_override',
		number => 42,
		nested => {
			key => 'nested_value',
			deep => {
				level => 'deep_value',
			},
			prod_key => 'prod_nested',
		},
		prod_only => 'prod_value',
		items => [qw(one two three four)],
		removed => [qw(keep)],
		replaced => [qw(new)],
		},
		'production config deep merged correctly';
};

subtest 'should load development environment config' => sub {
	my $config = Thunderhorse::Config->new(
		readers => [
			Gears::Config::Reader::PerlScript->new,
			TestReader->new,
		],
	);

	$config->load_from_files('t/config/development', 'development');

	is $config->config, {
		base => 'value',
		number => 42,
		nested => {
			key => 'nested_value',
		},
		test_key => 'test_value',
		another => '123',
		dev_key => 'dev_value',
		},
		'development config merged correctly';
};

subtest 'should handle missing conf directory gracefully' => sub {
	my $config = Thunderhorse::Config->new;

	ok lives { $config->load_from_files('t/config/nonexistent', 'production') },
		'load_from_files does not die without conf dir';
	is $config->config, {}, 'config is empty';
};

subtest 'should integrate with Thunderhorse::App' => sub {
	local $ENV{PAGI_ENV} = 'production';

	my $app = TestApp->new(initial_config => 'config/merge');

	is $app->config->config, {
		base => 'production_override',
		number => 42,
		nested => {
			key => 'nested_value',
			deep => {
				level => 'deep_value',
			},
			prod_key => 'prod_nested',
		},
		prod_only => 'prod_value',
		items => [qw(one two three four)],
		removed => [qw(keep)],
		replaced => [qw(new)],
		},
		'app loaded production config correctly';
};

done_testing;

