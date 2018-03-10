use lib '.';
use t::Helper;

$ENV{MOJO_SELENIUM_DRIVER} = t::Helper->mock_driver;

eval <<'HERE' or die $@;
package MyApp;
use Mojo::Base 'Mojolicious';
use FindBin qw/$Bin/;
sub startup {
  my $self = shift;
  my $cfg = $self->plugin(Config => {file => "$Bin/config-override.conf"});
  $self->routes->get('/' => sub { shift->render(text => $cfg->{value}) } );
}
1;
HERE

my $t = t::Helper->t('MyApp');
isa_ok($t->app, 'MyApp');
is $t->app->config->{value}, 'initial', 'original value in config';
$t->navigate_ok('/')->get_ok('/')->content_is('initial',, 'original value in response');

$t = t::Helper->t('MyApp', {value => 'override'});
isa_ok($t->app, 'MyApp');
is $t->app->config->{value}, 'override', 'overwritten value in config';
$t->navigate_ok('/')->get_ok('/')->content_is('override', 'overwritten value in response');

done_testing;
