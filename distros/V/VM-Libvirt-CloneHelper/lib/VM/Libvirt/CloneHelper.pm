package VM::Libvirt::CloneHelper;

use 5.006;
use strict;
use warnings;
use File::Slurp qw(write_file read_file);
use File::Temp;

=head1 NAME

VM::Libvirt::CloneHelper - Create a bunch of cloned VMs in via libvirt.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # initialize it
    my $clone_helper=VM::Libvirt::CloneHelper->new({
        blank_domains=>'/usr/local/etc/clonehelper/blank_domains',
        net_head=>'/usr/local/etc/clonehelper/net_head',
        net_tail=>'/usr/local/etc/clonehelper/net_tail',
        windows_blank=>0,
        mac_base=>'00:08:74:2d:dd:',
        ipv4_base=>'192.168.1.',
        start=>'100',
        to_clone=>'baseVM',
        clone_name_base=>'foo',
        count=>10,
        verbose=>1,
        snapshot_name=>'clean',
        net=>'default',
    });

    $clone_helper->delete_vms;
    $clone_helper->clone_vms;
    $clone_helper->start_vms;
    sleep 500;
    $clone_helper->snapshot_vms;
    $clone_helper->shutdown_vms;

It should be noted that this is effectively limited to 253 VMs.

This script lib is primarily meant for creating a bunch of cloned VMs on a
box for testing purposes, so this is not really a major issue given the
design scope.

VMs should be set to us DHCP so they will get their expected IP when they boot.

=head1 METHODS

=head2 new

Initialize the module.

    net=>'default'
    Name of the libvirt network in question.

    blank_domains=>'/usr/local/etc/clonehelper/blank_domains',
    List of domains to blank via setting 'dnsmasq:option value='address=/foo.bar/'.
    If not this file does not exist, it will be skipped.

    net_head=>'/usr/local/etc/clonehelper/net_head',
    The top part of the net XML config that that dnsmasq options will be
    sandwhiched between.

    net_tail=>'/usr/local/etc/clonehelper/net_tail',
    The bottom part of the net XML config that that dnsmasq options will
    be sandwhiched between.

    windows_blank=>1,
    Blank commonly used MS domains. This is handy for reducing network noise
    when testing as well as making sure they any VMs don't do something like
    run updates when one does not want it to.

    mac_base=>'00:08:74:2d:dd:',
    Base to use for the MAC.

    ipv4_base=>'192.168.1.',
    Base to use for the IPs for adding static assignments.

    start=>'100',
    Where to start in set.

    to_clone=>'baseVM',
    The name of the VM to clone.

    clone_name_base=>'cloneVM',
    Base name to use for creating the clones. 'foo' will become 'foo$current', so
    for a start of 100, the first one would be 'foo100' and with a count of 10 the
    last will be 'foo109'.

    count=>10,
    How many clones to create.

    snapshot_name=>'clean',
    The name to use for the snapshot.

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	my $self = {
		blank_domains   => '/usr/local/etc/clonehelper/blank_domains',
		net_head        => '/usr/local/etc/clonehelper/net_head',
		net_tail        => '/usr/local/etc/clonehelper/net_tail',
		windows_blank   => 1,
		mac_base        => '00:08:74:2d:dd:',
		ipv4_base       => '192.168.1.',
		start           => '100',
		to_clone        => 'baseVM',
		delete_old      => 1,
		clone_name_base => 'foo',
		uuid_auto       => 1,
		count           => 10,
		verbose         => 1,
		snapshot_name   => 'clean',
		net             => 'default',
	};
	bless $self;

	# do very basic value sanity checks and reel values in
	my @keys = keys(%args);
	foreach my $key (@keys) {
		if ( $key eq 'mac_base' ) {

			# make sure we got a sane base MAC
			if ( $args{mac_base}
				!~ /^[0-9aAbBcCdDeEfF][0-9aAbBcCdDeEfF]\:[0-9aAbBcCdDeEfF][0-9aAbBcCdDeEfF]\:[0-9aAbBcCdDeEfF][0-9aAbBcCdDeEfF]\:[0-9aAbBcCdDeEfF][0-9aAbBcCdDeEfF]\:[0-9aAbBcCdDeEfF][0-9aAbBcCdDeEfF]\:$/
				)
			{
				die( '"' . $args{mac_base} . '" does not appear to be a valid base for a MAC address' );
			}
		}
		elsif ( $key eq 'ipv4_base' ) {

			# make sure we have a likely sane base for the IPv4 address
			if ( $args{ipv4_base} !~ /^[0-9]+\.[0-9]+\.[0-9]+\.$/ ) {
				die( '"' . $args{ipv4_base} . '" does not appear to be a valid base for a IPv4 address' );
			}
		}
		elsif ( $key eq 'to_clone' ) {

			# make sure we have a likely sane base VM name
			if ( $args{to_clone} !~ /^[A-Za-z0-9\-\.]+$/ ) {
				die( '"' . $args{to_clone} . '" does not appear to be a valid VM name' );
			}
		}
		elsif ( $key eq 'clone_name_base' ) {

			# make sure we have a likely sane base name to use for creating clones
			if ( $args{clone_name_base} !~ /^[A-Za-z0-9\-\.]+$/ ) {
				die( '"' . $args{clone_name_base} . '" does not appear to be a valid VM name' );
			}
		}

		# likely good, adding
		$self->{$key} = $args{$key};
	}

	return $self;
}

