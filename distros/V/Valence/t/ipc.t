use Test::More tests => 2;

use common::sense;

use AnyEvent;
use Valence;
use Cwd;

my $cv = AE::cv;

my $v = Valence->new;

my $electron = $v->require('electron');

my $app = $electron->attr('app');
my $browser_window = $electron->attr('BrowserWindow');
my $ipc = $electron->attr('ipcMain');

my $main_window;

$app->on(ready => sub {
  $main_window = $browser_window->new({ width => 1000, height => 600, show => \1, });
  my $web_contents = $main_window->attr('webContents');

  $ipc->on('ready' => sub {
    ok(1, 'got ready');

    $web_contents->send(ping => "HELLO");

    $ipc->on('pong' => sub {
      my ($event, $message) = @_;

      is($message, "HELLOHELLO", "got pong");

      $cv->send;
    });
  });

  $main_window->loadURL('file://' . getcwd() . '/t/static/remote.html');

  $main_window->openDevTools;
});

$cv->recv;
