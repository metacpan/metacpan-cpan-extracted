use strict;
use warnings;
use Test::More;

my ($username, $password) = get_hatena_config();
my $filename = 't/assets/cinnamon.jpg';
my $edit_uri;

use WebService::Hatena::Fotolife;

my $client = WebService::Hatena::Fotolife->new;
   $client->username($username);
   $client->password($password);

subtest 'create fotolife entry' => sub {
    $edit_uri = $client->createEntry(
        title    => 'cinnamon',
        filename => $filename,
        folder   => 'test',
    );

    ok   $edit_uri;
    like $edit_uri, qr(http://f\.hatena\.ne\.jp/atom/edit/\d{14});

    done_testing;
};

subtest 'update fotolife entry' => sub {
    my $result = $client->updateEntry(
        $edit_uri,
        title    => 'cinnamon is cute',
        filename => $filename,
        folder   => 'test',
    );

    ok $result;

    done_testing;
};

subtest 'delete fotolife entry' => sub {
    my $result = $client->deleteEntry($edit_uri);

    ok $result;

    done_testing;
};

done_testing;

sub get_hatena_config {
    my ($username, $password);
    eval "require Config::Pit";

    if ($ENV{HATENA_USERNAME} && $ENV{HATENA_PASSWORD}) {
        $username = $ENV{HATENA_USERNAME};
        $password = $ENV{HATENA_PASSWORD};
    }
    elsif (!$@) {
        my $config = Config::Pit::get('hatena.ne.jp', require => {
            username => 'your username on hatena.ne.jp',
            password => 'your password on hatena.ne.jp',
        });
        if ($config) {
            $username = $config->{username};
            $password = $config->{password};
        }
    }

    plan skip_all => 'Username and password are required for this test'
        if !$username || !$password;

    ($username, $password);
}
