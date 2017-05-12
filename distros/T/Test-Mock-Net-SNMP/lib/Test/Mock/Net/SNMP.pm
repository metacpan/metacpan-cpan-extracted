package Test::Mock::Net::SNMP;

use 5.008008;
use strict;
use warnings;
use Carp;
use Readonly;
use Test::MockObject::Extends;

Readonly::Scalar my $VARBINDLIST_MULTIPLE => 3;
Readonly::Scalar my $MAX_RETRIES          => 20;
Readonly::Scalar my $MIN_MSG_OCTETS       => 484;
Readonly::Scalar my $MAX_MSG_OCTETS       => 65_535;
Readonly::Scalar my $DEFAULT_MSG_SIZE     => 1_472;
Readonly::Scalar my $DEFAULT_TIMEOUT      => 5.0;
Readonly::Scalar my $NEGATIVE_ONE         => -1;

our $VERSION = '1.02';

=pod

=for stopwords Halliday oid oids SNMP varbindlist varbindnames varbindtypes Varbindlist hostname -varbindlist undef

=head1 NAME

Test::Mock::Net::SNMP - Perl extension for mocking Net::SNMP in your unit tests.

=head1 SYNOPSIS

  use Test::Mock::Net::SNMP;
  my $mock_snmp = Test::Mock::Net::SNMP->new();

=head1 DESCRIPTION

Test::Mock::Net::SNMP is a simple way to mock a Net::SNMP object and allows you 
to test your modules behaviour when retrieving SNMP data or sending SNMP traps.

=head1 METHODS

=cut

=head2 new

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

Generates the mock object required to mock Net::SNMP

=cut

sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless $self, $class;

    $self->_initialise();

    return $self;
}

=head2 set_varbindlist

$mock_net_snmp->set_varbindlist(
    [
        {'1.3.6.1.2.1.2.2.1' => 1, '1.3.6.1.2.1.2.2.2' => 2, '1.3.6.1.2.1.2.2.3' => 3, '1.3.6.1.2.1.2.2.4' => 4},
        {'1.3.6.1.2.1.2.2.5' => 5, '1.3.6.1.2.1.2.3.1' => 1, '1.3.6.1.2.1.2.3.2' => 2, '1.3.6.1.2.1.2.3.3' => 5}
    ]
);

set_varbindlist is the main way of returning values in Net::SNMP
the most important part of setting up the mock is setting this correctly
takes an array reference of varbindlist hashes and returns true

This will also set up varbindnames, but you can overwrite this by
calling set_varbindnames (see below). set_varbindlist will overwrite
varbindnames so it's best to call this first.

To force a failed return for a request method or a call to var_bind_list
assign a value of undef to the array element that represents that call.

i.e. if we have a blocking get_request that is performed after two set 
request, and we want that request to fail to make sure that our code is
handling a the failure correctly, we could set it up like this:

$mock_net_snmp->set_varbindlist(
    [
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Building 1, First Floor' },
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Building 1, Second Floor' },
        undef,
        { '1.3.6.1.2.1.1.3.0' => 600 }
    ]
);

=cut

sub set_varbindlist {
    my ($self, $vbl) = @_;

    # varbindnames is just a list of the oids in vabindlist so we can build this automatically
    # start by clearing it out
    $self->{varbindnames} = [];
    for my $lst (@{$vbl}) {
        next unless defined $lst;
        my $names = [];
        @{$names} = sort { $a cmp $b } keys %{$lst};
        push @{ $self->{varbindnames} }, $names;
    }
    $self->{varbindlist} = $vbl;
    return 1;
}

=head2 set_varbindnames

$mock_net_snmp->set_varbindnames([[qw( 2.2.1 2.2.3 2.2.4 )]]);

varbindnames is a list of names for each oid, it should match the
keys of the hash that the call to var_bind_list returns.

set_varbindnames takes an array reference of arrays of oids.

=cut

sub set_varbindnames {
    my ($self, $vbn) = @_;
    $self->{varbindnames} = $vbn;
    return 1;
}

=head2 set_varbindtypes

$mock_net_snmp->set_varbindtypes(
    [
        { '1.2.1.1' => OCTET_STRING, '1.2.1.2' => OCTET_STRING, '1.2.1.3' => OCTET_STRING },
        { '1.2.2.1' => OCTET_STRING, '1.2.2.2' => OCTET_STRING, '1.2.2.3' => OCTET_STRING }
    ]
);

varbindtypes is a hash of types for each oid

set_varbindtypes takes an array reference of varbindtypes

=cut

sub set_varbindtypes {
    my ($self, $vbt) = @_;
    $self->{varbindtypes} = $vbt;
    return 1;
}

