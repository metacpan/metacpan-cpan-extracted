use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;
use Test::Mojo;

my $home = path();
$home = path($home->dirname) if $home->basename eq 'blib';
$ENV{MOJO_CONFIG} = $home->child(qw(t custom-error.conf))->to_string;
plan skip_all => "MOJO_CONFIG=$ENV{MOJO_CONFIG}" unless -r $ENV{MOJO_CONFIG};

my $t = Test::Mojo->new('Toadfarm');

$t->get_ok('/blah')->status_is(404)->content_like(qr{^404444444440404040404040404});

$t->get_ok('/yay.txt')->status_is(200)->content_like(qr{^yay});

done_testing;
