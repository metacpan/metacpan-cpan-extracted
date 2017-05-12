# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl User-Simple.t'

use strict;
use DBI;
use File::Temp qw(:mktemp);
my ($db, $tmp_file);

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 40;
BEGIN { use_ok('User::Simple'); use_ok('User::Simple::Admin') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$tmp_file = mktemp('User-Simple-build-XXXXXX');
eval { $db = DBI->connect('DBI:SQLite:dbname=' .$tmp_file) };

SKIP: {
    my ($ua, $adm_id, $usr_id, $usr, $session, %users, %sessions);
    skip 'Not executing the complete tests: Database handler not created ' .
	'(I need DBD::SQLite for this)', 37 unless $db;

    ###
    ### First, the User::Simple::Admin tests...
    ###

    # Create now the database and our table - Add 'descr' and 'adm_level' 
    # fields
    ok($ua = User::Simple::Admin->create_plain_db_structure($db,'user_simple',
	      'descr varchar(30), adm_level integer'),
       'Created a new table and an instance of a User::Simple::Admin object');

    # Create some user accounts
    ok(($ua->new_user(login => 'admin',
		      descr => 'Administrative user',
		      passwd => 'Iamroot',
		      adm_level => 5) and
	$ua->new_user(login => 'adm2',
		      descr => 'Another administrative user',
		      passwd => 'stillagod',
		      adm_level => 2) and
	$ua->new_user(login => 'user1',
		      descr => 'Regular user 1',
		      passwd => 'a_password',
		      adm_level => 0) and
	$ua->new_user(login => 'user2',
		      descr => 'Regular user 2',
		      passwd => 'a_password',
		      adm_level => 0) and
	$ua->new_user(login => 'user3',
		      descr => 'Regular user 3',
		      passwd => 'a_password',
		      adm_level => 0) and
	$ua->new_user(login => 'user4',
		      descr => 'Regular user 4',
		      passwd => '',
		      adm_level => 0) and
	$ua->new_user(login => 'user5',
		      descr => 'Regular user 5',
		      passwd => 'a_password',
		      adm_level => 0)),
       'Created some users to test on');

    # Does dump_users report the right amount of users?
    %users = $ua->dump_users;
    is(scalar(keys %users), 7, 'Right number of users reported');

    # Now do some queries on them...
    $adm_id = $ua->id('admin');
    $usr_id = $ua->id('user2');

    # Get the information they were created with
    is($ua->login($adm_id), 'admin', 'First user reports the right login');
    is($ua->descr($adm_id), 'Administrative user', 
       'First user reports the right descr');
    is($ua->adm_level($adm_id), 5, 
       'First user reports the right adm_level');
    
    is($ua->login($usr_id), 'user2', 'Second user reports the right login');
    is($ua->descr($usr_id), 'Regular user 2', 
       'Second user reports the right descr');
    is($ua->adm_level($usr_id), 0, 
       'Second user reports the right adm_level');

    # Change their details
    ok($ua->set_login($usr_id, 'luser1'), 
       'Successfully changed the user login');
    is($ua->id('luser1'), $usr_id, 'Changed user login reported correctly');

    ok(($ua->set_descr($usr_id, 'Irregular luser 1') and 
	$ua->set_adm_level($usr_id, 1)),
       "Successfully changed other of this user's details");

    diag('Next test will issue a warning - Disregard.');
    ok(!($ua->set_login($adm_id, 'adm2')),
       'System successfully prevents me from having duplicate logins');

    # Remove a user, should be gone.
    ok($ua->remove_user($usr_id), 'Removed a user');
    ok(!($ua->id('luser1')), 'Could not query for the removed user - Good.');

    ###
    ### Now, the User::Simple tests
    ###
    ok($usr = User::Simple->new(db=>$db, tbl=>'user_simple'),
       'Created a new instance of a User::Simple object');

    # Log in with user/password as user4 - As the password is blank, it should
    # be marked as disabled
    ok(!($usr->ck_login('user4','')),
       'Blank password is successfully disabled');

    # Log in with user/password, retrieve the user's data
    ok($usr->ck_login('user5','a_password'),
       'Successfully logged in with one of the users');
    is($usr->login, 'user5', 'Reported login matches');
    is($usr->descr, 'Regular user 5', 'Reported descr matches');
    is($usr->adm_level, 0, 'Reported adm_level matches');

    # Verify we can change the changeable fields and that we cannot change 
    # restricted ones.
    ok($usr->set_descr('A new description'), "Able to change a user's descr");
    is($usr->descr, 'A new description', 'descr changed successfully');

    eval { $usr->set_login('please_kill_me') };
    ok($!, 'Prevented a login change');
    is($usr->login, 'user5', 'Previous login still there');

    eval { $usr->set_adm_level(5) };
    ok($!, 'Prevented an adm_level change');
    is($usr->adm_level, 0, 'Previous adm_level still there');

    # Get the user's session
    ok($session = $usr->session, "Retreived the user's session");
    
    # Try to log in with an invalid session, check that all of the data is
    # cleared.
    is($usr->ck_session('blah'), undef,
       'Checked for a wrong session, successfully got refused');
    is($usr->id, undef, "Nobody's ID successfully reports nothing");
    is($usr->login, undef, "Nobody's login successfully reports nothing");
    is($usr->descr, undef, "Nobody's descr successfully reports nothing");
    is($usr->adm_level, undef, 
       "Nobody's adm_level successfully reports nothing");

    # Now log in using the session we just retreived - We should get the 
    # full data again.
    ok($usr->ck_session($session), 'Successfully checked for a real session');
    is($usr->login, 'user5', 'Reported login matches');
    is($usr->descr, 'A new description', 'Reported descr matches');
    is($usr->adm_level, 0, 'Reported adm_level matches');
    
    # Ensure that logging in several times in a row produces different
    # session IDs (that is, that we are not vulnerable to time-based
    # predictability - see changelog for 1.42)
    %sessions = ();
    map { $usr->ck_login('user5', 'a_password');
	  $sessions{$usr->session} = $_} (1..10);
    is(scalar(keys %sessions), 10,
       'Discrepancy in the number of generated sessions - possible clash?')
    

}
unlink($tmp_file)
