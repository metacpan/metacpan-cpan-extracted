use strict;
use warnings;
use Test::More;
use WWW::Mailman;

my %config;

$WWW::Mailman::VERSION ||= 'undefined';

# pickup the configuration information
# from files
if ( my @credentials = <mailman_credentials*> ) {
    for my $file (@credentials) {
        open my $fh, $file or die "Can't open $file: $!";
        /^(\w+):\s*(\S*)/ && ( $config{$file}{$1} = $2 ) while <$fh>;
        close $fh;
    }
}

# from environment
for my $key (qw( uri email password admin_password moderator_password )) {
    my $env_key = uc "mailman_$key";
    $config{'MAILMAN ENV'}{$key} = $ENV{$env_key}
        if exists $ENV{$env_key};
}

# check we have enough information for testing
for my $list ( keys %config ) {

    # drop lists without a uri
    if ( !exists $config{$list}{uri} ) {
        diag "$list needs at least the uri parameter for live tests";
        delete $config{$list};
    }

    # drop lists we can't connect to
    if ( !WWW::Mechanize->new( autocheck => 0 )->get( $config{$list}{uri} )
        ->is_success() )
    {
        diag "Need web access to $list for live tests";
        delete $config{$list};
    }
}

# we can't do live tests without some information
if ( !keys %config ) {
    diag << 'INFO';
To run these (hopefully) non-destructive tests against a Mailman account:
either create one or more files matching mailman_credentials* per list,
with the following keys:
- uri
- email
- password
- admin_password
- moderator_password

The syntax being simply:
key: value

or create environment variables to test list from the environment:
- MAILMAN_URI
- MAILMAN_EMAIL
- MAILMAN_PASSWORD
- MAILMAN_ADMIN_PASSWORD
- MAILMAN_MODERATOR_PASSWORD
INFO
    plan skip_all => 'No credentials available for live tests';
}

# it is also possible to add some extra keys prefixed by test_
# to the mailman_credentials* files, to further influence testing
# this is not documented further, read the test code!

# we can do live tests!
plan tests => my $tests * keys %config;

my %option;
my @option_keys;
my %admin;

