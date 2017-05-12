use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;
use Test::Mojo;

my $home = path();
$home = path($home->dirname) if $home->basename eq 'blib';
$ENV{MOJO_CONFIG} = $home->child(qw(t without-rules.conf))->to_string;
$ENV{PATH} = join ':', $home->child(qw(t bin)), $ENV{PATH};
plan skip_all => "MOJO_CONFIG=$ENV{MOJO_CONFIG}" unless -r $ENV{MOJO_CONFIG};
plan skip_all => 'Started from wrong directory'  unless -x $home->child(qw(t bin git));

my $t = Test::Mojo->new('Toadfarm');
$t->get_ok('/')->content_is('ROOT');
$t->get_ok('/other')->content_is('OTHER');
$t->get_ok('/reload')->content_like(qr{--- cool-repo});

done_testing;
