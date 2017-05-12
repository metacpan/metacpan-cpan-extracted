use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

unless ( $ENV{TEST_AUTHOR}) {
     plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
}

use Test::Docker::Image;
use Test::Docker::Image::Utility 'docker';

my $mysql51_image = Test::Docker::Image->new(
    tag             => 'iwata/centos6-mysql51-q4m-hs',
    container_ports => [3306],
);

my $container_id = $mysql51_image->container_id;
my $container_id2;

subtest "host" => sub {
    my $got = $mysql51_image->host;
    like $got => '/^192\.168\.59\.\d{2,3}$/', 'return IP Address';
};

subtest "connect MySQL and show plugins" => sub {
    my $port = $mysql51_image->port(3306);
    my $host = $mysql51_image->host;

    my $exp = [qw/binlog CSV MEMORY InnoDB MyISAM MRG_MYISAM QUEUE handlersocket/];

    my @mysql_plugins = map {
         my ($plugin) = split "\t", $_;
         $plugin;
    } grep { $_ !~ /License/ } split "\n", `mysql -h $host -u root -P $port -e 'show plugins'`;

    cmp_bag \@mysql_plugins => $exp or diag explain \@mysql_plugins;
};

subtest "DESTROY" => sub {
    my $mysql51_image2 = Test::Docker::Image->new(
        tag             => 'iwata/centos6-mysql51-q4m-hs',
        container_ports => [3306],
        boot            => 'Test::Docker::Image::Boot::Boot2docker',
    );
    $container_id2 = $mysql51_image2->container_id;

    my $got = docker('inspect', $container_id);
    ok $got, 'got inspect';

    undef $mysql51_image;

    $got = docker('inspect', $container_id);
    is $got => '[]', 'gabage collect guard object and removed container';

    $got = docker('inspect', $container_id2);
    ok $got, 'another container exists yet';
};

my $got = docker('inspect', $container_id2);
is $got => '[]', 'scope out guard object and removed container';

done_testing;