=head2 set_session_failure

$mock_net_snmp->set_session_failure()

calling this method will mean that all calls to Net::SNMP->session 
will fail.

To revert this you need to call reset_values (see below)

=cut

sub set_session_failure {
    my ($self) = @_;
    return $self->{session_failure} = 1;
}

=head2 set_error

$mock_net_snmp->set_error('Error message');

This method allows you to override the error message that 
will be returned if an error occurs.

=cut

sub set_error {
    my ($self, $message) = @_;
    return $self->{error} = $message;
}

=head2 set_error_status

$mock_net_snmp->set_error_status($status);

This lets you set the return value of an $snmp->error_status() call.

=cut

sub set_error_status {
    my ($self, $status) = @_;
    return $self->{error_status} = $status;
}

=head2 set_error_index

$mock_net_snmp->set_error_index($index);

This lets you set the return value of an $snmp->error_index() call.

=cut

sub set_error_index {
    my ($self, $index) = @_;
    return $self->{error_index} = $index;
}

=head2 get_option_val

is($mock_net_snmp->get_option_val('session','-hostname'),q{myhost.myserver.com},q{correct hostname passed to session});

is_deeply($mock_net_snmp->get_option_val('get_request','-varbindlist',0),['1.2.2.1'],q{first call to get_request is for 1.2.2.1});

is($mock_net_snmp->get_option_val($method,$option,$position), $expected, qq{$option passed to $method in call $postition is $expected});

where:
$method is the mocked method, 
$option is the option passed into the method,
$position is the position in the call stack (the last call is returned if no position is given) 

it returns the value for that option.

Net::SNMP lets you specify options in a style such as -varbindlist or Varbindlist. Test::Mock::Net::SNMP expects you to retrieve the option values using the same style as the option passed in. So if your method call uses Varbindlist then $option should equal Varbindlist.

=cut

sub get_option_val {
    my ($self, $method, $option, $position) = @_;
    croak "Unknown mocked method: $method" unless exists $self->{$method};
    if ($method eq 'session') {

        #session values are not stored in a call stack
        croak "Option: <$option> was not passed in to $method" unless exists $self->{$method}{$option};
        return $self->{$method}{$option};
    } else {
        $position = $NEGATIVE_ONE unless defined $position;
        croak "Option: <$option> was not passed in to $method at position $position"
          unless exists $self->{$method}[$position]{$option};
        return $self->{$method}[$position]{$option};
    }
}

=head2 get_num_method_calls

$mock_net_snmp->get_num_method_calls('get_request');

returns the number of times that the requested method was called.

=cut

sub get_num_method_calls {
    my ($self, $method) = @_;

    # if the method is not in $self then either it doesn't exist or it wasn't called
    return 0 unless exists $self->{$method};

    # session calls should only register once
    return 1 if $method eq 'session';

    # return the number of option values in the methods array
    return scalar @{ $self->{$method} };
}

=head2 reset_values

$mock_net_snmp->reset_values();

Sets all the values to their original state.

=cut

sub reset_values {
    my ($self) = @_;
    for my $setting (keys %{$self}) {

        # we want to keep the mocked object
        next if $setting eq 'net_snmp';
        delete $self->{$setting};
    }
    return 1;
}

=head2 clear_error

$mock_net_snmp->clear_error();

Test::Mock::Net::SNMP will only update the error string if it hasn't already been set. This means that sometimes it is useful to clear the error string

=cut

sub clear_error {
    my ($self) = @_;
    return $self->{error} = q{};
}

=head2 set_trap_failure

$mock_net_snmp->set_trap_failure();

force a trap method to fail.

=cut

sub set_trap_failure {
    my ($self) = @_;
    return $self->{trap_error} = 1;
}

# private methods go here.

# set up all the mocked methods
sub _initialise {
    my ($self) = @_;
    $self->{net_snmp} = Test::MockObject::Extends->new('Net::SNMP');
    $self->_mock_session();    # this needs calling before any of the others
    $self->_mock_close();
    $self->_mock_snmp_dispatcher();
    $self->_mock_get_request();
    $self->_mock_get_next_request();
    $self->_mock_set_request();
    $self->_mock_trap();
    $self->_mock_get_bulk_request();
    $self->_mock_inform_request();
    $self->_mock_snmpv2_trap();
    $self->_mock_get_table();
    $self->_mock_get_entries();
    $self->_mock_version();
    $self->_mock_error();
    $self->_mock_hostname();
    $self->_mock_error_status();
    $self->_mock_error_index();
    $self->_mock_var_bind_list();
    $self->_mock_var_bind_names();
    $self->_mock_var_bind_types();
    $self->_mock_timeout();
    $self->_mock_retries();
    $self->_mock_max_msg_size();
    $self->_mock_translate();
    $self->_mock_debug();
    return 1;    # return true if we got here
}

