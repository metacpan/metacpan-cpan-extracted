#!/usr/local/bin/perl
use Test::More;
plan tests => 1;

use Test::WWW::Simple;
use Mojolicious::Lite;

$SIG{PIPE} = sub {};
$ENV{MOJO_LOG_LEVEL} = 'error';

my $pid = fork;
if ($pid == 0) {
  diag "starting Mojolicious server";
  my @values = qw(aaaaa bbbbb ccccc ddddd eeeee fffff ggggg);
  get "/"     => sub { shift->render_text(shift @values) };
  get "/stop" => sub { 
    shift->render_text("ok!"); 
    diag 'stopping Mojolicious server';
    kill 9,$$ 
  };
  app->start('daemon');
}
else {
  diag "Waiting for test webserver to spin up";
  sleep 5;
  # actual tests go here
  my @output = `perl -Iblib/lib examples/simple_scan<examples/ss_cache.in`;
  my @expected = map {"$_\n"} split /\n/,<<EOF;
1..9
ok 1 - initial value OK [http://localhost:3000/] [/aaaaa/ should match]
ok 2 - reaccessed as expected [http://localhost:3000/] [/bbbbb/ should match]
ok 3 - intervening page [http://perl.org/] [/perl/ should match]
ok 4 - cached from last get [http://localhost:3000/] [/bbbbb/ should match]
ok 5 - still cached [http://localhost:3000/] [/bbbbb/ should match]
ok 6 - reaccessed as expected [http://localhost:3000/] [/ccccc/ should match]
ok 7 - intervening page [http://perl.org/] [/perl/ should match]
ok 8 - return to last cached value [http://localhost:3000/] [/ccccc/ should match]
ok 9 - now a new value [http://localhost:3000/] [/ddddd/ should match]

EOF
  is_deeply(\@output, \@expected, "working output as expected");

  # shut down webserver
  diag "Shutting down test webserver";
  my $mech = WWW::Mechanize->new(autocheck=>0, timeout=>2);
  $mech->get('http://localhost:3000/stop');
}
