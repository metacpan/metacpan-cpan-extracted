#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use File::Temp;
use TryCatch;

use_ok('Text::Tradition::Directory');

my $fh = File::Temp->new();
my $file = $fh->filename;
$fh->close;
my $dsn = "dbi:SQLite:dbname=$file";

my $user_store = Text::Tradition::Directory->new('dsn' => $dsn,
                                                 'extra_args' => { 'create' => 1 } );

my $scope = $user_store->new_scope;

## passwords
my $shortpass = 'bloggs';
ok(!$user_store->validate_password($shortpass), '"bloggs" is too short for a password');
try {
	my $dud_user = $user_store->add_user({ username => 'joe',
										   password => $shortpass });
	ok( 0, "User with short password should not have been created" );
} catch ( Text::Tradition::Error $e ) {
	is( $e->message, "Invalid password - must be at least " 
		. $user_store->MIN_PASS_LEN . " characters long",
		"Attempt to add user with too-short password threw correct error" );
}

## create user
my $new_user = $user_store->add_user({ username => 'fred',
                                       password => 'bloggspass'});
isa_ok($new_user, 'Text::Tradition::User');
is($new_user->active, 1, 'New user created and active');
is($new_user->email, 'fred', 'Email value set to username');
ok(!$new_user->is_admin, 'New user is not an admin');

## find user
my $find_user = $user_store->find_user({ username => 'fred'});
isa_ok($find_user, 'Text::Tradition::User');
ok($find_user->check_password('bloggspass'), 'Stored & retrieved with correct password');

## modify user
my $changed_user = $user_store->modify_user({ username => 'fred',
                                              password => 'passbloggs' });
isa_ok($changed_user, 'Text::Tradition::User');
my $changed = $user_store->find_user({ username => 'fred'});
ok($changed->check_password('passbloggs'), 'Modified & retrieved with correct new password');

{
## deactivate user
## Sets all traditions to non-public, deactivates
    my $user = $user_store->add_user({ username => 'testactive',
                                       password => 'imanactiveuser' });
    ok($user->active, 'Deactivate test user starts active');

    my $d_user = $user_store->deactivate_user({ username => 'testactive' });
    is($d_user->active, 0, 'Deactivated user');
    is($user_store->find_user({ username => 'testactive' }), undef, 'Deactivated user not returned by find_user');

## TODO - add test where user has traditions to start with
}

{
## reactivate user
## reactivates user, does not mess with their traditions (as we don't know which were public to start with)

    my $user = $user_store->add_user({ username => 'testinactive',
                                       password => 'imaninactiveuser' });
    my $d_user = $user_store->deactivate_user({ username => 'testinactive' });
    ok(!$d_user->active, 'Deactivate test user starts active');   
    
    my $a_user = $user_store->reactivate_user({ username => 'testinactive' });
    is($a_user->active, 1, 'Re-activated user');
    ok($user_store->find_user({ username => 'testinactive' }), 'Re-activated user returned by find_user again');
}

{
## delete user (admin only?)
    my $user = $user_store->add_user({ username => 'testdelete',
                                       password => 'imgoingtobedeleted' });

    my $gone = $user_store->delete_user({ username => 'testdelete' });

    my $d_user = $user_store->find_user({ username => 'testdelete' });

    ok($gone && !$d_user, 'Deleted user completely from store');
}

{
## add_tradition
    use Text::Tradition;
    my $t = Text::Tradition->new( 
        'name'  => 'inline', 
        'input' => 'Tabular',
        'file'  => 't/data/simple.txt',
	);

    my $uuid = $user_store->save($t);
    my $user = $user_store->add_user({ username => 'testadd',
                                       password => 'testingtraditions' });
    $user->add_tradition($t);
    $user_store->update($user);

    is( scalar @{$user->traditions}, 1, 'Added one tradition');

    my @tlist = $user_store->traditionlist($user);
    is($tlist[0]->{name}, $t->name, 'Traditionlist returns same named user->tradition');
    is($tlist[0]->{id}, $uuid, 'Traditionlist returns actual tradition with same uuid we put in earlier');
    my $fetched_t = $user_store->tradition($tlist[0]->{id});
    is($fetched_t->user->id, $user->id, 'Traditionlist returns item belonging to this user');

    ## add a second, not owned by this user, we shouldn't return it from
    ## traditionslist
    my $t2 = Text::Tradition->new( 
        'name'  => 'inline', 
        'input' => 'Tabular',
        'file'  => 't/data/simple.txt',
	);
    $user_store->save($t2);
    my @tlist2 = $user_store->traditionlist($user);
    is(scalar @tlist2, 1, 'With 2 stored traditions, we only fetch one');
    my $fetched_t2 = $user_store->tradition($tlist[0]->{id});
    is($fetched_t2->user->id, $user->id, 'Traditionlist returns item belonging to this user');
    
    
}


