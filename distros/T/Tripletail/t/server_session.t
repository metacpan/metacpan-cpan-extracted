# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config;
use Data::Dumper;
use lib '.';
use t::test_server;

setup();
plan tests => 32;

test_01_basic();  #8.
test_binary();    #2.
test_csv();       #2.
test_text();      #2.
test_02_info();   #1.
test_03_form();   #9.
test_04_mobile(); #6.
teardown();       #1.

# -----------------------------------------------------------------------------
# shortcut.
# 
sub check_requires() { &t::test_server::check_requires; }
sub start_server()   { &t::test_server::start_server; }
sub request_get(@)   { &t::test_server::request_get; }
sub raw_request(@)   { &t::test_server::raw_request; }
sub rget($)
{
	request_get(
		script  => shift,
		db      => 'DB',
		session => 'Session',
	);
}

sub with_filter($$) {
    my $main   = shift;
    my $filter = shift;

    my $script = q{
        $TL->startCgi(
            -main    => \&main,
            -DB      => 'DB',
            -Session => 'Session'
           );
        sub main {
            $TL->setContentFilter('<&FILTER>');
            <&MAIN>
        }
    };
    $script =~ s/<&FILTER>/$filter/;
    $script =~ s/<&MAIN>/$main/;

    return raw_request(
        method => 'GET',
        script => $script
       )->content;
}

# -----------------------------------------------------------------------------
# setup.
# 
sub setup
{
	my $failmsg = check_requires();
	if( $failmsg )
	{
		plan skip_all => $failmsg;
	}
	
	eval{ require DBD::mysql; };
	$@ and plan skip_all => "no DBD::mysql";
	diag "DBD::mysql ".DBD::mysql->VERSION;
	
	&start_server;
	
	# ini.
	my ($name) = getpwuid($<);
	my $ini = {
		DB => {
			type    => 'mysql',
			defaultset  => 'SET_Default',
			SET_Default => 'DBRW1',
		},
		DBRW1 => {
			host     => $ENV{TEST_DBHOST} || 'localhost',
			dbname   => $ENV{TEST_DBNAME} || 'test',
			user     => $ENV{TEST_DBUSER} || $name,
			password => $ENV{TEST_DBPASS},
		},
		Session => {
			mode         => 'http',
			dbgroup      => 'DB',
			dbset        => 'SET_Default',
			sessiontable => 'TripletaiL_Session_Test',
			csrfkey      => 'TripletaiL_Key',
		},
	};
	
	# check db connection.
	my $ver = eval
	{
		request_get(
			ini     => $ini,
			db      => 'DB', 
			session => 'Session',
			script  => q{ $TL->getDB()->selectRowArray('SELECT version()'); },
		);
	};
	if( $@ )
	{
		if( $@ =~ m{(DBI connect.+?)(<br|\n|$)})
		{
			# DBI connect error.
			$_ = $1;
			s/&#39;/'/g;
			plan skip_all => $_;
		}
		# other error?
		plan skip_all => "request failure: $@";
	}
	$ver &&= $ver->[0];
	diag("MySQL $ver");
}

# -----------------------------------------------------------------------------
# basic.
# 
sub test_01_basic
{
	ok( rget q{ $TL->getSession; }, '[basic] getsession');
	
	ok( rget q{
			my $s = $TL->getSession;
			not $s->isHttps;
		} => '[basic] not isHttps');
	
	# セッションキーの取得.
	ok( rget q{
			my $s = $TL->getSession;
			my $first = $s->get;
			my $next = $s->get;
			$first eq $next;
		} => '[basic] session-id is persistent');
	
	ok( rget q{
			my $s = $TL->getSession;
			my $old = $s->get;
			my $new = $s->renew;
			$old ne $new;
		} => '[basic] renew session-id');
	
	ok( rget q{
			my $s = $TL->getSession;
			my $old = $s->get;
			$s->discard;
			my $new = $s->get;
			$old ne $new;
		} => '[basic] discard session-id');
	
	ok( rget q{
			my $s = $TL->getSession;
			not defined $s->getValue;
		}, '[basic] session value is initialized by undef');
	
	is( rget q{
			my $s = $TL->getSession;
			$s->setValue('666');
			$s->getValue;
		}, '666', '[basic] set and get value');
	
	is( rget q{
			my $s = $TL->getSession;
			$s->getValue;
		}, '666', '[basic] session value is persistent');
}

# -----------------------------------------------------------------------------
# binary
#
sub test_binary {
    is with_filter(q{
           my $s = $TL->getSession;
           $s->setValue('666');
           $TL->print($s->getValue);
         }, 'Tripletail::Filter::Binary')
      , '666', '[binary] set and get';

    is with_filter(q{
           my $s = $TL->getSession;
           $TL->print($s->getValue);
         }, 'Tripletail::Filter::Binary')
      , '666', '[binary] get';
}

# -----------------------------------------------------------------------------
# csv
#
sub test_csv {
    is with_filter(q{
           my $s = $TL->getSession;
           $s->setValue('666');
           $TL->print([$s->getValue]);
         }, 'Tripletail::Filter::CSV')
      , "666\r\n", '[csv] set and get';

    is with_filter(q{
           my $s = $TL->getSession;
           $TL->print([$s->getValue]);
         }, 'Tripletail::Filter::CSV')
      , "666\r\n", '[csv] get';
}