sub _mock_session {
    my ($self) = @_;

    #session() - create a new Net::SNMP object
    $self->{net_snmp}->fake_module(
        'Net::SNMP',
        session => sub {
            my ($return_val);
            my ($ns_class, %session_options) = @_;

            # tell all the other methods that we are open
            $self->{closed} = 0;

            # store the session options
            $self->{session} = \%session_options;

            # allow for failing a call to session
            if ($self->{session_failure}) {
                $return_val = undef;
                $self->{error} = 'session failure' unless defined $self->{error} && $self->{error};
            } else {
                $return_val = $self->{net_snmp};
            }

            # Net::SNMP returns the object and an error string if you want it
            if (wantarray) {
                return $return_val, $self->{error};
            } else {

                # it returns the object if you call it in scalar
                return $return_val;
            }
        }
    );
    return 1;
}

sub _mock_close {
    my ($self) = @_;

    #close() - clear the Transport Domain associated with the object
    $self->{net_snmp}->mock(close => sub { return $self->{closed} = 1; });
    return 1;
}

sub _mock_snmp_dispatcher {
    my ($self) = @_;

    #snmp_dispatcher() - enter the non-blocking object event loop
    # all of the mocked methods are going to block so this only needs to return true
    $self->{net_snmp}->set_true('snmp_dispatcher');
    return 1;
}

sub _process_varbindlist {
    my ($self, $caller, %args) = @_;

    # if we don't have varbindlist then that will be an error
    unless (exists $args{Varbindlist} || exists $args{-varbindlist}) {
        $self->{error} = '-varbindlist option not passed in to ' . $caller unless $self->{error};
        return 0;
    }

    return 1;
}

sub _process_trap_varbindlist {
    my ($self, $caller, %args) = @_;

    # check the first 2 sets of values are as expected
    my $vbl = $args{Varbindlist} || $args{-varbindlist} || [];
    my $sets = $VARBINDLIST_MULTIPLE + $VARBINDLIST_MULTIPLE;
    if (scalar @{$vbl} < ($sets)) {
        $self->{error} = "$caller requires sysUpTime and snmpTrapOID as the first 2 sets of varbindlist."
          unless $self->{error};
        return 0;
    }

    my $list = $args{-varbindlist} || $args{Varbindlist};
    if (scalar @{$list} % $VARBINDLIST_MULTIPLE > 0) {

        # we have an incorrect number of variables
        $self->{error} = "-varbindlist expects multiples of $VARBINDLIST_MULTIPLE in call to $caller"
          unless $self->{error};
        return 0;
    }

    unless ($vbl->[0] eq '1.3.6.1.2.1.1.3.0' && $vbl->[$VARBINDLIST_MULTIPLE] eq '1.3.6.1.6.3.1.1.4.1.0') {
        $self->{error} = "$caller: Wrong oids found in sysUpTime and snmpTrapOID spaces" unless $self->{error};
        return 0;
    }

    return 1;
}

sub _get_varbindlist {
    my ($self) = @_;

    if (defined $self->{varbindlist} && @{ $self->{varbindlist} }) {
        my $value = shift @{ $self->{varbindlist} };
        return $value if defined $value;
    }

    $self->{error} = 'No more elements in varbindlist!' unless $self->{error};
    return;
}

sub _process_callback {
    my ($self, %args) = @_;

    my $cb = $args{-callback} || $args{Callback} || $self->{cb} || q{};
    if ($cb) {

        # calls from within the callback don't set the call back so we need to track it
        $self->{cb} = $cb;

        if (ref($cb) eq 'ARRAY') {

            # best not mess with our reference
            my @cbs = @{$cb};
            my $sub = shift @cbs;
            $sub->($self->{net_snmp}, @cbs);
        } else {
            $cb->($self->{net_snmp});
        }
        return 1;

    } else {

        # we are blocking so return the first element of varbindlist
        return $self->_get_varbindlist();
    }
    return 1;
}