=head2 clone

Create the clones.

    $clone_helper->clone;

=cut

sub clone {
	my $self = $_[0];

	my $VMs = $self->vm_list;

	my @VM_names = sort( keys( %{$VMs} ) );
	foreach my $name (@VM_names) {
		print "Cloning '".$self->{to_clone}."' to '" . $name . "'(".$VMs->{$name}{mac}.", ".$VMs->{$name}{ip}.")...\n";

		my @args = ( 'virt-clone', '-m', $VMs->{$name}{mac}, '-o', $self->{to_clone},'--auto-clone','-n', $name );
		system(@args) == 0 or die("system '@args' failed... $?");
	}
}

=head2 delete_clones

Delete all the clones

    $clone_helper->delete_clones;

=cut

sub delete_clones {
	my $self = $_[0];

	# virsh undefine --snapshots-metadata
	# the VM under /var/lib/libvirt/images needs to be removed manually given
	# the shit show that is libvirt does not have a means of sanely removing
	# VMs and relevant storage... for example it will include ISOs in relevant
	# VMs to be removed if you let it... and it is likely to fail to remove the
	# base disk image for a VM, even if you pass it any/every combination of
	# possible flags...

	my $VMs = $self->vm_list;

	my @VM_names = sort( keys( %{$VMs} ) );
	foreach my $name (@VM_names) {
		print "Undefining " . $name . "\n";
		my @args = ( 'virsh', 'undefine', '--snapshots-metadata', $name );
		system(@args) == 0 or warn("system '@args' failed... $?");

		my $image = '/var/lib/libvirt/images/' . $name . '.qcow2';

		if ( -f $image ) {
			print "Unlinking " . $image . "\n";
			unlink($image) or die( 'unlinking "' . $image . '" failed... ' . $! );
		}
	}
}

=head2 net_xml

Returns a string with the full net config XML.

    my $net_config_xml=$clone_helper->net_xml;
    print $net_config_xml;

=cut

