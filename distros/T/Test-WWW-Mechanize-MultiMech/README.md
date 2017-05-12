# NAME

Test::WWW::Mechanize::MultiMech - coordinate multi-object mech tests for multi-user web app testing

# SYNOPSIS

    use strict;
    use warnings;
    use lib qw(lib ../lib);
    use Test::WWW::Mechanize::MultiMech;

    my $mech = Test::WWW::Mechanize::MultiMech->new(
        users   => [
            admin       => { pass => 'adminpass', },
            super       => { pass => 'superpass', },
            clerk       => { pass => 'clerkpass', },
            shipper     => {
                login => 'shipper@system.com',
                pass => 'shipperpass',
            },
        ],
    );

    # optional shortcut method to login all users
    $mech->login(
        login_page => 'http://myapp.com/',
        form_id => 'login_form',
        fields => {
            login => \'LOGIN',
            pass  => \'PASS',
        },
    );

    $mech         ->text_contains('MyApp.com User Interface');  # all users
    $mech->admin  ->text_contains('Administrator Panel');       # only admin
    $mech->shipper->text_lacks('We should not tell shippers about the cake');

    $mech         ->add_user('guest');     # add another user
    $mech         ->get_ok('/user-info');  # get page with each user
    $mech->guest  ->text_contains('You must be logged in to view this page');
    $mech         ->remove_user('guest');  # now, get rid of the guest user

    $mech         ->text_contains('Your user information'  );  # all users
    $mech->admin  ->text_contains('You are an admin user!' );  # admin user only
    $mech->super  ->text_contains('You are a super user!'  );  # super user only
    $mech->clerk  ->text_contains('You are a clerk user!'  );  # clerk user only

    # nothing stops you from using variables as method calls
    $mech->$_->get_ok('/foobar')
        for qw/admin shipper/;

    # call ->res once on "any one" mech object
    print $mech->any->res->decoded_content;

    # call ->uri method on every object and inspect value returned for admin user
    print $mech->uri->{admin}->query;

    # call ->uri method on every object and inspect value returned for 'any one' user
    print $mech->uri->{any}->query;

    # ignore user 'super' when making all-user method calls
    $mech->ignore('super');
    $mech->get_ok('/not-super'); # this was not called for user 'super'
    $mech->unignore('super');

# DESCRIPTION

Ofttimes I had to test a web app where I had several user permission
categories and I needed to ensure that, for example, only admins get
the admin panel, etc. This module allows you to instantiate several
[Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) objects and then easily call methods
on all of them (using one line of code) or individually, to test for
differences between them that should be there.

# ORDERING/SIMULTANEITY NOTES

Note that this module does not fork out or do any other business to
make all the mech objects execute their methods __simultaneously__. The
methods that are called to be executed on all mech objects will be called
in the order that you specify the `users` to the `->new` method.
Which user you get when using `any`, either as a method or the key
in return value hashref, is not specified; it is what it says on the tin,
"any" user.

# GENERAL IDEA BEHIND THE INTERFACE OF THIS MODULE

The general idea is that you define aliases for each of your mech
objects in the bunch inside the `->new` method. Then, you can call
your usual [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) methods on your
`Test::WWW::Mechanize::MultiMech` object and they will be called
__on each__ mech object in a bundle. And, you can use the aliases you
specified to call [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) methods on specific objects
in the bundle.

The return value for all-object method calls will be hashrefs, where keys
are the user aliases and values are the return values of the method call
for each user. E.g.:

    $mech->get_ok('http://foo.com/bar');
    $mech->text_contains('Foo');
    print $mech->uri->{user_alias}->query;

If you make a call `$mech->USER_ALIAS->method` that method
will be called __only__ for the user whose alias is `USER_ALIAS`, e.g.

    # check that "admin" users have Admin panel
    $mech->admin->text_contains('Admin panel');

There's a special user called "`any`". It exists to allow you to create
tests without reliance on any specific user alias. You can think of it
as picking any user's return value or picking any user's mech object
and sticking with it. E.g.:

    $mech->get_ok('http://foo.com/bar');
    $mech->any->uri->query;  # one call to ->uri using any user's mech object
    # or
    # call ->uri on every mech object and get the result of any one of them
    $mech->uri->{any}->query;

__Note:__ if you `->ignore()` a user, they won't be considered
as a candidate for `$mech->any` and they won't be as a key in the
return value of all-user method calls.

# METHODS

## `new`

    my $mech = Test::WWW::Mechanize::MultiMech->new(
        users   => [
            user        => { },
            admin       => { pass => 'adminpass',   },
            super       => { pass => 'superpass',   },
            clerk       => { pass => 'clerkpass',   },
            shipper     => {
                login => 'shipper@system.com',
                pass => 'shipperpass',
            },
        ],
    );