# -----------------------------------------------------------------------------
# text
#
sub test_text {
    is with_filter(q{
           my $s = $TL->getSession;
           $s->setValue('666');
           $TL->print($s->getValue);
         }, 'Tripletail::Filter::TEXT')
      , '666', '[text] set and get';

    is with_filter(q{
           my $s = $TL->getSession;
           $TL->print($s->getValue);
         }, 'Tripletail::Filter::TEXT')
      , '666', '[text] get';
}

# -----------------------------------------------------------------------------
# info.
#
sub test_02_info
{
	ok( rget q{
			my $s = $TL->getSession;
			[$s->getSessionInfo];
		} => '[info] getSessionInfo');
}

# -----------------------------------------------------------------------------
# form.
# 
sub test_03_form
{
	ok( rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
			});
			$t->addSessionCheck('Session', 'TEST');
			
			my $form = $t->getForm('TEST');
			$form->haveSessionCheck('Session');
		} => '[form] addSessionCheck/haveSessionCheck w/ form name');
	
	ok( rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<?xml version="1.0" encoding="UTF-8" ?>
				<form method="post">
				</form>
				});
			$t->addSessionCheck('Session');
			
			my $form = $t->getForm;
			$form->haveSessionCheck('Session');
		} => '[form] addSessionCheck/haveSessionCheck w/o form name');
	
	ok( rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<?xml version="1.0" encoding="UTF-8" ?>
				<form method="post">
				</form>
				});
			$t->addSessionCheck( $TL->getSession('Session') );
			
			my $form = $t->getForm;
			$form->haveSessionCheck( $TL->getSession('Session') );
		} => '[form] addSessionCheck/haveSessionCheck, session obj');
	
	my $re_err_no_session_group = 
		qr/^Tripletail::Template::Node#addSessionCheck: arg\[1\] is not defined/;
	throws_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
				});
			$t->addSessionCheck;
		}} $re_err_no_session_group => '[form] addSessionCheck die (session group requires)';
	
	dies_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
				});
			$t->addSessionCheck('Session2', 'TEST');
		};} '[Template] addSessionCheck die';
	
	dies_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
				});
			$t->addSessionCheck('Session', 'TEST2');
		};} '[Template] addSessionCheck die';
	
	dies_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
				});
			$t->addSessionCheck('Session', \123);
		};} '[Template] addSessionCheck die';
	
	dies_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
				});
			$t->addSessionCheck('Session', 'TEST' , \123);
		};} '[Template] addSessionCheck die';
	
	dies_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="post">
				</form>
				});
			$t->addSessionCheck('Session', 'TEST' , \123);
		};} '[Template] addSessionCheck die';
	
	dies_ok { rget q{
			my $t = $TL->newTemplate->setTemplate(q{
				<form name="TEST" method="get">
				</form>
				});
			$t->addSessionCheck('Session', 'TEST');
		};} '[Template] addSessionCheck die';
}

# -----------------------------------------------------------------------------
# mobile
#
sub test_04_mobile {
    my $html = raw_request(
        method => 'GET',
        script => q{
            $TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
            $TL->startCgi(
                -main    => \&main,
                -DB      => 'DB',
                -Session => 'Session',
               );
            sub main {
                $TL->setContentFilter('Tripletail::Filter::MobileHTML');

                my $s = $TL->getSession;
                $s->setValue('123456789');

                $TL->print(q{
                      <a href="link-1"></a>
                      <a href="link-2?INT=1"></a>
                      <form action="index.cgi" name="form-1" EXT="1"></form>
                      <form action="index.cgi" name="form-2"></form>
                  });
            }
        },
       )->content;

    like $html, qr{<a href="link-1"></a>},
      'the link without INT=1 is not rewritten';

    like $html, qr{<a href="link-2\?SIDSession=[^"]+"></a>},
      'the link with INT=1 is rewritten';

    like $html, qr{<form action="index.cgi" name="form-1"></form>},
      'the form with EXT="1" is not rewritten';

    like $html, qr{<form action="index.cgi" name="form-2">(.*?)<input type="hidden" name="SIDSession" value="[^"]+"></form>},
      'the form without EXT="1" is rewritten';

    # リンクから SID を取り出す
    $html =~ m{<a href="link-2\?(SIDSession=[^"]+)"></a>} or die;
    my $query = $1;

    # フォームから取り出した SID が等しい事を確認。
    $html =~ m{<input type="hidden" name="SIDSession" value="([^"]+)">} or die;
    is $query, "SIDSession=$1", 'the session ID is the same';

    # セッションが繋がっているかどうかを確認。
    is raw_request(
        method  => 'GET',
        env     => {
            QUERY_STRING => $query,
        },
        script  => q{
            $TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
            $TL->startCgi(
                -main    => \&main,
                -DB      => 'DB',
                -Session => 'Session',
               );
            sub main {
                $TL->setContentFilter('Tripletail::Filter::MobileHTML');

                my $s = $TL->getSession;
                $TL->print($s->getValue);
            }
        },
       )->content, '123456789',
         'getting the session value through the link';
}

# -----------------------------------------------------------------------------
# teardown.
#
sub teardown
{
	is rget q{
			my $DB = $TL->getDB();
			$DB->execute(q{
				DROP TABLE IF EXISTS TripletaiL_Session_Test
			});
			'ok';
    } => 'ok', '[teardown] drop table';
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
