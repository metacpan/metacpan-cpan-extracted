#!perl
use strict;
use warnings;
use Crypt::CBC;
use Crypt::Rijndael;
use Data::Dumper;
use LWP::UserAgent;
use Test::More;
use Test::Exception;

our $HTTP_PORT = 8967;

if (!$ENV{TL_MEMCACHE_CHECK}) {
    plan skip_all => "skipping tests for Tripletail::MemCached for \$ENV{TL_MEMCACHE_CHECK} being false.";
}

eval {
    require Cache::Memcached;
};
if ($@) {
    plan skip_all => "skipping tests for Tripletail::MemCached for Cache::Memcached being unavailable.";
}

eval {
    require POE;
    require POE::Component::Server::HTTP;
};
if ($@) {
    plan skip_all => "PoCo::Server::HTTP is required for various tests using http server...";
}

eval {
    require HTTP::Cookies;
};
if ($@) {
    return "HTTP::Cookies is required for these tests...";
}

eval {
    require HTTP::Status;
    import HTTP::Status;
};
if ($@) {
    return "HTTP::Status is required for these tests...";
}

eval {
    require URI::QueryParam;
};
if ($@) {
    return "URI::QueryParam is required for these tests...";
}

eval {
    use IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
		LocalPort => $HTTP_PORT,
		Proto => 'tcp',
		Listen => 1,
		ReuseAddr => 1,
       );
    $sock or die;
};
if ($@) {
    plan skip_all => "port $HTTP_PORT/tcp required not to be in use for these tests...";
}


# ------------------------------
# plan
#
plan tests => 8;

# ------------------------------
# server
#
our $SERVER_PID;
our $KEY;
sub start_server () {
    # 子プロセスでPoCo::Server::HTTPを立てる。

    $KEY = '';
    for (1 .. 10) {
		$KEY .= int(rand 0xffffffff);
    }

    if ($_ = fork) {
		$SERVER_PID = $_;

		# サーバーが起動するまで1秒待つ
		#diag("Waiting 1 sec for the coming of server... [pid:$SERVER_PID]");
		sleep 1;
    } else {
		my $script;
		my $ini;
		my $stdin;
		my $env;

		POE::Component::Server::HTTP->new(
			Port => $HTTP_PORT,
			ContentHandler => {
				'/' => sub {
					my ($req, $resp) = @_;

					my $inifile = -d 't' ? "t/tmp$$.ini" : "tmp$$.ini";
					my $script  = "use Tripletail qw($inifile);\n" . $script;
					do {
						open my $fh, '>', $inifile;
						if ($ini) {
							print $fh $ini;
						}
					};

					# その子プロセスでスクリプトをevalする。

					pipe my $p_read, my $c_write;
					pipe my $c_read, my $p_write;
					my $received_data = '';
					if (fork) {
						close $c_write;
						close $c_read;

						if (defined $stdin) {
							print $p_write $stdin;
						}
						close $p_write;

						while (defined($_ = <$p_read>)) {
							$received_data .= $_;
						}

						wait;
					} else {
						close $p_read;
						close $p_write;

						open STDIN,  '<&' . fileno $c_read;
						open STDOUT, '>&' . fileno $c_write;

						if ($env) {
							while (my ($key, $val) = each %$env) {
								$ENV{$key} = $val;
							}
						}

						$ENV{REQUEST_URI} = '/';
						$ENV{SERVER_NAME} = 'localhost';
						$ENV{REQUEST_METHOD} = $req->method;
						$ENV{CONTENT_TYPE} = defined $req->header('Content-Type') ?
						  $req->header('Content-Type') : 'application/x-www-form-urlencoded';
						$ENV{CONTENT_LENGTH} = defined $stdin ? length($stdin) : 0;
						if(defined $req->header('Last-Modified')) {
							$ENV{HTTP_IF_MODIFIED_SINCE} = $req->header('Last-Modified');
						}

						if ($_ = $req->header('Cookie')) {
							$ENV{HTTP_COOKIE} = $_;
						} else {
							delete $ENV{HTTP_COOKIE};
						}

						eval $script;
						exit;
					}

					unlink $inifile;

					# 結果をパースしてhttpdへ渡す。

					my $msg = HTTP::Message->parse($received_data);
					my $retval = $msg->headers->header('Status') || 200;
					$resp->code($retval);
					$resp->message(status_message($resp->code));

					foreach my $key ($msg->headers->header_field_names) {
						$resp->headers->header(
							$key => $msg->headers->header($key));
					}

					$resp->content($msg->content);
					return $retval;
				},

				'/install' => sub {
					my ($req, $resp) = @_;
					my $uri = $req->uri;

					my $cipher = Crypt::CBC->new({
						key    => $KEY,
						cipher => 'Rijndael',
					});

					if (defined($_ = $uri->query_param('ini'))) {
						if ($_ = $cipher->decrypt($_)) {
							$ini = $_;
						}
					}

					if (defined($_ = $uri->query_param('stdin'))) {
						if ($_ = $cipher->decrypt($_)) {
							$stdin = $_;
						}
					}

					if (defined($_ = $uri->query_param('script'))) {
						if ($_ = $cipher->decrypt($_)) {
							$script = $_;
						}
					}

					if (defined($_ = $uri->query_param('env'))) {
						$env = eval $cipher->decrypt($_);
					}

					$resp->code(204);
					$resp->message(status_message($resp->code));
					return 204;
				},
			},
		   );
		POE::Kernel->run;
		exit;
    }
}

