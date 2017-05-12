#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use open ':encoding(utf8)', ':std';
use Test::More tests => 11;

BEGIN {
    use_ok( 'WebService::Megaplan' ) || print "Bail out!\n";
}

SKIP: {
    skip 'No env MEGAPLAN_LOGIN',    10 if(! $ENV{MEGAPLAN_LOGIN});
    skip 'No env MEGAPLAN_PASSWORD', 10 if(! $ENV{MEGAPLAN_PASSWORD});
    skip 'No env MEGAPLAN_HOST',     10 if(! $ENV{MEGAPLAN_HOST});
    skip 'No env MEGAPLAN_PROJECT',  10 if(! $ENV{MEGAPLAN_PROJECT});

    my $api = WebService::Megaplan->new(
                    login => $ENV{MEGAPLAN_LOGIN},
                    password => $ENV{MEGAPLAN_PASSWORD},
                    hostname => $ENV{MEGAPLAN_HOST},
                    use_ssl  => 1,
                );
    ok($api, 'object created');

    my $user_id = $api->authorize();
    ok($user_id, 'login successful');

    ok($api->secret_key, 'got SecretKey');
    ok($api->access_id, 'got AccessID');

    my $data = $api->post_data('/BumsTaskApiV01/Task/create.api', {
                                    'Model[Name]'        => 'Test task',
                                    # 'p' means Project - task added to project ID
                                    'Model[SuperTask]'   => 'p' . $ENV{MEGAPLAN_PROJECT},
                                    'Model[Statement]'   => 'Verify API access',
                                    # assign it to myself
                                    'Model[Responsible]' => $user_id,
                                });
    ok($data, 'task response');
    ok($data->{data}->{task}->{Id}, 'new task id');

    my $comment = $api->post_data('/BumsCommonApiV01/Comment/create.api', {
                                    SubjectType   => 'task',
                                    SubjectId     => $data->{data}->{task}->{Id},
                                    'Model[Text]' => 'New comment via API',
                                    # If you want attach file - encode it in base64 and provide visible name:
                                    # 'Model[Attaches][0][Content]' => MIME::Base64::encode_base64($content),
                                    # 'Model[Attaches][0][Name]'    => 'document.pdf',
                                });
    ok($comment, 'comment response');
    ok($comment->{data}->{comment}->{Id}, 'new comment id');

    # mark task as accepted (cannot just complete it)
    my $reply_accept = $api->post_data('/BumsTaskApiV01/Task/action.api', {
                                        Id     => $data->{data}->{task}->{Id},
                                        Action => 'act_accept_task',
                                });
    ok($reply_accept);

    # mark task as complete
    my $reply_done = $api->post_data('/BumsTaskApiV01/Task/action.api', {
                                        Id     => $data->{data}->{task}->{Id},
                                        Action => 'act_done',
                                });
    ok($reply_done);
}

diag( "Testing WebService::Megaplan $WebService::Megaplan::VERSION, Perl $], $^X" );
