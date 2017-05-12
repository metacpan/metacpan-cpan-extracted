use strict;
use warnings;

use Test::More tests => 25;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

use URT::FakeDBI;

# A Test datasource
# It allows errors with "retry this" to be retried
# The DBI component functions are at the bottom
    package URT::DataSource::Testing;

    class URT::DataSource::Testing {
        is => ['UR::DataSource::RDBMSRetriableOperations', 'URT::DataSource::SomeSQLite'],
        has => [ '_use_handle' ],
    };

    sub get_default_handle {
        my $self = UR::Util::object(shift);
        if (my $h = $self->_use_handle) {
            return $h;
        }
        return $self->super_can('get_default_handle')->($self,@_);
    }

    sub should_retry_operation_after_error {
        my($self, $sql, $dbi_errstr) = @_;
        return scalar($dbi_errstr =~ m/retry this/);
    }

    sub default_handle_class { 'URT::FakeDBI' }
            


# The entity we want to try saving

    package main;

    class TestThing {
        id_by => 'test_thing_id',
        data_source => 'URT::DataSource::Testing',
        table_name => 'main.test_thing',
        id_generator => 'test_thing_seq',
    };

# Fake table/column info for TestThing's table
    UR::DataSource::RDBMS::Table->__define__(
        table_name => 'main.test_thing',
        data_source => 'URT::DataSource::Testing');
    UR::DataSource::RDBMS::TableColumn->__define__(
        column_name => 'test_thing_id',
        table_name => 'test_thing',
        data_source => 'URT::DataSource::Testing');
    UR::DataSource::RDBMS::PkConstraintColumn->__define__(
        column_name => 'test_thing_id',
        table_name => 'main.test_thing',
        rank => 1,
        data_source => 'URT::DataSource::Testing');

#
# Set up the test
# We only want 2 retries...
#
my $test_ds = TestThing->__meta__->data_source;
$test_ds->dump_error_messages(0);
$test_ds->retry_sleep_start_sec(0.01);
$test_ds->retry_sleep_max_sec(0.03);

my $retry_count;
my @sleep_counts;
$test_ds->add_observer(
    aspect => 'retry',
    callback => sub {
        my($ds, $aspect, $sleep_time) = @_;
        $retry_count++;
        push @sleep_counts, $sleep_time;
    }
);
 
# Try a connection failure 
retry_test('get_default_handle', 'connect_fail', sub { $test_ds->get_default_handle });
not_retry_test('get_default_handle', 'connect_fail', sub { $test_ds->get_default_handle} );


# Try a get() failure
my $test_dbh = URT::FakeDBI->new();
$test_ds->_use_handle($test_dbh);

retry_test('get', 'prepare_fail', sub { TestThing->get(1) });
not_retry_test('get', 'prepare_fail', sub { TestThing->get(2) });

# Try a do() failure

retry_test('do_sql', 'do_fail', sub { $test_ds->do_sql('select foo from something') });
not_retry_test('do_sql', 'do_fail', sub { $test_ds->do_sql('select foo from something') });

# try a sequence generator retrieval failure
# UR::DS::SQLite uses do() to get sequence values
retry_test('sequence generator', 'do_fail', sub { TestThing->create() });
not_retry_test('sequence generator', 'do_fail', sub { TestThing->create() });


# try a commit failure
UR::Context->dump_error_messages(0);
retry_test('commit', 'prepare_fail', sub { TestThing->create(3); UR::Context->commit });
not_retry_test('commit', 'prepare_fail', sub { TestThing->create(4); UR::Context->commit });

sub retry_test {
    my($label, $dbi_config, $code) = @_;

    URT::FakeDBI->configure($dbi_config, 'we should retry this');
    $retry_count = 0;
    @sleep_counts = ();
    eval { $code->() };
    like($@, qr(Maximum database retries reached), qq($label: Trapped "max retry" exception));
    is($retry_count, 2, "$label retried 2 times");
    is_deeply(\@sleep_counts, [0.01,0.02], "$label sleep times");
}
    

sub not_retry_test {
    my($label, $dbi_config, $code) = @_;

    URT::FakeDBI->configure($dbi_config, 'fail only once');
    $retry_count = 0;
    eval { $code->() };

    my $error_string = $label eq 'commit' ? $test_ds->error_message : $@;
    like($error_string, qr(fail only once), "$label: non-retriable exception");
    is($retry_count, 0, "$label did not retry");
}

