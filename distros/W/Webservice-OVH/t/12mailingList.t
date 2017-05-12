use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ( $json_dir && -e $json_dir ) { plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

=head2

    You need to choose an email domain with an additional email package wich allows mailing lists
    This test can take up to 5 minutes to complete, because ovh need up to 5 minutes to delete a mailing list

=cut

my $api = Webservice::OVH->new_from_json($json_dir);
ok( $api, "module ok" );

my $email_domain = $api->email->domain->domains->[0];

SKIP: {

    skip "No email domain found in connected account", 1 if !$email_domain;

    ok( $email_domain, 'email_domain ok' );

    my $new_mailing_list;
    eval { $new_mailing_list = $email_domain->new_mailing_list( language => 'de', name => 'testlist', options => { moderator_message => 'false', subscribe_by_moderator => 'false', users_post_only => 'false' }, owner_email => 'test@t.com' ); };
  SKIP: {

        skip "Maximum mailinglist quota reached for connected account", 1 if !$new_mailing_list;

        ok( $new_mailing_list, 'new mailing list ok' );

        ok( $new_mailing_list->name,   'name ok' );
        ok( $new_mailing_list->id,     'id ok' );
        ok( $new_mailing_list->domain, 'domain ok' );
        ok( $new_mailing_list->properties && ref $new_mailing_list->properties eq 'HASH', 'properties ok' );
        ok( $new_mailing_list->language, 'language ok' );
        ok( $new_mailing_list->options && ref $new_mailing_list->options eq 'HASH', 'options ok' );
        ok( $new_mailing_list->owner_email, 'owner_email ok' );
        ok( $new_mailing_list->reply_to,    'reply_to ok' );
        ok( $new_mailing_list->nb_subscribers_update_date && ref $new_mailing_list->nb_subscribers_update_date eq 'DateTime', 'nb_subscribers_update_date ok' );
        ok( $new_mailing_list->nb_subscribers >= 0, 'nb_subscribers ok' );

        while ($@) {

            eval { $new_mailing_list->change( language => 'en', reply_to => 'test@test.com', owner_email => 'test2@t.com' ); };
            warn $@ if $@;
            sleep(10);
        }

        ok( $new_mailing_list->reply_to eq 'test@test.com',     'change reply_to ok' );
        ok( $new_mailing_list->language eq 'en',                'change language ok' );
        ok( $new_mailing_list->owner_email eq 'test2@test.com', 'change owner_email ok' );

        $new_mailing_list->add_moderator('test3@t.com');

        my $moderators_n = $new_mailing_list->moderators;
        my @found_n      = grep { $_ eq 'test3@t.com' } @$moderators_n;
        my $moderator_n  = $new_mailing_list->moderator('test3@t.com');

        ok( $moderators_n && ref $moderators_n eq 'ARRAY', 'moderator list ok' );
        ok( scalar @found_n > 0, 'moderator ok' );
        ok( $moderator_n,        'moderator found ok' );

        $new_mailing_list->delete_moderator('test3@t.com');

        my $moderators_c = $new_mailing_list->moderators;
        my @found_c      = grep { $_ eq 'test3@t.com' } @$moderators_c;
        my $moderator_c  = $new_mailing_list->moderator('test3@t.com');

        ok( $moderators_c && ref $moderators_c eq 'ARRAY', 'moderator list ok' );
        ok( scalar @found_c == 0, 'not moderator ok' );
        ok( !$moderator_c,        'no moderator found ok' );

        $new_mailing_list->change_options( moderatorMessage => 'true', subscribeByModerator => 'false', usersPostOnly => 'true' );

        my $options = $new_mailing_list->options;

        ok( $options->moderatorMessage eq 'true',      'moderatorMessage ok' );
        ok( $options->subscribeByModerator eq 'false', 'subscribeByModerator ok' );
        ok( $options->usersPostOnly eq 'true',         'usersPostOnly ok' );

        $new_mailing_list->add_subscriber('test12@t.de');

        my $subscribers = $new_mailing_list->subscribers;
        my @sub         = grep { $_ eq 'test12@t.com' } @$subscribers;
        my $subscriber  = $new_mailing_list->moderator('test12@t.com');

        ok( $subscribers && ref $subscribers eq 'ARRAY', 'subscribers list ok' );
        ok( scalar @sub > 0, 'subscriber ok' );
        ok( $subscriber,     'subscriber found ok' );

        $new_mailing_list->delete_subscriber('test12@t.de');

        my $subscribers_n = $new_mailing_list->subscribers;
        my @sub_n         = grep { $_ eq 'test12@t.com' } @$subscribers;
        my $subscriber_n  = $new_mailing_list->moderator('test12@t.com');

        ok( $subscribers_n && ref $subscribers_n eq 'ARRAY', 'subscribers list ok' );
        ok( scalar @sub_n == 0, 'not subscriber ok' );
        ok( !$subscriber,       'no subscriber found ok' );

        while ( $new_mailing_list->is_valid ) {

            eval { $new_mailing_list->delete; };
            warn $@ if $@;
            sleep(10);
        }

    }

}

done_testing();
