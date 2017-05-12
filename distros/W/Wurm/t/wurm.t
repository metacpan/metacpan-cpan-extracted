#!perl

use strict;
use warnings;

use Test::More;
use Wurm qw(let);

my $mind = { };
my ($app, $wurm) = Wurm::wrapp({
  case => sub {$_[0]->{mind}{body} = ''; $_[0]},
  pore => sub {$_[0]},
  gate => sub {$_[0]->{mind}{body} .= 'gate;'; return;},
  neck => sub {$_[0]->{mind}{body} .= 'neck;'; return;},
  body => {
    qux => sub {$_[0]->{mind}{body} .= 'qux;'; return;},
  },
  tail => sub {
    my $meal = shift;
    $meal->{mind}{body} .= 'tail;';
    return
      unless $meal->{env}{cast};
    return Wurm::_200('nil', $meal->{mind}{body});
  },
}, $mind);

$wurm->{tube}{lost} = {
  gate => sub {$_[0]->{mind}{body} .= 'etag;'; return;},
  neck => sub {
    my $meal = shift;
    $meal->{mind}{body} .= 'kcen;';
    return
      unless $meal->{env}{cast};
    return Wurm::_200('nil', $meal->{mind}{body});
  },
};

is(ref $app,  'CODE', '$app');
is(ref $wurm, 'HASH', '$wurm');

_req($app, get => '/',           0, 404, 'gate;neck;tail;');
_req($app, get => '/',           1, 200, 'gate;neck;tail;');
_req($app, get => 'lost',        1, 200, 'gate;etag;kcen;');
_req($app, get => '/lost',       1, 200, 'gate;etag;kcen;');
_req($app, get => 'lost/',       1, 200, 'gate;etag;kcen;');
_req($app, get => 'lost',        0, 404, 'gate;etag;kcen;');
_req($app, get => '/lost',       0, 404, 'gate;etag;kcen;');
_req($app, get => 'lost/',       0, 404, 'gate;etag;kcen;');
_req($app, get => 'lost/found',  1, 404, 'gate;etag;');
_req($app, get => '/lost/found', 1, 404, 'gate;etag;');
_req($app, get => 'lost/found/', 1, 404, 'gate;etag;');
_req($app, get => 'lost/found',  0, 404, 'gate;etag;');
_req($app, get => '/lost/found', 0, 404, 'gate;etag;');
_req($app, get => 'lost/found/', 0, 404, 'gate;etag;');
_req($app, qux => '/',           1, 200, 'gate;neck;qux;tail;');

done_testing();

sub _req {
  my ($app, $method, $path, $cast, $code, $body) = @_;

  my $name = $code. ' '. $path;
  my $res  = $app->({
    REQUEST_METHOD => $method,
    PATH_INFO      => $path,
    cast           => $cast,
  });

  is($res->[0],     $code, $name. ' code');
  is($mind->{body}, $body, $name. ' body');
}