sub stop_server () {
    if ($SERVER_PID) {
		#diag("Waiting for the going of server... [pid:$SERVER_PID]");
		
		kill 9, $SERVER_PID;
		wait;

		$SERVER_PID = undef;
    }
}

# ------------------------------
#
my $ua = LWP::UserAgent->new;
my $cookie_jar = HTTP::Cookies->new;
$ua->cookie_jar($cookie_jar);

sub rget {
    $ua->get("http://localhost:$HTTP_PORT/", @_);
}
sub rpost {
    $ua->post("http://localhost:$HTTP_PORT/", @_);
}

sub install (@) {
    my $opts = { @_ };
    my $ini = $opts->{ini};
    my $script = $opts->{script};
    my $env = $opts->{env};
    my $stdin = $opts->{stdin};

    my $cipher = Crypt::CBC->new({
		key    => $KEY,
		cipher => 'Rijndael',
    });

    my $uri = URI->new("http://localhost:$HTTP_PORT/install");
    $uri->query_param(ini    => $cipher->encrypt(defined $ini ? $ini : ''));
    $uri->query_param(script => $cipher->encrypt(defined $script ? $script : ''));
    $uri->query_param(stdin  => $cipher->encrypt(defined $stdin ? $stdin : ''));
    if ($env) {
		$uri->query_param(
			env => $cipher->encrypt(
				Data::Dumper->new([$env])
					->Purity(1)->Useqq(1)->Terse(1)->Dump));
    }

	$ua->get($uri);
}

# ------------------------------
# start
start_server;

# ------------------------------
# memcache
install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			$TL->deleteCache('TLTEST');
			$TL->print('ok');
		}
	},
);
is(rget->content, 'ok', 'Tripletail::Memcache');

install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			my $t = $TL->newTemplate;
			$t->setTemplate(q{<&DATA>})->expand(DATA => qq{testdata});

			return if(!defined($TL->printCacheUnlessModified('TLTEST')));
			$TL->setCache('TLTEST');

			$t->flush;
		}
	},
);
is(rget->content, 'testdata', 'Tripletail::Memcache');

install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			return if(!defined($TL->printCacheUnlessModified('TLTEST')));
		}
	},
);
is(rget->content, 'testdata', 'Tripletail::Memcache');

install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			my $t = $TL->newTemplate;
			$t->setTemplate(q{<&DATA>})->expand(DATA => qq{aadata});

			return if(!defined($TL->printCacheUnlessModified('TLTEST')));
			$TL->setCache('TLTEST');

			$t->flush;
		}
	},
);
is(rget->content, 'testdata', 'Tripletail::Memcache');
install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			my $t = $TL->newTemplate;
			$t->setTemplate(q{<&DATA>})->expand(DATA => qq{aadata});

			return if(!defined($TL->printCacheUnlessModified('TLTEST')));
			$TL->setCache('TLTEST');

			$t->flush;
		}
	},
	env => {
		HTTP_IF_MODIFIED_SINCE => 'Tue, 27 Jun 2006 13:19:57 GMT',
	},
);

is(rget->content, 'testdata', 'Tripletail::Memcache');


install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			$ENV{HTTP_IF_MODIFIED_SINCE} = $TL->newDateTime->toStr('rfc822');
			my $t = $TL->newTemplate;
			$t->setTemplate(q{<&DATA>})->expand(DATA => qq{aadata});

			return if(!defined($TL->printCacheUnlessModified('TLTEST')));

			$t->flush;
		}
	},
);

is(rget->header('Status'), '304', 'Tripletail::Memcache');


# ----差し込み系se

install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			$TL->deleteCache('TLTEST');
			my $t = $TL->newTemplate;
			$t->setTemplate(q{<&DATA>})->setAttr(DATA => 'raw')->expand(DATA => qq{aadata <&TEST> <&TEST2>});

			$TL->setCacheFilter($TL->newForm('<&TEST>' => 'test', '<&TEST2>' => 'test2'),'Shift_JIS');
			return if(!defined($TL->printCacheUnlessModified('TLTEST','200')));
			$TL->setCache('TLTEST',20000);

			$t->flush;
		}
	},
);
is(rget->content, 'aadata test test2', 'Tripletail::Memcache');

install(
	script => q{
		$TL->startCgi(
			-main => \&main,
		   );

		sub main {
			my $t = $TL->newTemplate;
			$t->setTemplate(q{<&DATA>})->setAttr(DATA => 'raw')->expand(DATA => qq{testdata <&TEST> <&TEST2>});

			$TL->setCacheFilter($TL->newForm('<&TEST>' => 'test', '<&TEST2>' => 'test2'));
			return if(!defined($TL->printCacheUnlessModified('TLTEST','200')));
			$TL->setCache('TLTEST');

			$t->flush;
		}
	},
);
is(rget->content, 'aadata test test2', 'Tripletail::Memcache');

# ------------------------------
# stop
END {
    stop_server;
}
