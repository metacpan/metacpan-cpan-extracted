use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config;
use Data::Dumper;
use lib '.';
use t::test_server;

&setup;
plan tests => 20;

&test_01_basic; #8.
&test_02_info;  #1.
&test_03_form;  #9.
&teardown;      #1.

# -----------------------------------------------------------------------------
# shortcut.
# 
sub check_requires() { &t::test_server::check_requires; }
sub start_server()   { &t::test_server::start_server; }
sub request_get(@)   { &t::test_server::request_get; }
sub rget($)
{
	request_get(
		script  => shift,
		db      => 'DB',
		session => 'Session',
	);
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
			mysqlsessiontabletype => 'InnoDB',
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
