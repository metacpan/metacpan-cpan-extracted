#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

subtest 'load iterator'=> sub {
    plan tests => 3;

    class URT::DefaultLoaderIter {
        has => [qw/nose tail/],
        data_source => 'UR::DataSource::Default',
    };

    sub URT::DefaultLoaderIter::__load__ {
        my ($class, $bx, $headers) = @_;
        # for testing purposes we ignore the $bx and $headers, 
        # and return a 2-row, 3-column data set
        $headers = ['nose','tail','id'];
        my $body = [
            ['wet','waggly', 1001],
            ['dry','perky', 1002],
        ];

        my $iterator = sub { shift @$body };
        return $headers, $iterator;
    }

    my $new = URT::DefaultLoaderIter->create(nose => 'long', tail => 'floppy', id => 1003);
    ok($new, 'made a new object');

    # The system will trust the db engine, but then will merge results with any objects
    # already in memory.  This means our new object matches, and even though only one
    # of the database rows match, the broken db above will return 2 more items.  Totalling 3.
    my @p1 = URT::DefaultLoaderIter->get(nose => ['long','wet']);
    is(scalar(@p1), 2, "got two objects as expected, because we re-check the query engine by default");

    # Now that the query results are cached, the bug in the db logic is hidden, and we return 
    # the full results.
    my @p2 = URT::DefaultLoaderIter->get(nose => ['long','wet']);
    is(scalar(@p2), 2, "got two objects as expected");
};

subtest 'load list' => sub {
    plan tests => 2;

    class URT::DefaultLoadList {
        has => [qw/nose tail/],
        data_source => 'UR::DataSource::Default',
    };

    sub URT::DefaultLoadList::__load__ {
        my ($class, $bx, $headers) = @_;
        # Same as the iter loader, but return a list of lists
        # representing the resultset
        $headers = ['nose','tail','id'];
        my $body = [
            ['wet','waggly', 1001],
            ['dry','perky', 1002],
        ];

        return $headers, $body;
    }

    # The system will trust the db engine, but then will merge results with any objects
    # already in memory.  This means our new object matches, and even though only one
    # of the database rows match, the broken db above will return 2 more items.  Totalling 3.
    my @p1 = URT::DefaultLoaderIter->get(nose => ['long','wet']);
    is(scalar(@p1), 2, "got two objects as expected, because we re-check the query engine by default");

    # Now that the query results are cached, the bug in the db logic is hidden, and we return 
    # the full results.
    my @p2 = URT::DefaultLoaderIter->get(nose => ['long','wet']);
    is(scalar(@p2), 2, "got two objects as expected");
};

subtest 'join with two default datasources' => sub {
    plan tests => 6;

    class URT::ThingOne {
        has => ['id','t1_name'],
        data_source => 'UR::DataSource::Default',
    };
    our $thing_one_loader_called = 0;
    sub URT::ThingOne::__load__ {
        my($class, $bx, $headers) = @_;
        $thing_one_loader_called++;
        $headers = ['id', 't1_name'],
        my $body = [ [ 5, 'Bob' ] ];
        return ($headers, $body);
    }

    class URT::ThingTwo {
        has => [
            name => { is => 'String' },
            thing_one_id => { is => 'Integer' },
            thing_one => { is => 'URT::ThingOne', id_by => 'thing_one_id' },
            thing_one_name => { via => 'thing_one', to => 't1_name' },
        ],
        data_source => 'UR::DataSource::Default',
    };
    our $thing_two_loader_called = 0;
    sub URT::ThingTwo::__load__ {
        my($class, $bx, $headers) = @_;
        $thing_two_loader_called++;
        $headers = ['id', 'thing_one_id', 'name'],
        my $body = [ [ 99, 5, 'Joe' ] ];
        return ($headers, $body);
    }

    my $thing_two = URT::ThingTwo->get(thing_one_name => 'Bob');
    ok($thing_two, 'Loaded ThingTwo');
    is($thing_one_loader_called, 1, 'ThingOne loader called once');
    is($thing_two_loader_called, 1, 'ThingTwo loader called once');

    ($thing_one_loader_called, $thing_two_loader_called) = (0,0);
    my $thing_two_redux = URT::ThingTwo->get('thing_one.t1_name' => 'Bob');
    ok($thing_two_redux, 'Loaded ThingTwo again');
    is($thing_one_loader_called, 0, 'ThingOne loader was not called');
    is($thing_two_loader_called, 1, 'ThingTwo loader called once');
};

