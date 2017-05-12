#!perl
use BTDT::Test::WWW::Declare tests => 9;
use strict;
use warnings;

session "gooduser" => run {
    flow "create task" => check {
        login as 'gooduser';
        fill form 'tasklist-new_item_create' => {
            summary => "bouncy task",
        };
        click button 'Create';
        content should contain "bouncy task";
    };

    flow "assign task to otheruser" => check {
        click href qr{bouncy task};
        fill form mech->moniker_for("BTDT::Action::UpdateTask", id => 3) => {
            owner_id => 'otheruser@example.com',
        };
        click button 'Save';

        content should contain 'something or other';
    };

    session "otheruser" => run {
        flow "accept gooduser's task" => check {
            login as 'otheruser';
            click href qr{unaccepted task(s)?};
            content should contain 'bouncy task';
            click href qr{bouncy task};

            fill form mech->moniker_for('BTDT::Action::AcceptTask') => {
                accepted => 1,
            };
            click button 'Save';

            content should contain 'Task accepted';
        };
    };

    flow "comment on the task I gave" => check {
        click href qr{bouncy task};
        content should contain 'bouncy task';

        fill form mech->moniker_for('BTDT::Action::UpdateTask', id => 3) => {
            comment => "first comment",
        };

        click button 'Save';

        session "otheruser" => run {
            flow "check that we got the comment" => check {
                reload;
                content should contain 'first comment';
            };
        };
    };

    flow "add another comment" => check {
        fill form mech->moniker_for('BTDT::Action::UpdateTask', id => 3) => {
            comment => "second comment",
        };

        click button 'Save';
    };
};

