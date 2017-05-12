use strict;
use warnings;
use t::Util qw/dispense_client/;
use Data::Section::Simple qw/get_data_section/;
use File::Temp qw/tempfile/;
use Ukigumo::Client::YamlConfig;
use Ukigumo::Constants;
use Test::More;

sub generate_config_by_yml {
    my ($client, $yml) = @_;

    my ($tmpfh, $tmpfile) = tempfile();
    print $tmpfh get_data_section($yml);
    close $tmpfh;

    Ukigumo::Client::YamlConfig->new(
        c => $client,
        ukigumo_yml_file => $tmpfile,
    );
}

subtest 'Set environment variable ok' => sub {
    my $client = dispense_client();
    my $config = generate_config_by_yml($client, 'basic.yml');

    my $orig_env_foo = $ENV{foo};
    my $orig_env_bar = $ENV{buz};

    {
        local %ENV = %ENV;

        $config->apply_environment_variables;

        is $ENV{foo}, 'hoge';
        is $ENV{buz}, 'qux';
    }

    is $ENV{foo}, $orig_env_foo;
    is $ENV{buz}, $orig_env_bar;
};

subtest 'Invalid env' => sub {
    my $original_reflect_result = *Ukigumo::Client::reflect_result{CODE};
    undef *Ukigumo::Client::reflect_result;
    *Ukigumo::Client::reflect_result = sub {};

    my $client = dispense_client();

    subtest 'give scalar and dies ok' => sub {
        my $config = generate_config_by_yml($client, 'invalid_scalar.yml');

        local %ENV = %ENV;

        eval { $config->apply_environment_variables };
        like $@, qr/`env` must be array reference: in spite of it was given `SCALAR`/;
    };

    subtest 'give hashref and dies ok' => sub {
        my $config = generate_config_by_yml($client, 'invalid_hash.yml');

        local %ENV = %ENV;

        eval { $config->apply_environment_variables };
        like $@, qr/`env` must be array reference: in spite of it was given `HASH`/;
    };

    undef *Ukigumo::Client::reflect_result;
    *Ukigumo::Client::reflect_result = $original_reflect_result;
};

done_testing;

__DATA__

@@ basic.yml
env:
  - foo: bar
  - buz: qux
  - foo: hoge

@@ invalid_scalar.yml
env: 'hogehoge'

@@ invalid_hash.yml
env:
  foo: 'hoge'

