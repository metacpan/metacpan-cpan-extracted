#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 14;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

use URT::FakeDBI;


my(@events,@callback_args);

# A test datasource
package URT::DataSource::Testing;

class URT::DataSource::Testing {
    is => 'URT::DataSource::SomeSQLite'
};

sub disconnect {
    my $self = shift;
    push @events, 'method:disconnect';
    $self->SUPER::disconnect(@_);
}

sub create_default_handle {
    my $self = shift;
    push @events, 'method:create_default_handle';
    $self->SUPER::create_default_handle(@_);
}

{
    my $use_handle;
    sub _use_handle {
        my $self = shift;
        if (@_) {
            $use_handle = shift;
        }
        return $use_handle;
    }
}

sub get_default_handle {
    my $self = shift;
    if (my $h = $self->_use_handle) {
        return $h;
    }
    return $self->super_can('get_default_handle')->($self,@_);
}

*_init_created_dbh = \&init_created_handle;
sub init_created_handle {
    my $self = shift;
    push @events, 'method:init_created_handle';
    $self->SUPER::init_created_handle(@_);
}

# Fake table/column objects
UR::DataSource::RDBMS::Table->__define__(
    table_name => 'foo',
    owner => 'main',
    data_source => 'URT::DataSource::Testing');
UR::DataSource::RDBMS::TableColumn->__define__(
    column_name => 'test_id',
    table_name => 'foo',
    owner => 'main',
    data_source => 'URT::DataSource::Testing');

foreach my $method ( qw(precreate_handle create_handle predisconnect_handle disconnect_handle query_failed commit_failed) ) {
    URT::DataSource::Testing->create_subscription(
        method => $method,
        callback => sub {
            my $self = shift;
            my $reported_method = shift;
            my @cb_args = @_;
            for (my $i = 0; $i < @_; $i++) {
                no warnings 'uninitialized';
                $cb_args[$i] =~ s/\n+|\s+/ /sg;
                $cb_args[$i] =~ s/^\s//;
            }
            push @events, "signal:$reported_method";
            push @callback_args, \@cb_args;
        }
    );
}

UR::Object::Type->define(
    class_name => 'URT::TestingObject',
    data_source => 'URT::DataSource::Testing',
    table_name => 'foo',
    id_by => 'test_id',
);

package main;

my $dbh = URT::DataSource::Testing->get_default_handle();
ok($dbh, 'get_default_handle()');

is_deeply(\@events,
    ['signal:precreate_handle', 'method:create_default_handle', 'signal:create_handle', 'method:init_created_handle'],
    'signals and methods called in the expected order');

@events = ();

ok(URT::DataSource::Testing->disconnect_default_handle(), 'disconnect_default_handle()');
is_deeply(\@events,
    ['signal:predisconnect_handle', 'method:disconnect', 'signal:disconnect_handle'],
    'signals and methods called in the expected order');


# Test the error condition signals
my $test_dbh = URT::FakeDBI->new();
URT::DataSource::Testing->_use_handle($test_dbh);
URT::DataSource::Testing->dump_error_messages(0);
URT::TestingObject->dump_error_messages(0);

note('Setting fake handle to fail on prepare()');
$test_dbh->configure('prepare_fail', 'triggering prepare failure');
@events = ();
@callback_args = ();
eval { URT::TestingObject->get(1) };
is_deeply(\@events,
    ['signal:query_failed'],
    'prepare_failed signal called');
is_deeply(\@callback_args,
    [ ['prepare', 'select foo.test_id from foo where foo.test_id = ? order by foo.test_id', 'triggering prepare failure'] ],
    'query_failed callback given expected args');


note('setting fake handle to fail on execute()');
$test_dbh->configure('prepare_fail', undef);
$test_dbh->configure('execute_fail', 'triggering execute failure');
@events = ();
@callback_args = ();
eval { URT::TestingObject->get(2) };
is_deeply(\@events,
    ['signal:query_failed'],
    'query_failed signal called');
is_deeply(\@callback_args,
    [ ['execute', 'select foo.test_id from foo where foo.test_id = ? order by foo.test_id', 'triggering execute failure'] ],
    'query_failed callback given expected args');


note('setting fake handle to fail on prepare()');
$test_dbh->configure('execute_fail', undef);
$test_dbh->configure('prepare_fail', 'prepare fail on commit');
URT::TestingObject->create(3);
@events = ();
@callback_args = ();
UR::Context->current->dump_error_messages(0);
ok( ! eval { UR::Context->commit }, 'Commit should fail');
UR::Context->current->dump_error_messages(1);
is_deeply(\@events,
    ['signal:commit_failed'],
    'commit_failed signal called');
is_deeply(\@callback_args,
    [ ['prepare', 'INSERT INTO foo (test_id) VALUES (?)', 'prepare fail on commit'] ],
    'commit_failed given expected args');


note('setting fake handle to fail on execute()');
$test_dbh->configure('prepare_fail', undef);
$test_dbh->configure('execute_fail', 'execute fail on commit');
@events = ();
@callback_args = ();
ok( ! eval { UR::Context->commit }, 'Commit should fail');
is_deeply(\@events,
    ['signal:commit_failed'],
    'commit_failed signal called');
is_deeply(\@callback_args,
    [ ['execute', 'INSERT INTO foo (test_id) VALUES (?)', 'execute fail on commit'] ],
    'commit_failed given expected args');