subtest 'save' => sub {
    plan tests => 5;

    class URT::DefaultSave {
        has => [qw/nose tail/],
        data_source => 'UR::DataSource::Default',
    };

    my @saved_ids;
    *URT::DefaultSave::__save__ = sub {
        my $self = shift;
        push @saved_ids, $self->id;
    };

    my @committed_ids;
    *URT::DefaultSave::__commit__ = sub {
        my $self = shift;
        push @committed_ids, $self->id;
    };

    # fake loading objects from the data source by defining them
    my $unchanged = URT::DefaultSave->__define__(id => 1, nose => 'black', tail => 'fluffy');
    my $will_change = URT::DefaultSave->__define__(id => 2, nose => 'short', tail => 'blue');

    # Make some changes
    ok($will_change->tail('black'), 'change existing object');
    my $new_obj = URT::DefaultSave->create(id => 3, nose => 'medium', tail => 'smooth');
    ok($new_obj, 'created new object');

    ok(UR::Context->current->commit, 'commit changes');

    is_deeply([ sort @saved_ids ],
       [2, 3],
       'Proper objects were saved');

    is_deeply([ sort @committed_ids ],
       [2, 3],
       'Proper objects were committed');
};

subtest 'failure syncing' => sub {
    plan tests => 3;

    class URT::FailSync {
        data_source => 'UR::DataSource::Default',
    };

    do {
        local *URT::FailSync::__save__ = sub {
            die "failed during save";
        };

        my $should_fail_during_rollback = 0;
        local *URT::FailSync::__rollback__= sub {
            die "failed during rollback" if $should_fail_during_rollback;
        };

        my $obj = URT::FailSync->create(id => 1);
        throws_ok { UR::Context->current->commit() }
            qr/failed during save/,
            'Failed in commit';

        my $error_message_during_commit;
        UR::DataSource::Default->dump_error_messages(0);
        UR::DataSource::Default->add_observer(
            aspect => 'error_message',
            once => 1,
            callback => sub {
                my($self, $aspect, $message) = @_;
                $error_message_during_commit = $message;
            },
        );
        $should_fail_during_rollback = 1;
        throws_ok { UR::Context->current->commit() }
            qr/Failed to save, and ERRORS DURING ROLLBACK:\s+failed during save.*failed during rollback/s,
            'Failed in commit second time';
        like($error_message_during_commit,
             qr/Rollback failed:.*'id' => 1/s,
            'error_message() mentions the object failed rollback');
    };

    UR::Context->current->rollback; # throw away errored objects
};

subtest 'sync all before committing' => sub {
    plan tests => 4;

    class URT::SyncThenCommit {
        data_source => 'UR::DataSource::Default',
    };

    my @objs = map { URT::SyncThenCommit->create(id => $_) } qw(1 2 3);

    my @synced_ids;
    my @committed_ids;
    *URT::SyncThenCommit::__save__ = sub {
        my $obj = shift;
        push @synced_ids, $obj->id;
        if (@committed_ids) {
            ok(0, 'Some objects were committed before all were synced')
                or diag explain @committed_ids;
        }
    };

    *URT::SyncThenCommit::__commit__ = sub {
        my $obj = shift;
        push @committed_ids, $obj->id;
    };

    UR::Context->current->add_observer(
        aspect => 'sync_databases',
        once => 1,
        callback => sub {
            is_deeply([ sort @synced_ids ],
                      [ qw(1 2 3) ],
                      'Synced all objects');
            is(scalar(@committed_ids), 0, 'No objects are committed yet');
        },
    );
    UR::Context->current->add_observer(
        aspect => 'commit',
        once => 1,
        callback => sub {
            is_deeply([ sort @committed_ids ],
                      [ qw(1 2 3) ],
                      'Committed all objects');
        },
    );

    ok(UR::Context->current->commit, 'commit');
};

subtest 'subclassify_by' => sub {
    plan tests => 2;

    class SubclassifyByParent {
        has => [
            subclass_name => { is => 'String' },
        ],
        is_abstract => 1,
        subclassify_by => 'subclass_name',
    };
    sub SubclassifyByParent::__load__ {
        my ($class, $bx, $headers) = @_;
        $headers = ['subclass_name', 'id'];
        my @data = ( [ 'SubclassifyByParent::TheSubclass', 1] );
        return($headers, sub { shift @data });
    }

    class SubclassifyByParent::TheSubclass {
        is => 'SubclassifyByParent',
    };

    my @objs = SubclassifyByParent->get();
    is(scalar(@objs), 1, 'get() on parent class returns one object');
    is($objs[0]->id, 1, 'Was the correct object');
};
