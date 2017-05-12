use strict;
use warnings;
use t::Util qw/dispense_client/;
use Data::Section::Simple qw/get_data_section/;
use File::Temp qw/tempfile/;
use File::Spec::Functions qw/catfile/;
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

subtest 'load `.ukigumo.yml` on project root ok' => sub {
    my $config = Ukigumo::Client::YamlConfig->new(
        c => $client,
        ukigumo_yml_file => catfile('eg', '_ukigumo.yml'),
    );

    is $config->ukigumo_yml_file, 'eg/_ukigumo.yml';

    is scalar @{$config->before_install}, 1;
    is $config->before_install->[0], 'cpanm -L $HOME/.ukigumo/ukigumo-client/extlib --installdeps -n .';

    is_deeply $config->install, ['ln -s $HOME/.ukigumo/ukigumo-client/extlib ./extlib'];
    is_deeply $config->script, ['prove -lrv -Iextlib/lib/perl5 t'];
};

subtest 'load basic yml' => sub {
    my $config = generate_config_by_yml($client, 'basic.yml');

    my @sorted_notifiers = sort @{$config->notifiers};
    is scalar @{$config->notifiers}, 2;
    is ref $sorted_notifiers[0], 'Ukigumo::Client::Notify::GitHubStatuses';
    is ref $sorted_notifiers[1], 'Ukigumo::Client::Notify::Ikachan';

    is $config->project_name, 'MyProj';
    is_deeply $config->before_install, ['foo'];
    is_deeply $config->install, ['bar'];
    is_deeply $config->before_script, ['buz'];
    is_deeply $config->script, ['hoge'];
    is_deeply $config->after_script, ['fuga'];
};

subtest 'load nil yml' => sub {
    my ($tmpfh, $tmpfile) = tempfile();
    close $tmpfh;

    eval {
        my $config = Ukigumo::Client::YamlConfig->new(
            c => $client,
            ukigumo_yml_file => $tmpfile,
            travis_yml_file => $tmpfile,
        );
    };
    like $@, qr/$tmpfile: does not contain anything/;
};

subtest 'load nil yml' => sub {
    my $config = Ukigumo::Client::YamlConfig->new(
        c => $client,
        ukigumo_yml_file => 'NOT_EXISTS',
        travis_yml_file => 'NOT_EXISTS',
    );
    is_deeply $config->config, {}
};

done_testing;

__DATA__

@@ basic.yml

project_name: MyProj
before_install:
  - foo
install: bar
before_script:
  - buz
script:
  - hoge
after_script:
  - fuga
notifications:
  ikachan:
    - url: localhost
      channel: "#ukigumo"
  github_statuses:
    - api_endpoint: localhost
      access_token: __ACCESS_TOKEN__

@@ unknown_notification.yml

notifications:
  unknown:
    - foo: bar
