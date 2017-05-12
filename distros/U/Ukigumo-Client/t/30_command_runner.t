use strict;
use warnings;
use t::Util qw/dispense_client/;
use Data::Section::Simple qw/get_data_section/;
use File::Temp qw/tempfile/;
use Ukigumo::Client::CommandRunner;
use Ukigumo::Client::YamlConfig;
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

undef *Ukigumo::Client::reflect_result;
*Ukigumo::Client::reflect_result = sub {};
my $client = dispense_client();

subtest 'running commands is successful' => sub {
    my $config = generate_config_by_yml($client, 'success.yml');
    my $command_runner = Ukigumo::Client::CommandRunner->new(
        c      => $client,
        config => $config,
    );

    ok $command_runner->run('before_install');
    ok $command_runner->run('install');
    ok $command_runner->run('before_script');
    ok $command_runner->run('after_script');
};

subtest 'running commands fail' => sub {
    my $config = generate_config_by_yml($client, 'fail.yml');
    my $command_runner = Ukigumo::Client::CommandRunner->new(
        c      => $client,
        config => $config,
    );

    eval { $command_runner->run('before_install') };
    like $@, qr/Failure in before_install: perl --invalid-option/;
    eval { $command_runner->run('install') };
    like $@, qr/Failure in install: perl --invalid-option/;
    eval { $command_runner->run('before_script') };
    like $@, qr/Failure in before_script: perl --invalid-option/;
    eval { $command_runner->run('after_script') };
    like $@, qr/Failure in after_script: perl --invalid-option/;
};

done_testing;

__DATA__

@@ success.yml

before_install:
  - perl -v
install: perl -v
before_script:
  - perl -v
after_script:
  - perl -v

@@ fail.yml

before_install:
  - perl --invalid-option
install: perl --invalid-option
before_script:
  - perl --invalid-option
after_script:
  - perl --invalid-option
