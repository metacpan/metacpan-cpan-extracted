package Test::Story::Fixture::VMWare;
use Moose::Role;
use VMware::Vix::Simple;
use VMware::Vix::API::Constants;
use File::Temp qw( tempfile );

our $VERSION = 0.01;

our @EXCLUDE_METHODS = qw(
    selenium
    vmware
    is_valid 
    is_connected 
    hostname
    port
    server_username
    server_password
    cfg_path
    server_handle
    vm_handle
    num_snapshots 
    revertSnapshot 
    vm_names 
    is_running 
    start 
    guest_ip
);


sub BUILD {
    my $self = shift;
    my ($params) = @_;
    if (!exists($params->{config}->{cfg_path})) {
        $self->is_valid(0);
    } else {
        $self->is_valid(1);
    }
}

sub DEMOLISH {
    my $self = shift;
    if ($self->is_connected) {
        ReleaseHandle($self->vm_handle);
        HostDisconnect($self->server_handle);
        ReleaseHandle($self->server_handle);
    }
}

has 'is_valid' => (
    is => 'rw',
    isa => 'Bool',
);

has 'is_connected' => (
    is => 'rw',
    isa => 'Bool',
);

has 'hostname' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my $host = $self->config->{server} || "";
        return "" unless $host;
        $host =~ s/:\d+$//;
        return $host;
    }
);

has 'port' => (
    is => 'ro',
    required => 1,
    isa => 'Int',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my $host = $self->config->{server};
        return 0 unless $host;
        my ($port) = $host =~ /:(\d+)$/;
        return $port || 902;
    }
);

has 'server_username' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
    lazy => 1,
    default => sub { 
        my $self = shift;
        return $self->config->{server_username} || "";
    }
);

has 'server_password' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
    lazy => 1,
    default => sub { 
        my $self = shift;
        return $self->config->{server_password} || "";
    }
);

has 'cfg_path' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
    lazy => 1,
    default => sub { 
        my $self = shift;
        return $self->config->{cfg_path};
    }
);

has 'server_handle' => (
    is => 'ro',
    required => 1,
    isa => 'Int',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my ($err, $handle) = ();
        ($err, $handle) = HostConnect(
            VIX_API_VERSION,
            VIX_SERVICEPROVIDER_VMWARE_SERVER,
            $self->hostname,
            $self->port,
            $self->server_username,
            $self->server_password,
            0,
            VIX_INVALID_HANDLE,
        );
        die "Can't connect to the VMWare server: $err " . GetErrorText($err) . "\n"
            unless ($err == VIX_OK);
        $self->is_connected(1);
        return $handle;
    },
);

has 'vm_handle' => (
    is => 'ro',
    required => 1,
    isa => 'Int',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my ($err, $handle) = VMOpen($self->server_handle, $self->cfg_path);
        die "Could not open virtual machine: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
        return $handle;
    },
);

sub num_snapshots {
    my $self = shift;
    my ($err, $num) = VMGetNumRootSnapshots($self->server_handle); 
    die "Could not get a list of snapshots: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    return $num;
}

sub revertSnapshot {
    my $self = shift;
    my ($num) = @_;
    $num ||= 0;
    my ($err, $snapshot);
    return unless ($self->num_snapshots);
    ($err, $snapshot) = VMGetRootSnapshot($self->server_handle, $num); 
    die "Could not get root snapshot $num: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    $err = VMRevertToSnapshot($self->server_handle, $snapshot, 0, VIX_INVALID_HANDLE); 
    die "Could not revert to snapshot $num: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
}

sub vm_names {
    my $self = shift;
    my ($timeout) = @_;
    $timeout ||= 10;
    my ($err, @vms) = FindRunningVMs($self->server_handle, $timeout); 
    die "Could not get list of running virtual machines: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    warn "VMS: " . join(", ", @vms);
    return @vms;
}

sub is_running {
    my $self = shift;
    my ($err, $power_state) = GetProperties($self->vm_handle, VIX_PROPERTY_VM_POWER_STATE); 
    die "Could not get properties for virtual machine: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    return ($power_state == VIX_POWERSTATE_POWERED_ON);
}

sub start {
    my $self = shift;
    my ($timeout) = @_;
    $timeout ||= 120;
    my $err = VMPowerOn($self->vm_handle, VIX_VMPOWEROP_NORMAL, VIX_INVALID_HANDLE);
    die "Could not power on virtual machine: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    $err = VMWaitForToolsInGuest($self->vm_handle, $timeout);
    die "Could not wait for the VMWare Tools to start in the guest: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    if ($self->config->{vm_username}) {
        my $user = $self->config->{vm_username};
        my $pass = $self->config->{vm_password} || 'tester1';
        $err = VMLoginInGuest($self->vm_handle, $user, $pass, 0);
        die "Could not log in to the guest as [$user/$pass]: $err ", GetErrorText($err), "\n" if $err != VIX_OK;
    }
}

has 'guest_ip' => (
    is => 'ro',
    required => 1,
    isa => 'Str',
    lazy => 1,
    default => sub { 
        my $self = shift;
        if (!$self->is_running) {
            $self->start();
        }
        my $err;

        my ($copybat_fh, $copybat_filename) = tempfile();
        print $copybat_fh 'ipconfig > C:\getip.txt';
        close $copybat_fh;
        $err = VMCopyFileFromHostToGuest($self->vm_handle, $copybat_filename, 'c:\getip.bat', 0, VIX_INVALID_HANDLE);
        die "Could not copy the IP batch file to the guest: $err ", GetErrorText($err), "\n" if $err != VIX_OK;

        $err = VMRunProgramInGuest($self->vm_handle, 'c:\getip.bat', '', 0, VIX_INVALID_HANDLE);
        die "Could not wait run ipconfig in the guest: $err ", GetErrorText($err), "\n" if $err != VIX_OK;

        my ($getip_fh, $getip_filename) = tempfile();
        $err = VMCopyFileFromGuestToHost($self->vm_handle, 'c:\getip.txt', $getip_filename, 0, VIX_INVALID_HANDLE);
        die "Could not copy the IP file from the guest: $err ", GetErrorText($err), "\n" if $err != VIX_OK;

        my $ip;
        {
            local $/;
            my $ip_str = <$getip_fh>;
            close $getip_fh;
            ($ip) = $ip_str =~ /IP Address.*:\s*([\d\.]+)/;
        }
        return $ip;
    },
);

sub selenium {
    if ( $self->DOES("Selenium") ) {
        if (exists $self->config->{selenium}->{"virtual machine"}) {
            my $vm = $self->vmware;
            if ($vm) {
                $vm->start if (!$vm->is_running);
                if (!$self->_get_metavar('selenium.server')) {
                    $self->config->{selenium}{server} = $vm->guest_ip;
                }
            }
        }
    }
}

has 'vmware' => (
    is => 'ro',
    required => 1,
    isa => 'Object',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my $config = $self->config->{selenium}->{"virtual machine"};
        return undef unless($config);
        return Test::Story::VMWare->new({ config => $config });
    },
);

sub ensure_testing_environment_is_in_a_consistent_state {
    my $self = shift;
    if ($self->vmware->is_valid) {
        $self->vmware->revertSnapshot();
    }
}


1;
__END__


=head1 SEE ALSO

=over 4

=item *

L<Test::Story::Fixture>

=item *

L<VMWare::Vix::Simple>

=back


