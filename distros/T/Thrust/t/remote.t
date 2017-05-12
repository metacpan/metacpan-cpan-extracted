use Test::More tests => 2;

use common::sense;

use AnyEvent;
use Thrust;
use Cwd;

my $cv = AE::cv;

my $t = Thrust->new;

my $w = $t->window(
          root_url => 'file://' . getcwd() . '/t/static/remote.html',
          title => 'My App',
          size => { width => 400, height => 400 },
        )->open_devtools->show;

$w->on('remote', sub {
  is($_[0]->{message}->{ping}, 'from JS', 'got initial message from JS');

  $w->clear('remote');

  $w->on('remote', sub {
    is($_[0]->{message}->{pong}, $$, 'got response message from JS');
    $cv->send;
  });

  $w->remote({ message => { ping => $$ } });
});

$cv->recv;
