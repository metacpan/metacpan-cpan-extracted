#!perl
use warnings;
use strict;
use lib 'lib';
use WebService::Intercom;
use Data::Dumper;
use Test::Modern -internet;
use Try::Tiny;

unless (defined($ENV{'INTERCOM_APP_ID'}) && defined($ENV{'INTERCOM_API_KEY'})) {
    plan skip_all => 'Testing this module needs an API key and app id in INTERCOM_APP_ID and INTERCOM_APP_KEY';
}


$Data::Dumper::Sortkeys = 1;
my $obj = object_ok(
    sub {
        WebService::Intercom->new(app_id => $ENV{INTERCOM_APP_ID},
                                  api_key => $ENV{INTERCOM_API_KEY});
    },
    '$obj',
    isa => [qw(WebService::Intercom)],
    can => [qw( user_create_or_update 
                user_delete 
                tag_create_or_update 
                tag_items 
                tag_delete 
                note_create
                event_create
          )],
    clean => 1
);

my $test_email = 'test@test.com';

my $user = $obj->user_create_or_update(
    email => $test_email,
    user_id => 0,
    signed_up_at => time,
    name => 'test user',
    last_seen_ip => '127.0.0.5',
    last_seen_user_agent => 'perl/1.0',
    last_request_at => time,
    unsubscribed_from_emails => 0,
    update_last_request_at => 0,
    new_session => 1,
    custom_attributes => {
        'Favorite Color' => 'blue',
        'paid subscriber' => Types::Serialiser::true,
        'daily spend' => 999.222,
    }
);

ok(defined($user), "Result is defined for creating a user");

object_ok(
    sub {
        $user
    },
    '$user',
    isa => [qw(WebService::Intercom::User)],
    clean => 1
);



my $message = $obj->create_message(from => { email => $test_email, type => 'user'},
                                   body => 'test user initiated message');

ok(defined($message), "User initiated message is defined");

object_ok(
    sub {
        $message;
    },
    '$message',
    isa => [qw(WebService::Intercom::Message)],
    clean => 1
);

my $admins = $obj->get_admins();

ok(defined($admins), "Got defined admins results");

ok(scalar(@$admins) > 0, "More than once admin found");

object_ok(
    sub {
        $admins->[0];
    },
    '$admins->[0]',
    isa => [qw(WebService::Intercom::Admin)],
    clean => 1
);


$message = $obj->create_message(from => { type => 'admin', id => $admins->[0]->id},
                                to  => { email => $test_email, type => 'user'},
                                subject => 'test message subject',
                                body => 'test admin message',
                                message_type => 'email'
                            );

ok(defined($message), "Admin initiated message is defined");

object_ok(
    sub {
        $message;
    },
    '$message',
    isa => [qw(WebService::Intercom::Message)],
    clean => 1
);


$user = $obj->user_get(email => $test_email);
ok(defined($user), "Result is defined for retrieving a user");

try {
    $obj->user_get(email => $test_email . "-note-found");
}
catch {
    my $error = $_;
    if ($error->isa('WebService::Intercom::Exception')) {
        is($error->code, 'not_found', 'Got expected not found user result');
    } else {
        die("Unknown error type caught: " . ref($error));
    }
}
;

object_ok(
    sub {
        $user
    },
    '$user',
    isa => [qw(WebService::Intercom::User)],
    can => [qw( save
                delete
          )],

    clean => 1
);

my $tag = $obj->tag_create_or_update(name => "TestTag");

ok(defined($tag), "Result is defined for creating a tag");


object_ok(
    sub {
        $tag
    },
    '$tag',
    isa => [qw(WebService::Intercom::Tag)],
    can => [qw( save
                delete
          )],
    clean => 1
);




$user->name('Test #3');
$user = $obj->user_create_or_update($user);

ok(defined($user), "Result is defined for updating a user");


$user->name('Test #4');
$user = $user->save();

is($user->name, 'Test #4', 'Correct name returned after update');

my $second_tag = object_ok(
    sub {
        $user->tag(name => 'test tag #1');
    },
    '$second_tag',
    isa => [qw(WebService::Intercom::Tag)],
    can => [qw( save
                delete
          )],
    clean => 1
);

# Make sure we can handle getting the tag.
$user = $obj->user_get(email => $test_email);
ok(defined($user), "Result is defined for retrieving a user");

my $remove_tag = object_ok(
    sub {
        $user->untag(name => 'test tag #1');
    },
    '$remove_tag',
    isa => [qw(WebService::Intercom::Tag)],
    can => [qw( save
                delete
          )],
    clean => 1
);



$user = $obj->user_delete(user_id => $user->user_id);
ok(defined($user), "Result is defined for deleting a user");

# This should recreate the user.
$user = $user->save();
ok(defined($user), "User is reinstantiated");


$obj->note_create(email => $test_email,
                  body => "This is a test message");

$user = $obj->user_get(email => $test_email);
ok(defined($user), "Result is defined for retrieving a user");


$user->add_note(body => "This is a test message #2");


$obj->event_create(email => $test_email,
                   event_name => 'first-event');

$obj->event_create(email => $test_email,
                   event_name => 'second-event',
                   metadata => {
                       "source" => "desktop",
                       "load" => 3.67,
                       "contact_date" =>  1392036272,
                       "article" =>  {"url" =>  "https://example.org/ab1de.html",
                                      "value" => "the dude abides"},
                       "stripe_customer" =>  "cus_42424242424"
                   });

$obj->event_create(email => $test_email,
                   event_name => 'third-event',
                   metadata => {
                       "price" => {
                           "amount" => 34999,
                           "currency" =>  "eur"
                       }
                   });


$user->add_event(event_name => 'fourth event');




ok(defined($tag->save()), "Result is defined for saving a tag");

$user->delete();
$tag->delete();

done_testing;
