#!/usr/bin/env perl
use Test::More;
plan tests => 1;

use Cwd;
use Test::WWW::Simple;
use Mojolicious::Lite;
use Mojo::IOLoop;
use Mojo::Server::Daemon;

$SIG{PIPE} = sub {};
$ENV{MOJO_LOG_LEVEL} = 'error';

my $pid  = fork;
my $port = Mojo::IOLoop::Server->generate_port;

if ($pid == 0) {
  note "starting Mojolicious server";
  my @values = qw(aaaaa bbbbb ccccc ddddd eeeee fffff ggggg);
  get "/"     => sub { my $v = shift(@values); shift->render(text=>$v) };
  get "/stop" => sub { 
    shift->render(text=>"ok!"); 
    diag 'stopping Mojolicious server';
    exit; 
  };
  
  my $daemon = Mojo::Server::Daemon->new(
    app    => app,
    listen => ["http://*:$port"]
  );
  $daemon->run;
}
else {
  diag "Waiting for test webserver to spin up";
  sleep 5;
  $port++;
  # actual tests go here
  open my $ss_cmds, "<", cwd()."/examples/ss_cache.in" or die $!;
  my @commands = <$ss_cmds>;
  my($fh,$file) = File::Temp::tempfile();
  @commands = map { s/3000/$port/g; $_ } @commands;
  print $fh @commands;
  close $fh;
  my @output = `$^X -Iblib/lib examples/simple_scan < $file`;
  my @expected = map {"$_\n"} split /\n/,<<EOF;
1..9
ok 1 - initial value OK [http://localhost:$port/] [/aaaaa/ should match]
ok 2 - reaccessed as expected [http://localhost:$port/] [/bbbbb/ should match]
ok 3 - intervening page [http://perl.org/] [/perl/ should match]
ok 4 - cached from last get [http://localhost:$port/] [/bbbbb/ should match]
ok 5 - still cached [http://localhost:$port/] [/bbbbb/ should match]
ok 6 - reaccessed as expected [http://localhost:$port/] [/ccccc/ should match]
ok 7 - intervening page [http://perl.org/] [/perl/ should match]
ok 8 - return to last cached value [http://localhost:$port/] [/ccccc/ should match]
ok 9 - now a new value [http://localhost:$port/] [/ddddd/ should match]

EOF
  is_deeply(\@output, \@expected, "working output as expected");

  # shut down webserver
  diag "Shutting down test webserver";
  my $mech = WWW::Mechanize->new(autocheck=>0, timeout=>2);
  $mech->get("http://localhost:$port/stop");
}