## Fetch public traditions, not user traditions, when not fetching with a user
use Text::Tradition;
my $t = Text::Tradition->new( 
	'name'  => 'inline', 
	'input' => 'Tabular',
	'file'  => 't/data/simple.txt',
);

$user_store->save($t);
my $user = $user_store->add_user({ username => 'testpublic',
								   password => 'testingtraditions' });
$user->add_tradition($t);
$user_store->update($user);

## add a second, not owned by this user, we shouldn't return it from
## traditionslist
my $t2 = Text::Tradition->new( 
	'name'  => 'inline', 
	'input' => 'Tabular',
	'file'  => 't/data/simple.txt',
);
$t2->public(1);
my $uuid = $user_store->save($t2);

my @tlist = $user_store->traditionlist('public');
is(scalar @tlist, 1, 'Got one public tradition');
is($tlist[0]->{name}, $t2->name, 'Traditionlist returns same named user->tradition');
is($tlist[0]->{id}, $uuid, 'Traditionlist returns actual tradition with same uuid we put in earlier');
my $fetched_t = $user_store->tradition($tlist[0]->{id});
ok($fetched_t->public, 'Traditionlist returns public item');


{
## remove_tradition
    use Text::Tradition;
    my $t = Text::Tradition->new( 
        'name'  => 'inline', 
        'input' => 'Tabular',
        'file'  => 't/data/simple.txt',
	);

    my $uuid = $user_store->save($t);
    my $user = $user_store->add_user({ username => 'testremove',
                                       password => 'testingtraditions' });
    $user->add_tradition($t);
    $user_store->update($user);

    $user->remove_tradition($t);
    $user_store->update($user);
    my $changed_t = $user_store->tradition($uuid);

    is( scalar @{$user->traditions}, 0, 'Added and removed one tradition');
    ok(!$changed_t->has_user, 'Removed user from tradition');

    my @tlist = $user_store->traditionlist($user);
    is(scalar @tlist, 0, 'Traditionlist now empty');
}

{
    ## Add admin user
    my $admin = $user_store->add_user({
        username => 'adminuser',
        password => 'adminpassword',
        role     => 'admin' });

    ok($admin->is_admin, 'Got an admin user');

    ## test admins get all traditions
    use Text::Tradition;
    my $t = Text::Tradition->new( 
        'name'  => 'inline', 
        'input' => 'Tabular',
        'file'  => 't/data/simple.txt',
	);

    $user_store->save($t);

    my @tlist = $user_store->traditionlist(); ## all traditions
    my @admin_tlist = $user_store->traditionlist($admin);

    is(scalar @admin_tlist, scalar @tlist, 'Got all traditions for admin user');

}

{
    ## Add/find simple openid user with OpenIDish parameters:

    my $openid_user = $user_store->create_user({ 
        url => 'http://username.myopenid.com',
        email => 'username.myopenid.com',
    });
    ok($openid_user, 'Created user from OpenID params');

    my $get_openid_user = $user_store->find_user({
        url => 'http://username.myopenid.com',
        email => 'username.myopenid.com',
    });

    ok($openid_user == $get_openid_user, 'Found OpenID user again');
    is($get_openid_user->id, 'http://username.myopenid.com', 'Set id to unique url from openid');
    is($get_openid_user->email, 'username.myopenid.com', 'Kept original email value');
}

{
    ## Add/find openid user with email attribute:
    my $openid_user = $user_store->create_user({ 
        url => 'http://blahblah.com/foo/bar/baz/lotsofjunk',
        email => 'http://blahblah.com/foo/bar/baz/lotsofjunk',
        extensions => {
            'http://openid.net/srv/ax/1.0' => { 
                'value.email' => 'fredbloggs@blahblah.com',
                'type.email' => 'http://axschema.org/contact/email',
                'mode' => 'fetch_response',
            },
        },
    });
    ok($openid_user, 'Created user from OpenID params');

    my $get_openid_user = $user_store->find_user({
        url => 'http://blahblah.com/foo/bar/baz/lotsofjunk',
        email => 'http://blahblah.com/foo/bar/baz/lotsofjunk',
        extensions => {
            'http://openid.net/srv/ax/1.0' => { 
                'value.email' => 'fredbloggs@blahblah.com',
                'type.email' => 'http://axschema.org/contact/email',
                'mode' => 'fetch_response',
            },
        },
    });

    ok($openid_user == $get_openid_user, 'Found OpenID user again');
    is($get_openid_user->id, 'http://blahblah.com/foo/bar/baz/lotsofjunk', 'Set id to unique url from openid');
    is($get_openid_user->email, 'fredbloggs@blahblah.com', 'Set email value to email from extension');
}

{
	## Find the same openid user just by email
	my $search_user = $user_store->find_user({ email => 'fredbloggs@blahblah.com' });
	ok( $search_user, 'Found an OpenID user by email' );
    is( $search_user->id, 'http://blahblah.com/foo/bar/baz/lotsofjunk', 'User has correct URL ID' );
    is( $search_user->email, 'fredbloggs@blahblah.com', 'User has correct email' );
}