use strict;
use warnings;
use Test::More tests => 5;
use_ok('Test::Reporter::Transport::Socket');


{ 
  my $host = '127.0.0.1';
  my $port = 8080;
  my $trans = Test::Reporter::Transport::Socket->new( host => $host, port => $port );
  isa_ok( $trans, 'Test::Reporter::Transport::Socket' );
}

{ 
  my $trans = eval { Test::Reporter::Transport::Socket->new(); };
  ok( !$trans, 'Object is undefined' );
}

{
  my $host = [ '127.0.0.1' ];
  my $port = 8080;
  my $trans = Test::Reporter::Transport::Socket->new( host => $host, port => $port );
  isa_ok( $trans, 'Test::Reporter::Transport::Socket' );
}

{
  my $host = [];
  my $port = 8080;
  my $trans = eval { Test::Reporter::Transport::Socket->new( host => $host, port => $port ); };
  ok( !$trans, 'Object is undefined' );
}

