use Test::More;

eval "require HTTP::Daemon";
if( $@ ) {
    plan skip_all => 'HTTP::Daemon unavailable';
}
elsif ( $^O eq 'MSWin32') {
    plan skip_all => 'Piped open not available';
}
else {
    plan tests => 9;
}

use Test::WWW::Simple;

$SIG{PIPE} = sub {};

my $pid = open($child, "-|");
if ($pid == 0) {
  my @values = qw(aaaaa bbbbb ccccc ddddd eeeee fffff ggggg);
  my $index = 0;
  diag "Starting test webserver";
  $daemon = HTTP::Daemon->new(LocalAddr => '127.0.0.1');
  print STDOUT $daemon->url;
  close STDOUT;
DAEMON: 
  while (my $connection = $daemon->accept) {
    while (my $request = $connection->get_request) {
      last DAEMON if ($request->uri->as_string =~ /stop/); 
      $connection->send_response($values[$index]);
      $index++;
    }
    $connection ->close;
    undef $connection;
  }
  diag "daemon stopped";
}
else {
  chomp(my $url = <$child>);
  diag "Webserver up on $url";
  # actual tests go here
  no_cache;
  page_like($url, qr/aaaaa/, 'initial value as expected');
  page_like($url, qr/bbbbb/, 'reaccessed as expected');
  cache;
  page_like('http://perl.org', qr/perl/i,   'intervening page');
  page_like($url, qr/bbbbb/, 'cached from last get');
  page_like($url, qr/bbbbb/, 'remains cached');
  no_cache "turned off again";
  page_like($url, qr/ccccc/, 'reaccessed again as expected');
  page_like('http://perl.org', qr/perl/i,   'intervening page');
  cache "back on again";
  page_like($url, qr/ccccc/, 'return to last cached value');
  no_cache;
  page_like($url, qr/ddddd/, 'now a new value');
  
  diag "Shutting down test webserver";
  mech->get($url . "/stop");
}