sub net_xml {
	my $self = $_[0];

	my $VMs = $self->vm_list;

	my $xml      = read_file( $self->{net_head} ) or die( 'Failed to read "' . $self->{net_head} . '"' );
	my $xml_tail = read_file( $self->{net_tail} ) or die( 'Failed to read "' . $self->{net_tail} . '"' );

	if ( $self->{windows_blank} ) {
		$xml = $xml . '    <dnsmasq:option value=\'address=/microsoft.com/\'/>
    <dnsmasq:option value=\'address=/windowsupdate.com/\'/>
    <dnsmasq:option value=\'address=/windows.com/\'/>
    <dnsmasq:option value=\'address=/microsoft.com.nsatc.net/\'/>
    <dnsmasq:option value=\'address=/bing.net/\'/>
    <dnsmasq:option value=\'address=/live.com/\'/>
    <dnsmasq:option value=\'address=/cloudapp.net/\'/>
    <dnsmasq:option value=\'address=/cs1.wpc.v0cdn.net/\'/>
    <dnsmasq:option value=\'address=/a-msedge.net/\'/>
    <dnsmasq:option value=\'address=/-msedge.net/\'/>
    <dnsmasq:option value=\'address=/msedge.net/\'/>
    <dnsmasq:option value=\'address=/microsoft.com.akadns.net/\'/>
    <dnsmasq:option value=\'address=/footprintpredict.com/\'/>
    <dnsmasq:option value=\'address=/microsoft-hohm.com/\'/>
    <dnsmasq:option value=\'address=/msn.com/\'/>
    <dnsmasq:option value=\'address=/social.ms.akadns.net/\'/>
    <dnsmasq:option value=\'address=/msedge.net/\'/>
    <dnsmasq:option value=\'address=/dc-msedge.net/\'/>
    <dnsmasq:option value=\'address=/bing.com/\'/>
    <dnsmasq:option value=\'address=/edgekey.net/\'/>
    <dnsmasq:option value=\'address=/azureedge.net/\'/>
    <dnsmasq:option value=\'address=/amsn.net/\'/>
    <dnsmasq:option value=\'address=/moiawsorigin.clo.footprintdns.com/\'/>
    <dnsmasq:option value=\'address=/office365.com/\'/>
    <dnsmasq:option value=\'address=/skype.com/\'/>
    <dnsmasq:option value=\'address=/trafficmanager.net/\'/>
';
	}

	if ( -f $self->{blank_domains} ) {
		my $blank_raw = read_file( $self->{blank_domains} ) or die( 'Failed to read "' . $self->{blank_domains} . '"' );

		# remove any blank lines or anyhting commented out
		my @blank_split = grep( !/^[\ \t]*]$/, grep( !/^[\ \t]*#/, split( /\n/, $blank_raw ) ) );
		foreach my $line (@blank_split) {
			chomp($line);
			$line =~ s/^[\ \t]*//;
			$line =~ s/[\ \t]*$//;
			foreach my $domain ( split( /[\ \t]+/, $line ) ) {
				$xml = $xml . "    <dnsmasq:option value='address=/" . $domain . "/'/>\n";
			}
		}
	}

	my @VM_names = sort( keys( %{$VMs} ) );
	foreach my $name (@VM_names) {
		$xml
			= $xml
			. '    <dnsmasq:option value=\'dhcp-host='
			. $VMs->{$name}{mac} . ','
			. $VMs->{$name}{ip} . '\'/>' . "\n";
	}

	return $xml . $xml_tail;
}

=head2 net_redefine

Redefines the network in question.

=cut

sub net_redefine {
	my $self = $_[0];

	my $xml = $self->net_xml;

	print "Undefining the the network('" . $self->{net} . "') for readding it...\n";
	my @args = ( 'virsh', 'net-undefine', $self->{net} );
	system(@args) == 0 or die("system '@args' failed... $?");

	my $fh       = File::Temp->new;
	my $tmp_file = $fh->filename;

	write_file( $tmp_file, $xml ) or die( 'Failed to write tmp net config to "' . $tmp_file . '"... ' . $@ );

	print "Defining the the network('" . $self->{net} . "') for readding it...\n";
	@args = ( 'virsh', 'net-define', '--file', $tmp_file );
	system(@args) == 0 or die("system '@args' failed... $?");

	unlink($tmp_file) or die( 'Failed to unlink net config "' . $tmp_file . '"... ' . $@ );

	return;
}

=head2 snapshot_clones

Snapshot all the clones

    $clone_helper->snapshot_clones;

=cut

sub snapshot_clones {
	my $self = $_[0];

	my $VMs = $self->vm_list;

	my @VM_names = sort( keys( %{$VMs} ) );
	foreach my $name (@VM_names) {
		print "Snapshotting " . $name . "...\n";
		my @args = ( 'virsh', 'snapshot-create-as', '--name', $self->{snapshot_name}, $name );
		system(@args) == 0 or die("system '@args' failed... $?");
	}
}

=head2 start_clones

Start all the clones

    $clone_helper->start_clones;

=cut

sub start_clones {
	my $self = $_[0];

	my $VMs = $self->vm_list;

	my @VM_names = sort( keys( %{$VMs} ) );
	foreach my $name (@VM_names) {
		print "Starting " . $name . "...\n";
		my @args = ( 'virsh', 'start', $name );
		system(@args) == 0 or die("system '@args' failed... $?");
	}
}

=head2 stop_clones

Stop all the clones. This does not stop them gracefully as we don't
need to as they are being started via snapshot.

    $clone_helper->stop_clones;

=cut

sub stop_clones {
	my $self = $_[0];

	my $VMs = $self->vm_list;

	my @VM_names = sort( keys( %{$VMs} ) );
	foreach my $name (@VM_names) {
		print "Stopping " . $name . "...\n";
		my @args = ( 'virsh', 'destroy', $name );
		system(@args) == 0 or warn("system '@args' failed... $?");
	}
}

=head2 vm_list

Generate a list of VMs.

=cut

sub vm_list {
	my $self = $_[0];

	my $VMs = {};

	my $current = $self->{start};
	my $till    = $current + $self->{count} - 1;
	while ( $current <= $till ) {
		my $name = $self->{clone_name_base} . $current;
		my $hex  = sprintf( '%#x', $current );
		$hex =~ s/^0[Xx]//;

		$VMs->{$name} = {
			ip  => $self->{ipv4_base} . $current,
			mac => $self->{mac_base} . $hex,
		};

		$current++;
	}

	return $VMs;
}

=head1 BLANKED MS DOMAINS

    microsoft.com
    windowsupdate.com
    windows.com
    microsoft.com.nsatc.net
    bing.net
    live.com
    cloudapp.net
    cs1.wpc.v0cdn.net
    -msedge.net
    msedge.net
    microsoft.com.akadns.net
    footprintpredict.com
    microsoft-hohm.com
    msn.com
    social.ms.akadns.net
    msedge.net
    dc-msedge.net
    bing.com
    edgekey.net
    azureedge.net
    amsn.net
    moiawsorigin.clo.footprintdns.com
    office365.com
    skype.com
    trafficmanager.net

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vm-libvirt-clonehelper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=VM-Libvirt-CloneHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VM::Libvirt::CloneHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=VM-Libvirt-CloneHelper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/VM-Libvirt-CloneHelper>

=item * Search CPAN

L<https://metacpan.org/release/VM-Libvirt-CloneHelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of VM::Libvirt::CloneHelper