# sets the error message appropriately and returns the value of closed
sub _closed {
    my ($self) = @_;
    $self->{error} = q{Can't call method on closed object} if $self->{closed};
    return $self->{closed};
}

sub _mock_get_request {

    #get_request() - send a SNMP get-request to the remote agent
    # this just sets up the object with passed in variables so that we can
    # call them later if we need to and calls the callback if one was provided
    my ($self) = @_;
    $self->{net_snmp}->mock(
        get_request => sub {
            my ($class, %args) = @_;
            push @{ $self->{get_request} }, \%args;

            return if $self->_closed();

            # check varbindlist vals
            return unless $self->_process_varbindlist('get_request', %args);
            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_get_next_request {

    #get_next_request() - send a SNMP get-next-request to the remote agent
    my ($self) = @_;
    $self->{net_snmp}->mock(
        get_next_request => sub {
            my ($class, %args) = @_;
            push @{ $self->{get_next_request} }, \%args;

            return if $self->_closed();

            # check varbindlist vals
            return unless $self->_process_varbindlist('get_next_request', %args);
            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_set_request {

    #set_request() - send a SNMP set-request to the remote agent
    my ($self) = @_;
    $self->{net_snmp}->mock(
        set_request => sub {
            my ($class, %args) = @_;
            push @{ $self->{set_request} }, \%args;

            return if $self->_closed();

            # check varbindlist vals
            return unless $self->_process_varbindlist('set_request', %args);
            my $list = $args{-varbindlist} || $args{Varbindlist};
            if (scalar @{$list} % $VARBINDLIST_MULTIPLE > 0) {

                # we have an incorrect number of variables
                $self->{error} = "-varbindlist expects multiples of $VARBINDLIST_MULTIPLE in call to set_request"
                  unless $self->{error};
                return;
            }

            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_trap {

    #trap() - send a SNMP trap to the remote manager
    my ($self) = @_;
    $self->{net_snmp}->mock(
        trap => sub {
            my ($class, %args) = @_;
            push @{ $self->{trap} }, \%args;
            return if $self->_closed();

            if (defined $self->{trap_error} && $self->{trap_error}) {
                return;
            } else {
                return 1;
            }
        }
    );
    return 1;
}

sub _mock_get_bulk_request {

    #get_bulk_request() - send a SNMP get-bulk-request to the remote agent
    my ($self) = @_;
    $self->{net_snmp}->mock(
        get_bulk_request => sub {
            my ($class, %args) = @_;
            push @{ $self->{get_bulk_request} }, \%args;

            return if $self->_closed();

            # check varbindlist vals
            return unless $self->_process_varbindlist('get_bulk_request', %args);
            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_inform_request {

    #inform_request() - send a SNMP inform-request to the remote manager
    my ($self) = @_;
    $self->{net_snmp}->mock(
        inform_request => sub {
            my ($class, %args) = @_;
            push @{ $self->{inform_request} }, \%args;

            return if $self->_closed();

            return unless $self->_process_varbindlist('inform_request', %args);
            return unless $self->_process_trap_varbindlist('inform_request', %args);
            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_snmpv2_trap {

    #snmpv2_trap() - send a SNMP snmpV2-trap to the remote manager
    my ($self) = @_;
    $self->{net_snmp}->mock(
        snmpv2_trap => sub {
            my ($class, %args) = @_;
            push @{ $self->{snmpv2_trap} }, \%args;

            return if $self->_closed();

            return unless $self->_process_varbindlist('snmpv2_trap', %args);
            return unless $self->_process_trap_varbindlist('snmpv2_trap', %args);

            if (defined $self->{trap_error} && $self->{trap_error}) {
                return;
            } else {
                return 1;
            }
        }
    );
    return 1;
}

sub _mock_get_table {

    #get_table() - retrieve a table from the remote agent
    my ($self) = @_;
    $self->{net_snmp}->mock(
        get_table => sub {
            my ($class, %args) = @_;
            push @{ $self->{get_table} }, \%args;

            return if $self->_closed();

            unless (exists $args{-baseoid} || exists $args{Baseoid}) {
                $self->{error} = '-baseoid not passed in to get_table' unless $self->{error};
                return;
            }

            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_get_entries {

    #get_entries() - retrieve table entries from the remote agent
    my ($self) = @_;
    $self->{net_snmp}->mock(
        get_entries => sub {
            my ($class, %args) = @_;
            push @{ $self->{get_entries} }, \%args;

            return if $self->_closed();

            unless (exists $args{-columns} || exists $args{Columns}) {
                $self->{error} = '-columns not passed in to get_entries' unless $self->{error};
                return;
            }

            return $self->_process_callback(%args);
        }
    );
    return 1;
}

sub _mock_version {

    #version() - get the SNMP version from the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        version => sub {
            my ($class) = @_;
            my $version = $self->{session}{-version} || $self->{session}{Version} || 1;
            my ($return) = $version =~ /(\d)/;
            return $return;
        }
    );
    return 1;
}

sub _mock_error {

    #error() - get the current error message from the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        error => sub {
            return $self->{error};
        }
    );
    return 1;
}

sub _mock_hostname {

    #hostname() - get the hostname associated with the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        hostname => sub {
            return $self->{session}{-hostname} || $self->{session}{Hostname} || 'localhost';
        }
    );
    return 1;
}

sub _mock_error_status {

    #error_status() - get the current SNMP error-status from the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        error_status => sub {
            $self->{error_status} = 0 unless defined $self->{error_status};
            return $self->{error_status};
        }
    );
    return 1;
}

sub _mock_error_index {

    #error_index() - get the current SNMP error-index from the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        error_index => sub {
            $self->{error_index} = 0 unless defined $self->{error_index};
            return $self->{error_index};
        }
    );
    return 1;
}

sub _mock_var_bind_list {

    #var_bind_list() - get the hash reference for the VarBindList values
    my ($self) = @_;
    $self->{net_snmp}->mock(
        var_bind_list => sub {
            return $self->_get_varbindlist();
        }
    );
    return 1;
}

sub _mock_var_bind_names {

    #var_bind_names() - get the array of the ObjectNames in the VarBindList
    my ($self) = @_;
    $self->{net_snmp}->mock(
        var_bind_names => sub {
            if (@{ $self->{varbindnames} }) {
                my $names = shift @{ $self->{varbindnames} };
                return @{$names};
            } else {
                $self->{error} = 'No more elements in varbindnames!' unless $self->{error};
                return;
            }
        }
    );
    return 1;
}

sub _mock_var_bind_types {

    #var_bind_types() - get the hash reference for the VarBindList ASN.1 types
    my ($self) = @_;
    $self->{net_snmp}->mock(
        var_bind_types => sub {
            if (@{ $self->{varbindtypes} }) {
                return shift @{ $self->{varbindtypes} };
            } else {
                $self->{error} = 'No more elements in varbindtypes!' unless $self->{error};
                return;
            }
        }
    );
    return 1;
}

sub _mock_timeout {

    #timeout() - set or get the current timeout period for the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        timeout => sub {
            my ($class, $option) = @_;
            if ($option) {
                $self->{timeout} = $option;
                return $option;
            } else {
                return $self->{timeout} || $DEFAULT_TIMEOUT;
            }
        }
    );
    return 1;
}

sub _mock_retries {

    #retries() - set or get the current retry count for the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        retries => sub {
            my ($class, $option) = @_;
            if ($option) {
                if ($option >= 0 && $option <= $MAX_RETRIES) {
                    $self->{retries} = $option;
                    return $option;
                } else {
                    $self->{error} = 'retries out of range';
                    return;
                }
            } else {
                return $self->{retries} || 1;
            }
        }
    );
    return 1;
}

sub _mock_max_msg_size {

    #max_msg_size() - set or get the current maxMsgSize for the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        max_msg_size => sub {
            my ($class, $option) = @_;
            if ($option) {
                if ($option >= $MIN_MSG_OCTETS && $option <= $MAX_MSG_OCTETS) {
                    $self->{max_msg_size} = $option;
                    return $option;
                } else {
                    $self->{error} = 'max msg size out of range';
                    return;
                }
            } else {
                return $self->{max_msg_size} || $DEFAULT_MSG_SIZE;
            }
        }
    );
    return 1;
}

sub _mock_translate {

    #translate() - enable or disable the translation mode for the object
    my ($self) = @_;
    $self->{net_snmp}->mock(
        translate => sub {
            my ($class, $option) = @_;
            if ($option) {
                $self->{translate} = $option;
            }
            return $self->{translate} || 1;
        }
    );
    return 1;
}

sub _mock_debug {

    #debug() - set or get the debug mode for the module
    my ($self) = @_;
    $self->{net_snmp}->mock(
        debug => sub {
            my ($class, $option) = @_;
            if ($option) {
                $self->{debug} = $option;
                return $option;
            } else {
                $self->{debug} = 0 unless defined $self->{debug};
                return $self->{debug};
            }
        }
    );
    return 1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 ADDITIONAL CHECKS

Some additional checks are performed to make sure that:

1.) The methods that expect a -varbindlist option are passed one
2.) The first two oids of an snmpv2_trap and inform_request are there
3.) those functions that should pass multiples of three do.
4.) checks that some arguments are within range.

It's important to not rely on these checks and instead check them through your unit tests, but you may find your tests dying if the input values are known to be incorrect.

=head1 SEE ALSO

Net::SNMP, Test::MockObject::Extends

=head1 AUTHOR

Rob Halliday, E<lt>robh@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Rob Halliday

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