You __must__ specify at least one user using the `users` key, whose
value is an arrayref of users. Everything else will be __passed__ to
the `->new` method of [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize). The users arrayref
is specified as a list of key/value pairs, where keys are user aliases
and values are, possibly empty, hashrefs of parameters. The aliases will be
used as method calls to call methods on mech object of individual
users (see ["GENERAL IDEA BEHIND THE INTERFACE OF THIS MODULE"](#general-idea-behind-the-interface-of-this-module)
section above), so ensure your user aliases do not conflict with mech
calls and other things (e.g. you can't have a user alias named
`get_ok`, as calling `$mech->get_ok('foo');` would call
the `->get_ok` [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize) method on each of your users).
Currently valid keys in the hashref value are:

### `pass`

    my $mech = Test::WWW::Mechanize::MultiMech->new(
        users   => [
            admin => { pass => 'adminpass', },
        ],
    );

__Optional__. Specifies user's password, which is currently only used in the
`->login()` method. __By default__ is not specified.

### `login`

    my $mech = Test::WWW::Mechanize::MultiMech->new(
        users   => [
            admin => { login => 'joe@example.com' },
        ],
    );

__Optional__. Specifies user's login (user name), which is currently only used in the `->login()` method. __If not specified__, the alias
for this user will be used as login instead (e.g. `admin` would be
used in the example code above, instead of `joe@example.com`).

## `login`

    $mech->login(
        login_page => 'http://myapp.com/',
        form_id => 'login_form',
        fields => {
            login => \'LOGIN',
            pass  => \'PASS',
        },
    );

This is a convenience method designed for logging in each user,
and you don't have to use it.
It's a shortcut for accessing page `login_page` and then calling
`->submit_form_ok()` for each user, with login/password set
individually.

Takes arguments as key/value pairs. Value of key `login_page`
__specifies__ the URL of the login page. __If omitted__, current page
of each mech object will be used.

All other arguments will be forwarded to the `->submit_form_ok()`
method of [Test::WWW::Mechanize](https://metacpan.org/pod/Test::WWW::Mechanize).

The `fields` argument, if specified, can contain any field name
whose value is `\'LOGIN'` or `\'PASS'` (note the reference
operator `\`). If such fields are specified, their values will be
substituted with the login/password of each user individually.

## `add_user`

    $mech->add_user('guest');

    $mech->add_user( guest => {
            pass  => 'guestpass',
            login => 'guestuser',
        }
    );

Adds new mech object to the bundle. This can be useful when you
want to do a quick test on a page with an unprivileged user, whom
you dump with a `->remove_user` method.
__Takes__ a user alias, optionally followed by user args hashref.
See `->new()` method for possible keys/values in the user args
hashref. Calling with a user alias alone is equivalent to calling with
an empty user args hashref.

If a user under the given user alias already exists, their user args
hashref will be overwritten. The user alias added with `->add_user`
method will be added to the end of the sequence for all-user method calls
(even if the user already existed, they will be moved to the end).

__Keep in mind__ that the mech object given to this user is brand new.
So you need to use absolute URLs when making the next call to,
say `->get_ok`, methods on this user (or with the next
all-users method).

## `remove_user`

    my $user_args = $mech->remove_user('guest');

__Takes__ a valid user alias.
Removes user with that alias from the MultiMech mech object bundle. If
removing an existing user, that user's user args hashref will be returned,
otherwise the return value is an empty list or `undef`, depending on the
context. The `mech` key in the returned hashref will contain the mech
object that was being used for that user.

Note that you can't delete all the users you have. If attempting to
delete the last remaining user, the module will
[croak()](https://metacpan.org/pod/Carp).

## `all_users`

    for ( $mech->all_users ) {
        print "I'm testing user $_\n";
    }

    # printing all users, even ignored ones
    for ( $mech->all_users(1) ) {
        print "I'm testing user $_\n";
    }

Returns a list of user aliases currently used by
MultiMech, in the same order in which they are called in
all-object method calls. Takes one optional true/value argument that
specifies whether to include ignored users (see `->ignore_user()`
method below). If set to a true value, ignored users will be included.

## `ignore_user`

    $mech->ignore_user('user1');

    # This will NOT be called on user 'user1':
    $mech->get_ok('/foo');

Makes the MultiMech ignore a particular user when making all-user
method calls. Ignored users won't be considered when using
`$mech->any` calls, and won't be present in the return value
hashref of all-user method calls.

Takes one argument, which is the alias of a user to ignore.
Ignoring an already-ignored user is perfectly fine and has no ill effects.
The method does not return anything meaningful.

You can NOT ignore all of your users; at least one user must be
unignored at all times. The module will
[croak()](https://metacpan.org/pod/Carp) if you attempt to ignore
the last available user.

__NOTE:__ ignored users are simply excluded from the all-user method calls.
It is still perfectly valid to call single-user method calls on
ignored users (e.g. `$mech->ignoreduser->get_ok('/foo')`)

## `unignore_user`

    # This will NOT be called on ignored user 'user1':
    $mech->get_ok('/foo');
    $mech->unignore_user('user1');

    # User 'user1' is now back in; this method will be called for him now
    $mech->get_ok('/foo');

Undoes what `->ignore_user()` does (removes an ignored user
from the ignore list). Takes one argument, which is the alias of a user
to unignore. Unignoring a non-ignored user is fine and has no ill effects.
Does not return any meaningful value.

# CAVEATS

What sucks about this module is the output is rather ugly and too
verbose. I'm open to suggestions on how to make it better looking, while
retaining information on which 'user' is doing what.

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Test-WWW-Mechanize-MultiMech](https://github.com/zoffixznet/Test-WWW-Mechanize-MultiMech)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Test-WWW-Mechanize-MultiMech/issues](https://github.com/zoffixznet/Test-WWW-Mechanize-MultiMech/issues)

If you can't access GitHub, you can email your request
to `bug-Test-WWW-Mechanize-MultiMech at rt.cpan.org`

# AUTHOR

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
