use strict;
use warnings;
use WWW::Plurk;
use Test::More;
use Test::Deep;

if ( my $plurk_env = $ENV{PLURK_TEST_ACCOUNT} ) {
    plan tests => 11;
    my ( $user, $pass ) = split /:/, $plurk_env, 2;

    my $plurk = WWW::Plurk->new;
    eval { $plurk->login( $user, $pass ) };
    ok !$@, "login: no error" or diag "$@";

    # use Data::Dumper;
    # diag Dumper( $plurk );

    is $plurk->nick_name, $user, "nick name";

    my @friends = eval { $plurk->friends };
    ok !$@, "friends: no error" or diag "$@";
    cmp_deeply [@friends],
      array_each(
        all( isa( 'WWW::Plurk::Friend' ), methods( plurk => $plurk ) )
      ),
      "friends";

    my @plurks = eval { $plurk->plurks };
    ok !$@, "messages: no error" or diag "$@";
    cmp_deeply [@plurks],
      array_each(
        all( isa( 'WWW::Plurk::Message' ), methods( plurk => $plurk ) )
      ),
      "messages";

    if ( @plurks ) {
        my $message = $plurks[0];
        {
            my @responses = eval { $message->responses };
            ok !$@, "responses: no error" or diag "$@";
            cmp_deeply [@responses],
              array_each(
                all(
                    isa( 'WWW::Plurk::Message' ),
                    methods( plurk => $plurk )
                )
              ),
              "responses";
        }
        {
            my $link = $message->permalink;
            ok can_fetch( $plurk->_ua, $link );
        };
    }
    else {
        pass "no responses" for 1 .. 2;
    }

    my @unread = eval { $plurk->unread_plurks };
    ok !$@, "unread: no error" or diag "$@";
    cmp_deeply [@unread],
      array_each(
        all( isa( 'WWW::Plurk::Message' ), methods( plurk => $plurk ) )
      ),
      "unread";
}
else {
    plan skip_all =>
      'Set $ENV{PLURK_TEST_ACCOUNT} to "user:pass" to run these tests';
}

sub can_fetch {
    my ( $ua, $uri ) = @_;
    my $resp = $ua->get( $uri );
    return $resp->is_success;
}