for my $list ( keys %config ) {
    %option = %{ $config{$list} };

    diag "testing $list";

    # this is pure lazyness
    sub mm {
        my $count = shift;
        exists $option{$_} || skip "Need '$_' for this test", $count for @_;
        WWW::Mailman->new( map { $_ => $option{$_} } 'uri', @_ );
    }

    # some useful variables
    my ( $mm, $url, $got, $expected, $conceal, @subs );

    # get the version
    $mm = mm();
    like( $mm->version, qr/^\d+\.\d+\.\d+\w*$/, "Version looks fine" );
    diag "Mailman version " . $mm->version;
    BEGIN { $tests += 1 }

    # options() fails with no email
    $mm = mm();
    $url = $mm->_uri_for('options');
    ok( !eval { $mm->options() }, 'options() fails with no credentials' );
    like( $@, qr/Couldn't login on \Q$url\E/, 'Expected error message' );
    BEGIN { $tests += 2 }

    # options() fails with no password
    $mm = mm();
    $mm->email('user@example.com');
    $url = $mm->_uri_for( 'options', $mm->email );
    ok( !eval { $mm->options() }, 'options() fails with no password' );
    like( $@, qr/Couldn't login on \Q$url\E/, 'Expected error message' );
    BEGIN { $tests += 2 }

    # options() for our user
SKIP: {
        $mm = mm( 2 + @option_keys, qw( email password ) );
        ok( eval { $got = $mm->options() }, 'options() with credentials' );
        diag $@ if $@;
        is( ref $got, 'HASH', 'options returned as a HASH ref' );
        ok( exists $got->{$_}, "options have key '$_'" ) for @option_keys;

        BEGIN {
            @option_keys = qw( fullname disablemail remind nodupes conceal );
            $tests += @option_keys + 2;
        }
    }

    # try changing an option
SKIP: {
        BEGIN { $tests += 5 }
        $mm = mm( 5, qw( email password ) );
        ok( eval { $got = $mm->options() }, 'options()' );
        diag $@ if $@;
        my $new = ( my $old = $got->{conceal} ) ? '0' : '1';
        ok( eval { $got = $mm->options( { conceal => $new } ) },
            "options( { conceal => $new } ) passes" );
        diag $@ if $@;
        is( $got->{conceal}, $new, "Changed the value of 'conceal' option" );
        ok( eval { $got = $mm->options( { conceal => $old } ) },
            "options( { conceal => $old } ) passes" );
        diag $@ if $@;
        is( $got->{conceal}, $old,
            "Changed back the value of 'conceal' option" );
        $conceal = $got->{conceal};
    }

    # check other subscriptions
SKIP: {
        BEGIN { $tests += 2 }
        $mm = mm( 2, qw( email password ) );

        # test_othersubs: FAIL
        if ( defined $option{test_othersubs}
            && $option{test_othersubs} =~ /FAIL/i )
        {
            ok( !eval { @subs = $mm->othersubs(); 1 }, 'othersubs() fails' );
            like( $@, qr/^No clickable input with name othersubs /, 'Expected error message' );
        }

        # test_othersubs: not defined or some number
        else {
            ok( eval { @subs = $mm->othersubs(); 1 }, 'othersubs()' );
            diag $@ if $@;
            my $subs
                = defined $option{test_othersubs}
                ? $option{test_othersubs}
                : 1;
            cmp_ok( scalar @subs, '>=', $subs, "At least $subs subscription" );
        }
    }

    # check email resend
SKIP: {
        BEGIN { $tests += 1 }
        $mm = mm( 1, qw( email ) );
        diag "You may receive password reminders for @{[$mm->list]}. Sorry.";
        ok( eval { $mm->emailpw(); 1 }, 'emailpw() without password' );
        diag $@ if $@;
    }

SKIP: {
        BEGIN { $tests += 1 }
        $mm = mm( 1, qw( email password ) );
        ok( eval { $mm->emailpw(); 1 }, 'emailpw()' );
        diag $@ if $@;
    }

SKIP: {
        BEGIN { $tests += 2 }
        $mm = mm( 2, qw( email password ) );
        ok( eval { $mm->options(); 1 }, 'login through options()' );
        diag $@ if $@;
        ok( eval { $mm->emailpw(); 1 }, 'emailpw() when logged in' );
        diag $@ if $@;
    }

    # check roster
    # (with some power user access, just in case access is restricted)
SKIP: {
        BEGIN { $tests += 2 }
        $mm = mm( 2, qw( email password moderator_password ) );
        skip "Can't test roster() if our email is concealed", 2
            if $conceal;
        my @emails;
        ok( eval { @emails = $mm->roster(); 1 }, 'roster()' );
        diag $@ if $@;
        ok( scalar( grep { $_ eq $option{email} } @emails ),
            'roster has at least our email' );
    }

SKIP: {
        BEGIN { $tests += 2 }
        $mm = mm( 2, qw( admin_password ) );
        my @emails;
        ok( eval { @emails = $mm->roster(); 1 }, 'roster()' );
        diag $@ if $@;
        ok( scalar( grep {/\@/} @emails ), 'roster has at least one email' );
    }

    # check some boolean admin options
SKIP: {
        BEGIN {
            %admin = (
                general => 'send_reminders',
                bounce  => 'bounce_processing',
            );
            $tests += 5 * keys %admin;
        }
        $mm = mm( 5 * keys %admin, qw( admin_password ) );
        for my $section ( keys %admin ) {
            my $method = "admin_$section";
            ok( eval { $got = $mm->$method() }, "admin_$section()" );
            my $new = ( my $old = $got->{ $admin{$section} } ) ? '0' : '1';
            ok( eval { $got = $mm->$method( { $admin{$section} => $new } ); },
                "$method( { $admin{$section} => $new } ) passes"
            );
            diag $@ if $@;
            is( $got->{ $admin{$section} },
                $new, "Changed the value of '$admin{$section}' option" );
            ok( eval { $got = $mm->$method( { $admin{$section} => $old } ); },
                "$method( { $admin{$section} => $old } ) passes"
            );
            diag $@ if $@;
            is( $got->{ $admin{$section} },
                $old, "Changed back the value of '$admin{$section}' option" );
        }
    }
}

