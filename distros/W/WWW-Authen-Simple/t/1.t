# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# These tests, and WWW:A:S, rely on a database to work. So, this is 
# a big mess which is mostly messy because it has to be able to run
# against some test database.

use Test::More tests => 63;
use DBI;
use Digest::MD5 ();
use Config;

eval {
	require WWW::Authen::Simple;
};
is($@, '', 'loading module');

eval {
	import WWW::Authen::Simple;
};
is($@, '', 'running import');

unless (defined(do 't/dbh.config'))
{
	die $@ if $@;
	unless (defined(do 'dbh.config'))
	{
		die $@ if $@;
		die "Could not read dbh.config: $!\n";
	}
}
my %opt = load_all();

my $datasource;
if ($opt{'dsn'})
{
	$datasource = $opt{'dsn'};
} else {
	my $driver = $opt{'driver'} || 'mysql';
	my $dbname = $opt{'dbname'} || 'test';
	my $host = $opt{'host'};
	my $port = $opt{'port'};
	$datasource = ___drivers($driver, {
		'driver' => $driver,
		'dbname' => $dbname,
		'host'	=> $host,
		'port'	=> $port
		} );
}
eval {
	$dbh = DBI->connect($datasource,$opt{'user'},$opt{'password'});
};


# We can't do any tests without a database.
SKIP: {
    skip("Can't test internals without a database connection.", 61)
        unless ref($dbh) && UNIVERSAL::isa($dbh, 'DBI::db');

    ok( UNIVERSAL::isa($dbh, 'DBI::db'), "Get a database handle for testing" );
    ok( $dbh->ping(), "We are indeed connected" );

    # setup default session tables
    eval {
        $dbh->do("CREATE TABLE sessions (username CHAR(63), address CHAR(255), ticket CHAR(255), point CHAR(255) )");
        $dbh->do("CREATE TABLE Users (uid INT(11), login CHAR(63), passwd TEXT, Disabled CHAR(1) )");
        $dbh->do("CREATE TABLE Groups (gid INT(11), Name CHAR(31) )");
        $dbh->do("CREATE TABLE UserGroups (gid INT(11), uid INT(11), accessbit CHAR(1) )");
    };
    is($@,'','create test tables');

    my $test_passwd = Digest::MD5::md5_base64('test');

    eval {
        $dbh->do("INSERT INTO Users (uid,login,passwd,Disabled) VALUES ('1','test', '$test_passwd', '0')");
        $dbh->do("INSERT INTO Users (uid,login,passwd,Disabled) VALUES ('1','disuser', '$test_passwd', '1')");
        $dbh->do("INSERT INTO Groups (gid, Name) VALUES ('1','readg')");
        $dbh->do("INSERT INTO UserGroups (gid,uid,accessbit) VALUES ('1','1','1')");
        $dbh->do("INSERT INTO Groups (gid, Name) VALUES ('2','writeg')");
        $dbh->do("INSERT INTO UserGroups (gid,uid,accessbit) VALUES ('2','1','2')");
        $dbh->do("INSERT INTO Groups (gid, Name) VALUES ('3','readwriteg')");
        $dbh->do("INSERT INTO UserGroups (gid,uid,accessbit) VALUES ('3','1','3')");
    };
    is($@,'','insert test data');


    my $s;
    eval {
        $s = WWW::Authen::Simple->new( db => $dbh, cookie_domain => 'test.tld' );
    };
    ok( UNIVERSAL::isa($s, 'WWW::Authen::Simple'), "Created WWW::Authen::Simple object");

    # set REMOTE_ADDR, cause WWW:A:S needs it
    $ENV{REMOTE_ADDR} = '127.0.0.1';
    my @rv = $s->login('test','test');
    ok( ($rv[0] > 0) , "Loggin successful"); 

    ok( $s->logged_in(), 'logged_in() method');
    ok( $s->uid() eq '1', 'uid() method');
    ok( $s->username() eq 'test', 'username() method');
    ok( $s->groups(), 'groups() method');

    my @groups = $s->groups();
    ok( grep(/^readg$/, @groups), 'groups() return value (readg)');
    ok( grep(/^writeg$/, @groups), 'groups() return value (writeg)');
    ok( grep(/^readwriteg$/, @groups), 'groups() return value (readwriteg)');

    ok( $s->in_group('readg') == 1, 'in_group(\'readg\')');
    ok( $s->in_group('writeg') == 2, 'in_group(\'writeg\')');
    ok( $s->in_group('readwriteg') == 3, 'in_group(\'readwriteg\')');
    ok( ! $s->in_group('bogusg'), 'not in_group(\'bogusg\')');
    ok( $s->in_group('1') == 1, 'in_group(1) : 1 is the gid of readg');

    ok( $s->in_group('readg','r'), 'in_group(\'readg\',\'r\')');
    ok( $s->in_group('writeg','w'), 'in_group(\'writeg\',\'w\')');
    ok( $s->in_group('readwriteg','rw'), 'in_group(\'readwriteg\',\'rw\')');
    ok( $s->in_group('readwriteg','r'), 'in_group(\'readwriteg\',\'r\')');
    ok( $s->in_group('readwriteg','w'), 'in_group(\'readwriteg\',\'w\')');
    ok( $s->in_group('readg','1'), 'in_group(\'readg\',\'1\')');
    ok( $s->in_group('1','1'), 'in_group(\'1\',\'1\')');
    ok( $s->in_group('1','r'), 'in_group(\'1\',\'r\')');

    ok( ! $s->in_group('readg','w'), 'not in_group(\'readg\',\'w\')');
    ok( ! $s->in_group('writeg','r'), 'not in_group(\'writeg\',\'r\')');
    ok( ! $s->in_group('readg','rw'), 'not in_group(\'readg\',\'rw\')');
    ok( ! $s->in_group('writeg','rw'), 'not in_group(\'writeg\',\'rw\')');
    ok( ! $s->in_group('bogusg','r'), 'not in_group(\'bogusg\',\'r\')');
    ok( ! $s->in_group('bogusg','w'), 'not in_group(\'bogusg\',\'w\')');
    ok( ! $s->in_group('bogusg','rw'), 'not in_group(\'bogusg\',\'rw\')');

    # check session db
    {
        my $sth = $dbh->prepare("SELECT username,address,ticket,point FROM sessions WHERE username = ? AND address = ?")
            or die "can't select data from database table sessions";
        $sth->execute('test','127.0.0.1')
            or die "can't select data from database table sessions";
        my ($user,$addr,$ticket,$point) = $sth->fetchrow_array();
        $sth->finish;
        ok( $user eq 'test', 'sessions table check: username field = test');
        ok( $addr eq '127.0.0.1', 'sessions table check: address field = 127.0.0.1');
        ok( length($ticket) > 30, 'sessions table check: length ticket field > 30');
        ok( $point =~ /^\d+$/, 'sessions table check: point field is int');
    }

    $s->logout();
    ok( ! $s->logged_in(), 'logout() method [via logged_in]');
    ok( ! $s->in_group('readg','r'), 'logout() method [via in_group]');

    # check session db
    {
        my $sth = $dbh->prepare("SELECT username,address,ticket,point FROM sessions WHERE username = ? AND address = ?")
            or die "can't select data from database table sessions";
        $sth->execute('test','127.0.0.1')
            or die "can't select data from database table sessions";
        my ($user,$addr,$ticket,$point) = $sth->fetchrow_array();
        $sth->finish;
        ok( $user eq 'test', 'sessions table check: username field = test');
        ok( $addr eq '127.0.0.1', 'sessions table check: address field = 127.0.0.1');
        ok( $ticket eq '*', 'sessions table check: ticket field = *');
        ok( $point == 0, 'sessions table check: point field = 0');
    }

    #################################################
    # create a failed login, make sure it all fails #
    #################################################
    # create a bunch of WWW:A:S objects to work with
    my @s;
    for (0 .. 12) {
        $s[$_] = WWW::Authen::Simple->new( db => $dbh, cookie_domain => 'test.tld' );
    }
    my @rvs; # return values
    # test bad passwd
    @{$rv[0]} = $s[0]->login('test','badpasswd');
    ok( ($rv[0]->[0] == 0) , "login(): Test bad passwd"); 
    # test bad user
    @{$rv[1]} = $s[1]->login('nosuchuser','test');
    ok( ($rv[1]->[0] == 0) , "login(): Test nonexisting user"); 
    # test disabled user
    @{$rv[2]} = $s[2]->login('disuser','test');
    ok( ($rv[2]->[0] == 0) , "login(): Test disabled user"); 
    # test no user/pass, no cookies
    @{$rv[3]} = $s[3]->login();
    ok( (($rv[3]->[0] == 0) && ($rv[3]->[1] == 0)) , "login(): Test no user/pass, no cookies"); 

    #########################################
    # now, we've got to check cookies stuff #
    #########################################
    # TODO: need to figure out how to do this...
    # will need to test:
    #	expected cookie strings are being printed
    #	catch those, make cookies, pass to new WWW:A:S object
    #	check exisiting session auth by cookie worked

    @{$rv[4]} = $s[4]->login('test','test');
    delete $ENV{HTTP_COOKIE};
    delete $ENV{COOKIE};
    my $t_ticket;
    # test good cookie
    $t_ticket = &fetch_ticket();
    $ENV{HTTP_COOKIE} = "login=test; ticket=$t_ticket";
    @{$rv[5]} = $s[5]->login();
    ok( ($rv[5]->[0] == 1) , "login(): via session cookies"); 
    delete $ENV{HTTP_COOKIE};
    # test bad user, good ticket
    $t_ticket = &fetch_ticket();
    $ENV{HTTP_COOKIE} = "login=nosuchuser; ticket=$t_ticket";
    @{$rv[6]} = $s[6]->login();
    ok( ($rv[6]->[0] == 0) , "login(): Bad user session cookie test"); 
    delete $ENV{HTTP_COOKIE};
    # bad ticket
    $t_ticket = &fetch_ticket();
    $ENV{HTTP_COOKIE} = "login=test; ticket=nosuchticket";
    @{$rv[7]} = $s[7]->login();
    ok( ($rv[7]->[0] == 0) , "login(): Bad ticket session cookie test"); 
    delete $ENV{HTTP_COOKIE};
    # expired ticket
    $t_ticket = &fetch_ticket();
    $ENV{HTTP_COOKIE} = "login=test; ticket=*";
    @{$rv[8]} = $s[8]->login();
    ok( ($rv[8]->[0] == 0) , "login(): Expired ticket session cookie test"); 
    delete $ENV{HTTP_COOKIE};

    ##########################
    # test output of cookies
    # Test::More does STDOUT magic, so this works
    # NOTE: STDOUT is basically closed, so the first
    # handle that get's open gets file descriptor 1, which perl thinks
    # should be opened for output only. It'll give warning unless we
    # put something else in those slots.

    # open STDOUT first, cause it's what kicks the first fd back to 1
    open STDOUT, ">blah1.out" or die "can't open stdout";
    close STDOUT;
    # open SLOT1 to hold onto file descriptor 1
    open SLOT1, ">blah1.out" or die "can't open slot1";
    #open SLOT2, "<blah1.out" or die "can't open slot2";
    #open SLOT3, "blah1.out" or die "can't open slot3";
    {	# test that login(user,pass) with good user/pass works
        open STDOUT, ">test.out" or die "can't open test.out";
        my @rv = $s[9]->login('test','test');
        close STDOUT;
        open(COOKIE, "<test.out")or die "can't open test.out";
        my @cookie_contents = <COOKIE>;
        close COOKIE;
        $t_ticket = &fetch_ticket();
        ok( $cookie_contents[0] eq "Set-Cookie: login=test; domain=test.tld; max-age=3600; path=/; version=1\n", "login(user,pass) cookies: Got correct Set-Cookie string (login cookie)");
        ok( $cookie_contents[1] eq "Set-Cookie: ticket=$t_ticket; domain=test.tld; max-age=3600; path=/; version=1\n", "login(user,pass) cookies: Got correct Set-Cookie string (ticket cookie)");
    }
    {	# test that login() with good user/pass cookie works
        $ENV{HTTP_COOKIE} = "login=test; ticket=$t_ticket";
        open STDOUT, ">test.out" or die "can't open test.out";
        my @rv = $s[10]->login();
        close STDOUT;
        open COOKIE, "test.out" or die "can't open test.out";
        my @cookie_contents = <COOKIE>;
        close COOKIE;
        $t_ticket = &fetch_ticket();
        ok( $cookie_contents[0] eq "Set-Cookie: login=test; domain=test.tld; max-age=3600; path=/; version=1\n", "login(viacookies) cookies: Got correct Set-Cookie string (login cookie)");
        ok( $cookie_contents[1] eq "Set-Cookie: ticket=$t_ticket; domain=test.tld; max-age=3600; path=/; version=1\n", "login(viacookies) cookies: Got correct Set-Cookie string (ticket cookie)");
        delete $ENV{HTTP_COOKIE};
    }
    {	# test that login(user,pass) fails with bad pass
        open STDOUT, ">test.out" or die "can't open test.out";
        my @rv = $s[11]->login('test','badpasswd');
        close STDOUT;
        open COOKIE, "test.out" or die "can't open test.out";
        my @cookie_contents = <COOKIE>;
        close COOKIE;
        ok( ! @cookie_contents, "login(user,badpass) cookies: Null cookies on bad password to login()");
    }
    {	# test that login(user,pass) fails with bad user
        open STDOUT, ">test.out" or die "can't open test.out";
        my @rv = $s[11]->login('nosuchuser','test');
        close STDOUT;
        open COOKIE, "test.out" or die "can't open test.out";
        my @cookie_contents = <COOKIE>;
        close COOKIE;
        ok( ! @cookie_contents, "login(baduser,pass) cookies: Null cookies on bad user to login()");
    }
    {	# test that login() fails with bad user/pass cookie
        $ENV{HTTP_COOKIE} = "login=test; ticket=badticket";
        open STDOUT, ">test.out" or die "can't open test.out";
        my @rv = $s[12]->login();
        close STDOUT;
        open COOKIE, "test.out" or die "can't open test.out";
        my @cookie_contents = <COOKIE>;
        close COOKIE;
        ok( ! @cookie_contents, "login() cookies: Null cookies on null login, bad cookies.");
        delete $ENV{HTTP_COOKIE};
    }
    {	# test that logout() sets the right cookies
        $ENV{HTTP_COOKIE} = "login=test; ticket=*";
        my $s = WWW::Authen::Simple->new( db => $dbh, cookie_domain => 'test.tld' );
        open STDOUT, ">test.out" or die "can't open test.out";
        $s->logout();
        close STDOUT;
        open COOKIE, "test.out" or die "can't open test.out";
        my @cookie_contents = <COOKIE>;
        close COOKIE;
        ok( $cookie_contents[0] eq "Set-Cookie: login=test; domain=test.tld; max-age=0; path=/; version=1\n", "logout() cookies: Got correct Set-Cookie string (login cookie)");
        ok( $cookie_contents[1] eq "Set-Cookie: ticket=*; domain=test.tld; max-age=0; path=/; version=1\n", "logout() cookies: Got correct Set-Cookie string (ticket cookie)");
        delete $ENV{HTTP_COOKIE};
    }
    close SLOT1;

    # cleanup the tables we created/used
    &cleanup_db();
} # end of SKIP if ! $dbh


# clean up after ourselves.
END { unlink "blah1.out"; unlink "test.out"; }


sub cleanup_db
{
	# cleanup databases
	#if (0) {
	eval {
		$dbh->do("DROP TABLE UserGroups");
		$dbh->do("DROP TABLE sessions");
		$dbh->do("DROP TABLE Users");
		$dbh->do("DROP TABLE Groups");
	};
#	print "ok 48\n" unless $@;
#	print "nook 48\n" if $@;
	is($@,'','drop our temp tables');
	#}
}

sub fetch_ticket
{
	my $sth = $dbh->prepare("SELECT ticket FROM sessions WHERE username = ? AND address = ?") or die "can't prepare fetch_ticket statement: $DBI::errstr";
	$sth->execute('test','127.0.0.1') or die "can't execute fetch_ticket statement: $DBI::errstr";
	my ($t_ticket) = $sth->fetchrow_array() or die "can't fetchrow_array() fetch_ticket statement: $DBI::errstr";
	$sth->finish;
	return $t_ticket;
}

# this code ripped from DBIx::PDlib
sub ___drivers
{
	my ($driver,$config) = @_;
	my %drivers = (
		# Feel free to add new drivers... note that some DBD data_sources
		# do not translate well (eg Oracle).
		mysql       => "dbi:mysql:$$config{dbname}:$$config{host}:$$config{port}",
		msql        => "dbi:msql:$$config{dbname}:$$config{host}:$$config{port}",
		Pg          => "dbi:Pg:$$config{dbname}:$$config{host}:$$config{port}",
		# According to DBI, drivers should use the below if they have no
		# other preference.  It is ODBC style.
		DEFAULT     => "dbi:$driver:"
		);
	# Make Oracle look a little bit like other DBs.
	# Right now we only have one hack, but I can imagine there being
	# more...
	if ($driver eq 'Oracle') {
		$$config{'sid'} ||= delete($$config{'dbname'});
		$ENV{ORACLE_HOME} = $$config{'home'} unless (-d $ENV{ORACLE_HOME});
	}
	my @keys;
	foreach (keys(%$config)) {
		next if /^user$/;
		next if /^password$/;
		next if /^driver$/;
		push(@keys,"$_=$$config{$_}");
	}
	$drivers{'DEFAULT'} .= join(';',@keys);
	if ($drivers{$driver}) {
		return $drivers{$driver};
	} else {
		return $drivers{'DEFAULT'};
	}
}

