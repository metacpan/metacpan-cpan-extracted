package Test::WWW::Mechanize::MultiMech;

use 5.006;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.006001'; # VERSION

use Test::WWW::Mechanize;
use Test::Builder qw//;
use Carp qw/croak/;

sub _diag {
    Test::Builder->new->diag(@_);
}

sub new {
    my ( $class, %args ) = @_;

    ref $args{users} eq 'ARRAY'
        or croak 'You must give ``users\'\' to new->new(); '
                . 'and it needs to be an arrayref';

    my @args_users = @{ delete $args{users} };
    my ( %users, @users_order );
    for ( grep !($_%2), 0 .. $#args_users ) {
        my $user_args = $args_users[ $_+1 ];

        push @users_order, $args_users[ $_ ];

        my $mech = Test::WWW::Mechanize->new( %args );
        $users{ $args_users[$_] } = {
            login   => (
                defined $user_args->{login}
                ? $user_args->{login} : $args_users[ $_ ]
            ),
            pass    => $user_args->{pass},
            mech    => $mech,
        };
    }

    my $self = bless {}, $class;
    $self->{USERS}       = \%users;
    $self->{USERS_ORDER} = \@users_order;
    $self->{MECH_ARGS}   = \%args;
    return $self;
}

sub _mech {
    my $self = shift;
    my ( $any_user ) = grep !$self->{IGNORED_USERS}{$_},
        @{$self->{USERS_ORDER}};

    $any_user
        or croak q{Didn't find any available users when getting any}
            . q{ user's mech object.};

    return $self->{USERS}{ $any_user }{mech};
}

sub login {
    my ( $self, %args ) = @_;

    my $page = delete $args{login_page};
    eval {
        $page = $self->_mech->uri
            unless defined $page;
    };
    if ( $@ ) {
        croak 'You did not give ->login() a page and mech did not yet'
        . ' access any pages. Cannot proceed further';
    }

    my $users = $self->{USERS};
    for my $alias (
        grep !$self->{IGNORED_USERS}{$_}, @{$self->{USERS_ORDER}}
    ) {
        my $mech = $users->{ $alias }{mech};

        $mech->get_ok(
            $page,
            "[$alias] get_ok($page)",
        );

        my $user_args = { %args };
        if ( $user_args->{fields} ) {
            $user_args->{fields} = {%{ $user_args->{fields} }};
        }

        for ( values %{ $user_args->{fields} || {} } ) {
            next unless ref eq 'SCALAR';
            if ( $$_ eq 'LOGIN'   ) { $_ = $users->{ $alias }{login}; }
            elsif ( $$_ eq 'PASS' ) { $_ = $users->{ $alias }{pass};  }
        }

        $mech->submit_form_ok(
            $user_args,
            "[$alias] Submitting login form",
        );
    }
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    our $AUTOLOAD;
    my $method = (split /::/, $AUTOLOAD)[-1];
    return if $method eq 'DESTROY';

    if ( $self->_mech->can($method) ) {
        return $self->_call_mech_method_on_each_user( $method, \@args );
    }
    elsif ( grep $_ eq $method, @{ $self->{USERS_ORDER} } ) {
        my $alias = $method;
        _diag "[$alias]-only call";
        return $self->{USERS}{ $alias }{mech};
    }
    elsif ( $method eq 'any' ) {
        _diag "[any] call";
        return $self->_mech;
    }

    croak qq|Can't locate object method "$method" via package |
        . __PACKAGE__;
}

sub _call_mech_method_on_each_user {
    my ( $self, $method, $args ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %returns;
    for my $alias (
        grep !$self->{IGNORED_USERS}{$_}, @{$self->{USERS_ORDER}}
    ) {
        _diag("\n[$alias] Calling ->$method()\n");
        $returns{ $alias }
        = $self->{USERS}{ $alias }{mech}->$method( @$args );
    }

    $returns{any} = (values %returns)[0];
    return \%returns;
}

sub remove_user {
    my ( $self, $alias ) = @_;

    return unless exists $self->{USERS}{ $alias };

    @{ $self->{USERS_ORDER} }
    = grep $_ ne $alias, @{ $self->{USERS_ORDER}  };

    my $args = delete $self->{USERS}{ $alias };

    croak 'You must have at least one user and you '
        . 'just removed the last one'
        unless @{ $self->{USERS_ORDER}  };

    return ( $alias, $args );
}

sub add_user {
    my ( $self, $alias, $args ) = @_;

    my $mech = Test::WWW::Mechanize->new( %{ $self->{MECH_ARGS} } );

    $self->{USERS}{ $alias } = {
        %{ $args || {} },
        mech => $mech,
    };

    @{ $self->{USERS_ORDER} } = (
        ( grep $_ ne $alias, @{ $self->{USERS_ORDER} } ),
        $alias,
    );

    return;
}

sub all_users {
    my $self = shift;
    my $is_include_ignored = shift;
    return $is_include_ignored
        ? @{ $self->{USERS_ORDER} }
        : grep !$self->{IGNORED_USERS}{ $_ }, @{ $self->{USERS_ORDER} };
}

sub ignore_user {
    my ( $self, $alias ) = @_;

    return unless exists $self->{USERS}{ $alias };

    $self->{IGNORED_USERS}{ $alias } = 1;
    if ( keys %{$self->{IGNORED_USERS}} eq @{ $self->{USERS_ORDER} } ){
        croak q{You ignored all your users. Can't function without at least
            one active user};
    }
}

sub unignore_user {
    my ( $self, $alias ) = @_;

    delete $self->{IGNORED_USERS}{ $alias };
}

q|
Why programmers like UNIX: unzip, strip, touch, finger, grep, mount, fsck,
    more, yes, fsck, fsck, fsck, umount, sleep
|;
__END__

=encoding utf8

=for stopwords Ofttimes Unignoring admin admins app mech unignore unignored

=head1 NAME

Test::WWW::Mechanize::MultiMech - coordinate multi-object mech tests for multi-user web app testing

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Ofttimes I had to test a web app where I had several user permission
categories and I needed to ensure that, for example, only admins get
the admin panel, etc. This module allows you to instantiate several
L<Test::WWW::Mechanize> objects and then easily call methods
on all of them (using one line of code) or individually, to test for
differences between them that should be there.

=head1 ORDERING/SIMULTANEITY NOTES

Note that this module does not fork out or do any other business to
make all the mech objects execute their methods B<simultaneously>. The
methods that are called to be executed on all mech objects will be called
in the order that you specify the C<users> to the C<< ->new >> method.
Which user you get when using C<any>, either as a method or the key
in return value hashref, is not specified; it is what it says on the tin,
"any" user.

=head1 GENERAL IDEA BEHIND THE INTERFACE OF THIS MODULE

The general idea is that you define aliases for each of your mech
objects in the bunch inside the C<< ->new >> method. Then, you can call
your usual L<Test::WWW::Mechanize> methods on your
C<Test::WWW::Mechanize::MultiMech> object and they will be called
B<on each> mech object in a bundle. And, you can use the aliases you
specified to call L<Test::WWW::Mechanize> methods on specific objects
in the bundle.

The return value for all-object method calls will be hashrefs, where keys
are the user aliases and values are the return values of the method call
for each user. E.g.:

    $mech->get_ok('http://foo.com/bar');
    $mech->text_contains('Foo');
    print $mech->uri->{user_alias}->query;

If you make a call C<< $mech->USER_ALIAS->method >> that method
will be called B<only> for the user whose alias is C<USER_ALIAS>, e.g.

    # check that "admin" users have Admin panel
    $mech->admin->text_contains('Admin panel');

There's a special user called "C<any>". It exists to allow you to create
tests without reliance on any specific user alias. You can think of it
as picking any user's return value or picking any user's mech object
and sticking with it. E.g.:

    $mech->get_ok('http://foo.com/bar');
    $mech->any->uri->query;  # one call to ->uri using any user's mech object
    # or
    # call ->uri on every mech object and get the result of any one of them
    $mech->uri->{any}->query;

B<Note:> if you C<< ->ignore() >> a user, they won't be considered
as a candidate for C<< $mech->any >> and they won't be as a key in the
return value of all-user method calls.

=head1 METHODS

=head2 C<new>

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

You B<must> specify at least one user using the C<users> key, whose
value is an arrayref of users. Everything else will be B<passed> to
the C<< ->new >> method of L<Test::WWW::Mechanize>. The users arrayref
is specified as a list of key/value pairs, where keys are user aliases
and values are, possibly empty, hashrefs of parameters. The aliases will be
used as method calls to call methods on mech object of individual
users (see L<GENERAL IDEA BEHIND THE INTERFACE OF THIS MODULE>
section above), so ensure your user aliases do not conflict with mech
calls and other things (e.g. you can't have a user alias named
C<get_ok>, as calling C<< $mech->get_ok('foo'); >> would call
the C<< ->get_ok >> L<Test::WWW::Mechanize> method on each of your users).
Currently valid keys in the hashref value are:

=head3 C<pass>

    my $mech = Test::WWW::Mechanize::MultiMech->new(
        users   => [
            admin => { pass => 'adminpass', },
        ],
    );

B<Optional>. Specifies user's password, which is currently only used in the
C<< ->login() >> method. B<By default> is not specified.

=head3 C<login>

    my $mech = Test::WWW::Mechanize::MultiMech->new(
        users   => [
            admin => { login => 'joe@example.com' },
        ],
    );

B<Optional>. Specifies user's login (user name), which is currently only used in the C<< ->login() >> method. B<If not specified>, the alias
for this user will be used as login instead (e.g. C<admin> would be
used in the example code above, instead of C<joe@example.com>).

=head2 C<login>

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
It's a shortcut for accessing page C<login_page> and then calling
C<< ->submit_form_ok() >> for each user, with login/password set
individually.

Takes arguments as key/value pairs. Value of key C<login_page>
B<specifies> the URL of the login page. B<If omitted>, current page
of each mech object will be used.

All other arguments will be forwarded to the C<< ->submit_form_ok() >>
method of L<Test::WWW::Mechanize>.

The C<fields> argument, if specified, can contain any field name
whose value is C<\'LOGIN'> or C<\'PASS'> (note the reference
operator C<\>). If such fields are specified, their values will be
substituted with the login/password of each user individually.

=head2 C<add_user>

    $mech->add_user('guest');

    $mech->add_user( guest => {
            pass  => 'guestpass',
            login => 'guestuser',
        }
    );

Adds new mech object to the bundle. This can be useful when you
want to do a quick test on a page with an unprivileged user, whom
you dump with a C<< ->remove_user >> method.
B<Takes> a user alias, optionally followed by user args hashref.
See C<< ->new() >> method for possible keys/values in the user args
hashref. Calling with a user alias alone is equivalent to calling with
an empty user args hashref.

If a user under the given user alias already exists, their user args
hashref will be overwritten. The user alias added with C<< ->add_user >>
method will be added to the end of the sequence for all-user method calls
(even if the user already existed, they will be moved to the end).

B<Keep in mind> that the mech object given to this user is brand new.
So you need to use absolute URLs when making the next call to,
say C<< ->get_ok >>, methods on this user (or with the next
all-users method).

=head2 C<remove_user>

    my $user_args = $mech->remove_user('guest');

B<Takes> a valid user alias.
Removes user with that alias from the MultiMech mech object bundle. If
removing an existing user, that user's user args hashref will be returned,
otherwise the return value is an empty list or C<undef>, depending on the
context. The C<mech> key in the returned hashref will contain the mech
object that was being used for that user.

Note that you can't delete all the users you have. If attempting to
delete the last remaining user, the module will
L<croak()|https://metacpan.org/pod/Carp>.

=head2 C<all_users>

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
specifies whether to include ignored users (see C<< ->ignore_user() >>
method below). If set to a true value, ignored users will be included.

=head2 C<ignore_user>

    $mech->ignore_user('user1');

    # This will NOT be called on user 'user1':
    $mech->get_ok('/foo');

Makes the MultiMech ignore a particular user when making all-user
method calls. Ignored users won't be considered when using
C<< $mech->any >> calls, and won't be present in the return value
hashref of all-user method calls.

Takes one argument, which is the alias of a user to ignore.
Ignoring an already-ignored user is perfectly fine and has no ill effects.
The method does not return anything meaningful.

You can NOT ignore all of your users; at least one user must be
unignored at all times. The module will
L<croak()|https://metacpan.org/pod/Carp> if you attempt to ignore
the last available user.

B<NOTE:> ignored users are simply excluded from the all-user method calls.
It is still perfectly valid to call single-user method calls on
ignored users (e.g. C<< $mech->ignoreduser->get_ok('/foo') >>)

=head2 C<unignore_user>

    # This will NOT be called on ignored user 'user1':
    $mech->get_ok('/foo');
    $mech->unignore_user('user1');

    # User 'user1' is now back in; this method will be called for him now
    $mech->get_ok('/foo');

Undoes what C<< ->ignore_user() >> does (removes an ignored user
from the ignore list). Takes one argument, which is the alias of a user
to unignore. Unignoring a non-ignored user is fine and has no ill effects.
Does not return any meaningful value.

=head1 CAVEATS

What sucks about this module is the output is rather ugly and too
verbose. I'm open to suggestions on how to make it better looking, while
retaining information on which 'user' is doing what.

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Test-WWW-Mechanize-MultiMech>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Test-WWW-Mechanize-MultiMech/issues>

If you can't access GitHub, you can email your request
to C<bug-Test-WWW-Mechanize-MultiMech at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut