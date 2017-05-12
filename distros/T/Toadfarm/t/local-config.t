use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use File::Spec;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

$ENV{MOJO_CONFIG} = File::Spec->rel2abs(File::Spec->catfile(qw( t config.conf )));
plan skip_all => 'MOJO_CONFIG is not readable' unless -r $ENV{MOJO_CONFIG};

make_some_app();

eval <<"HERE" or die $@;
  use Toadfarm -test;
  mount 'Some::App' => {config => {foo => 'local-config'}};
  start;
HERE

my $t = Test::Mojo->new;

$t->get_ok('/config')->json_is('/foo', 'local-config')->json_is('/bar', 'config.conf');

done_testing;

sub make_some_app {
  eval <<'HERE';
  package Some::App;
  use Mojo::Base 'Mojolicious';
  sub startup {
    my $app = shift;
    my %config = %{$app->plugin('Config')};
    $app->routes->get('/config' => sub { shift->render(json => \%config) });
  }
  1;
HERE
}
