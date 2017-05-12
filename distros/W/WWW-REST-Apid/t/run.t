#
#  WWW::REST::Apid unit tests, run by 'make test'.
#  Starts a daemon on localhost:8888 (host and port
#  can be changed with environment variables).

use Test::More tests => 15;
#use Test::More qw(no_plan);
use JSON;
use MIME::Base64;

my @WARNINGS_FOUND;
BEGIN {
    $SIG{__WARN__} = sub { diag( "WARN: ", join( '', @_ ) ); push @WARNINGS_FOUND, @_ };
}

BEGIN { use_ok 'WWW::REST::Apid'};

use LWP;
use LWP::UserAgent;
use HTTP::Status;
use POSIX qw(:sys_wait_h SIGKILL SIGINT);
use Data::Dumper;

my $port = $ENV{WRA_TEST_PORT} || 8888;
my $host = $ENV{WRA_TEST_HOST} || '127.0.0.1';

diag( '' );
diag( '' );
diag( "Using port: $port and host: $host for test server.");
diag( 'If these are not suitable settings on your machine, set the environment' );
diag( 'variables WRA_TEST_PORT and WRA_TEST_HOST to something suitable.');
diag( '' );

our ($serverpid, $ua);

my $b64auth = encode_base64('foo:bar');

# our test cases
our %map = (
	    '/t/0' => {
		       name => '     get data',
		       handler => sub {
			 return { n => 1 };
		       },
		       post => 0,
		       expect => { n => 1 },
		       code => 200
		      },

	    '/t/1' => {
		       name => 'post+validate',
		       handler => sub {
			 my $data = shift;
			 return { sum => $data->{a} + $data->{b} };
		       },
		       validate => { a => 'int', b => 'int' },
		       post => { a => 2, b => 4 },
		       expect => { sum => 6 },
		       code => 200,
		       },

	    '/t/2' => {
		       name => ' authenticate',
		       handler => sub {
			 return { };
		       },
		       header => { Authorization => "apid $b64auth" },
		       expect => { },
		       code => 200,
		       doauth => 1
		       },


);
our $json = JSON->new->allow_nonref;

sub setupserver {
  my $server;
 
  ok(
     $server = WWW::REST::Apid->new(host => $host,
				    port => $port,
				    foreground => 1,
				    sublogin => sub {
				      my($u,$p) = @_;
				      if ($u eq 'foo' && $p eq 'bar') {
					return 1;
				      }
				      return 0;
				    },
				   ),
     "started server"
    );

  isa_ok( $server, 'WWW::REST::Apid');

  foreach my $path (sort keys %map) {
    $server->mapuri(path => $path, %{$map{$path}});
  }

  if (!($serverpid = fork())) {
    $server->run;
    exit(0);
  }
}


sub testuri {
  my ($path, $name, $post, $expect, $code, $header) = @_;

  my $url = "http://$host:$port$path";

  my $ua = LWP::UserAgent->new();
  my $req;

  if ($post) {
    $req = HTTP::Request->new('POST', $url, [], $json->encode($post));
  }
  else {
    $req = HTTP::Request->new(GET => $url);
  }

  foreach my $h (keys %{$header}) {
    $req->header($h => $header->{$h});
  }

  my ($res, $data);

  ok($res = $ua->request($req), "$path (request worked)" );

  cmp_ok($res->code, '==', $code, "$path (result code as expected).");

  diag(join(' ', ($name, $path, $res->code, $res->content)) );

  ok( $data = $json->decode($res->content) );

  is_deeply($data, $expect, "$path (content matched).");
}



# start the daemon
&setupserver();

# test each mapped uri
diag('');
foreach my $path (sort keys %map) {
  &testuri($path, $map{$path}->{name}, $map{$path}->{post},
	   $map{$path}->{expect}, $map{$path}->{code},
	   $map{$path}->{header}
	  );
}

# kill when done
END {
  kill(SIGINT, $serverpid);
}
