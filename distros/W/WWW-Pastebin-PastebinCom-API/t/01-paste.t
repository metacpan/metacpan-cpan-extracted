#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib qw{../lib  lib};
use Test::More;

use WWW::Pastebin::PastebinCom::API;

plan tests => 22;

my $API_KEY = 'a3767061e0e64fef6c266126f7e588f3';
my $USER    = 'perlpaster';
my $PASS    = 'perlpaster';

my $bin = create_and_test_object();
test_get_paste( $bin );
my $created_paste_url = test_creation_of_new_paste( $bin );
test_get_user_info( $bin );
test_list_trendy_pastes( $bin );
SKIP: {
    defined $created_paste_url
        or skip
            "We don't have a freshly created paste to test this one",
            7;
    test_list_user_pastes( $bin, $created_paste_url );
    test_delete_paste_and_error_method( $bin, $created_paste_url );
}

sub test_get_user_info {
    diag("Testing get_user_info");
    SKIP: {
        my $bin = shift;
        my $info = $bin->get_user_info
            or skip "Got an error while getting user info: $bin", 2;

        is( ref $info, 'HASH', 'Is info ref a hash?' );
        my $all_hashrefs_have_proper_keys = 1;
        for my $key ( qw/ name  website  location  format_short
            avatar_url  email  expiration  account_type
        /) {
            $all_hashrefs_have_proper_keys = 0
                unless exists $info->{ $key }
        }
        ok( $all_hashrefs_have_proper_keys == 1,
                'Have all proper keys' );
    }
}

sub test_delete_paste_and_error_method {
    diag("Testing delete_paste and error methods");
    SKIP: {
    my $bin = shift;
    my $created_paste_url = shift;

    $bin->delete_paste( $created_paste_url )
        or skip "Got an error while deleting a paste: $bin", 3;

    my $paste = $bin->get_paste( $created_paste_url, $USER, $PASS );
    is( $paste, undef, 'Was our paste deleted?' );
    is( $bin->error, q|This paste doesn't exist|, 'Is error message OK?' );
    is( "$bin", 'Error: ' . $bin->error,
            q|Does interpolation work for the error?| );
    }
}

sub test_list_trendy_pastes {
    diag("Testing trendy pastes");
    SKIP: {
    my $bin = shift;

    my $list = $bin->list_trends
        or skip "Error while getting trendy paste list: $bin", 3;

    ok( scalar(@$list), 'Got some trendy pastes' );
    my (
        $all_items_are_hashrefs,
        $all_hashrefs_have_proper_keys,
    ) = (1, 1);

    for ( @$list ) {
        if ( ref eq 'HASH' ) {
            for my $key ( qw/key  url  title  date  expire_date
                size  hits/
            ) {
                $all_hashrefs_have_proper_keys = 0
                    unless exists $_->{ $key }
            }
        }
        else {
            $all_items_are_hashrefs = 0;
        }
    }
    ok( $all_items_are_hashrefs == 1,
            'All items in trendy paste list were hashrefs');
    ok( $all_hashrefs_have_proper_keys == 1,
            'All hashrefs have proper keys' );
    }
}

sub test_list_user_pastes {
    diag("Testing listing of user pastes");
    SKIP: {
    my $bin = shift;
    my $created_paste_url = shift;

    my $list = $bin->list_user_pastes
        or skip "Error while getting user paste list: $bin", 4;

    ok( scalar(@$list), 'Got some user pastes' );
    my (
        $found_the_paste_we_created,
        $all_items_are_hashrefs,
        $all_hashrefs_have_proper_keys,
    ) = (0, 1, 1);
    for ( @$list ) {
        if ( ref eq 'HASH' ) {
            $found_the_paste_we_created = 1
                if $_->{url} eq $created_paste_url;

            for my $key ( qw/key  url  title  date  expire_date
                format_short format_long  size  hits/
            ) {
                $all_hashrefs_have_proper_keys = 0
                    unless exists $_->{ $key }
            }
        }
        else {
            $all_items_are_hashrefs = 0;
        }
    }
    ok( $found_the_paste_we_created == 1, 'Found the paste we created' );
    ok( $all_items_are_hashrefs == 1,
            'All items in paste list were hashrefs');
    ok( $all_hashrefs_have_proper_keys == 1,
            'All hashrefs have proper keys' );
    }
}

sub test_get_paste {
    diag("Testing getting pastes");
    SKIP: {
    my $bin = shift;

    my $paste = $bin->get_paste('http://pastebin.com/fBBUJvde')
        or skip "Failed to get paste: $bin", 2;
    my $paste2 = $bin->get_paste('fBBUJvde')
        or skip "Failed to get paste: $bin", 2;

    is( $paste, q|My name is Zoffix and this paste will be used to |
                    . q|test my super awesome implementation of the |
                    . q|Pastebin.com API :)|,
        'Is paste content correct when asking using URL?' );
    is( $paste2, q|My name is Zoffix and this paste will be used to |
                    . q|test my super awesome implementation of the |
                    . q|Pastebin.com API :)|,
        'Is paste content correct when asking using ID?' );
    }
}

sub test_creation_of_new_paste {
    diag("Testing creation of new pastes");
    SKIP: {
    my $bin = shift;

    # Use some non-spam-looking data as test paste text
    my $test_paste = qq|Test for Perl implementation of the API\n|
    . join "\n", map join(qq|$_ => $ENV{$_}|), keys %ENV;

    my $user_key = $bin->get_user_key(qw/
        perlpaster
        perlpaster
    /) or skip "Failed to get user key: $bin", 6;

    like(
        $user_key, qr{^\w+$}, 'Does user key look like a user key?',
    );

    is(
        $user_key, $bin->user_key,
        'get_user_key returns same as user_key'
    );

    my $paste_link = $bin->paste(
        $test_paste,
        private     => 1,
        expiry      => 'asap',
        format      => 'perl',
    ) or skip "Failed to create the paste: $bin", 4;

    like(
        $paste_link, qr{^http://pastebin.com/\w+$},
        'Does paste return what looks like paste ID?'
    );

    is ( $paste_link, "$bin", 'Interpolation of object' );
    is ( $bin->paste_url, "$bin", 'Interpolation of object 2' );

    my $pasted_text = $bin->get_paste( $bin->paste_url, $USER, $PASS )
        or skip "Failed to get a paste: $bin", 1;
    like( $pasted_text, qr{^Test for Perl implementation of the API} );

    return $bin->paste_url;
    }
}

sub create_and_test_object {
    diag("Testing object creation");
    my $bin = WWW::Pastebin::PastebinCom::API->new(
        api_key => $API_KEY,
        timeout => 5,
    );

    isa_ok( $bin, 'WWW::Pastebin::PastebinCom::API' );
    can_ok( $bin, qw/
        error
        api_key
        user_key
        paste_url
        get_paste
        get_user_key
        paste
        delete_paste
        list_user_pastes
        list_trends
    /);

    return $bin;
}


