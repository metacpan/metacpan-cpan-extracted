package UR::DataSource::RDBMSRetriableOperations;

use strict;
use warnings;

use Time::HiRes;

# A mixin class that provides methods to retry queries and syncs
#
# Consumers should provide should_retry_operation_after_error().
# It's passed the SQL that generated the error and the DBI error string.
# It should return true if the operation generating that error should be
# retried.

class UR::DataSource::RDBMSRetriableOperations {
    has_optional => [
        retry_sleep_start_sec   => { is => 'Integer', value => 1, doc => 'Initial inter-error sleep time' },
        retry_sleep_max_sec     => { is => 'Integer', value => 3600, doc => 'Maximum inter-error sleep time' },
    ],
    valid_signals => ['retry']
};


# The guts of the thing.  Consumers that want a base-datasource method to
# be retriable should override the method to call this instead, and pass
# a code ref to perform the retriable action

sub _retriable_operation {
    my $self = UR::Util::object(shift);
    my $code = shift;

    $self->_make_retriable_operation_observer();

    RETRY_LOOP:
    for( my $db_retry_sec = $self->retry_sleep_start_sec;
         $db_retry_sec < $self->retry_sleep_max_sec;
         $db_retry_sec *= 2
    ) {
        my @rv = eval { $code->(); };

        if ($@) {
            if ($@ =~ m/DB_RETRY/) {
                $self->error_message("DB_RETRY");
                $self->debug_message("Disconnecting and sleeping for $db_retry_sec seconds...\n");
                $self->disconnect_default_handle;
                Time::HiRes::sleep($db_retry_sec);
                $self->__signal_observers__('retry', $db_retry_sec);
                next RETRY_LOOP;
            }
            Carp::croak($@);  # re-throw other exceptions
        }
        return $self->context_return(@rv);
    }
    die "Maximum database retries reached";
}


{
    my %retry_observers;
    sub _make_retriable_operation_observer {
        my $self = shift;
        unless ($retry_observers{$self->class}++) {
            for (qw(query_failed commit_failed do_failed connect_failed sequence_nextval_failed)) {
                $self->add_observer(
                    aspect => $_,
                    priority => 99999, # Super low priority to fire last
                    callback => \&_db_retry_observer,
                );
            }
        }
    }
}

# Default is to not retry
sub should_retry_operation_after_error {
    my($self, $sql, $dbi_errstr) = @_;
    return 0;
}


# The callback for the retry observer
sub _db_retry_observer {
    my($self, $aspect, $db_operation, $sql, $dbi_errstr) = @_;

    unless (defined $sql) {
        $sql = '(no sql)';
    }
    $self->error_message("SQL failed during $db_operation\nerror: $dbi_errstr\nsql: $sql");

    die "DB_RETRY" if $self->should_retry_operation_after_error($sql, $dbi_errstr);

    # just fall off the end here...
    # Code triggering the observer will throw an exception
}


# Searches the parentage of $self for a RDBMS datasource class
# and returns a ref to the named sub in that package
# This is necessary because we're using a mixin class and not
# a real role
my %cached_rdbms_datasource_method_for;
sub rdbms_datasource_method_for {
    my $self = shift;
    my $method = shift;
    my $target_class_name = shift;

    $target_class_name ||= $self->class;
    if ($cached_rdbms_datasource_method_for{$target_class_name}) {
        return $cached_rdbms_datasource_method_for{$target_class_name}->can($method);
    }

    foreach my $parent_class_name ( $target_class_name->__meta__->parent_class_names ) {
        if ( $parent_class_name->isa('UR::DataSource::RDBMS') ) {
            if ($parent_class_name->isa(__PACKAGE__) ) {
                if (my $sub = $self->rdbms_datasource_method_for($method, $parent_class_name)) {
                    return $sub;
                }
            } else {
                $cached_rdbms_datasource_method_for{$target_class_name} = $parent_class_name;
                return $parent_class_name->can($method);
            }
        }
    }
    return;
}

# The retriable methods we want to wrap

foreach my $parent_method (qw(
    create_iterator_closure_for_rule
    create_default_handle
    _sync_database
    do_sql
    autogenerate_new_object_id_for_class_name_and_rule
)) {
    my $override = sub {
        my $self = shift;
        my @params = @_;

        # Installing this as the $parent_method leads to infinte recursion if
        # the parent does not directly inherit this class.
        use warnings FATAL => qw( recursion );

        my $parent_sub ||= $self->rdbms_datasource_method_for($parent_method);
        $self->_retriable_operation(sub {
            $self->$parent_sub(@params);
        });
    };

    Sub::Install::install_sub({
        into => __PACKAGE__,
        as   => $parent_method,
        code => $override,
    });
}

1;
