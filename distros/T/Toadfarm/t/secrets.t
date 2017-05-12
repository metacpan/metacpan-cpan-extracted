use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

plan skip_all => 'Cannot run as root' if $< == 0 or $> == 0;

{
  use Toadfarm -test;
  mount 't::lib::Test' => {Host => 'thorsen.pm'};
  mount 't::lib::Test';
  secrets qw( s3cret yesterday );
  start;
}

my $t = Test::Mojo->new;

is_deeply $t->app->secrets, [qw( s3cret yesterday )], 'toadfarm secrets';

$t->get_ok('/secrets')->content_is('["s3cret","yesterday"]');
$t->get_ok('/secrets', {Host => 'thorsen.pm'})->content_is('["s3cret","yesterday"]');

done_testing;
