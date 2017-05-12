# -*- perl -*-

use strict;

use Net::LDAP ();
use Net::Netmask ();
use Socket ();
use Wizard ();
use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::SaveAble::LDAP ();
use Wizard::LDAP ();
use Wizard::LDAP::Net();
use Wizard::LDAP::Config ();

@Wizard::LDAP::Host::ISA = qw(Wizard::LDAP::Net);
$Wizard::LDAP::Host::VERSION = '0.01';

package Wizard::LDAP::Host;

sub init {
    my $self = shift; 
    return ($self->SUPER::init(1)) unless shift;
    my $item = $self->{'host'} || die "Missing host";
    ($self->SUPER::init(1), $item);
}


sub ShowMe {
    my($self, $wiz, $prefs, $host) = @_;
    (['Wizard::Elem::Title',
      'value' => $host->CreateMe() ?
          'LDAP Wizard: Create a new host' :
          'LDAP Wizard: Edit an existing host'],
     ['Wizard::Elem::Text', 'name' => 'ldap-host-hostname',
      'value' => $host->{'ldap-host-hostname'},
      'descr' => 'Name of Host'],
     ['Wizard::Elem::Text', 'name' => 'ldap-host-dnsname',
      'value' => $host->{'ldap-host-dnsname'},
      'descr' => 'DNS entry of the host'],
     ['Wizard::Elem::Text', 'name' => 'ldap-host-ip',
      'value' => $host->{'ldap-host-ip'},
      'descr' => 'IP adress of the host'],
     ['Wizard::Elem::Text', 'name' => 'ldap-host-mac',
      'value' => $host->{'ldap-host-mac'},
      'descr' => 'MAC address of host'],
     ['Wizard::Elem::Text', 'name' => 'ldap-host-timezone',
      'value' => $host->{'ldap-host-timezone'},
      'descr' => 'Timezone of host'],
     ['Wizard::Elem::Submit', 'name' => 'Action_HostSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to Host menu', 'id' => 97],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::LDAP::Net::Action_Reset',
      'value' => 'Return to Net menu', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::LDAP::Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


sub Action_Enter {
    my($self, $wiz) = @_;
    my($prefs, $admin) = $self->SUPER::init();
    my $dn = $wiz->param('ldap-net') || die "Missing net name";
    $dn = 'network=' . $dn . ', ' . $prefs->{'ldap-prefs-netbase'};
    my $net = $self->SUPER::Load($wiz, $prefs, $admin, $dn);
    $self->Action_Reset($wiz);
}

sub Action_Reset {
    my($self, $wiz) = @_;
    $self->init();

    delete $self->{'host'};
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard Host Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new host',
      'name' => 'Action_CreateHost',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing host',
      'name' => 'Action_ModifyHost',
      'id' => 3],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing host',
      'name' => 'Action_DeleteHost',
      'id' => 4],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::LDAP::Action_Reset',
      'id' => 97],
     ['Wizard::Elem::Submit', 'value' => 'Return to Net Menu',
      'name' => 'Wizard::LDAP::Net::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit LDAP Wizard',
      'id' => 99]);
}

sub Action_CreateHost {
    my($self, $wiz) = @_;
    my ($prefs, $admin, $net) = $self->init();
    my $host = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'ldap-host-',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'},
					   );
    my $base = 'network=' . $net->{'ldap-net-netname'} . ', ' 
	     . $prefs->{'ldap-prefs-netbase'};
    my $mesg = $self->ItemList($prefs, $admin, $base, 'hostName');
    my $ip = {}; my $dns = {}; my $hname;
    foreach my $entry ($mesg->entries) {
	my $hname = $entry->get('hostname');
	my @ips = $entry->get('ip'); my @dnss = $entry->get('dnsname');
	map { $ip->{$_} = $hname; } @ips;
	map { $dns->{$_} = $hname; } @dnss;
    }
    my $domain = $net->{'ldap-net-domain'};
    my $ripb = Socket::inet_aton($net->{'ldap-net-reservedipbegin'});
    my $ripe = Socket::inet_aton($net->{'ldap-net-reservedipend'});
    my $nm = new Net::Netmask($net->{'ldap-net-mask'});
    my ($nip, $nipt);
    my @allips = $nm->enumerate(); shift @allips; pop @allips;
    foreach $nip (@allips) {
	if($ripb && $ripe) {
	    $nipt = Socket::inet_aton($nip);
	    next if (($nipt ge $ripb) && ($nipt le $ripe));
	}
	unless(exists($ip->{$nip})) {
	    $host->{'ldap-host-ip'} = $nip;
	    last;
	}
    }
    my $i = 0;
    while(exists($dns->{"pc" . (++$i) . ".$domain"})) {};
    $host->{'ldap-host-dnsname'} = "pc" . $i . ".$domain";
    
    $host->CreateMe(1);
    $self->{'host'} = $host;
    $self->Store($wiz);
    $self->ShowMe($wiz, $prefs, $host);
}

sub Action_HostSave {
    my($self, $wiz) = @_;
    my ($prefs, $admin, $net, $host) = $self->init(1);
    my $base = "network=" . $net->{'ldap-net-netname'} . ', ' . $prefs->{'ldap-prefs-netbase'};

    foreach my $opt ($wiz->param()) {
	$host->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^ldap\-host/) && (defined($wiz->param($opt))));
    }

    # Verify settings
    my $errors = '';
    my $name = $host->{'ldap-host-hostname'} 
       or ($errors .= "Missing host name.\n");
    my $dns = $host->{'ldap-host-dnsname'} 
       or ($errors .= "Missing host dns name.\n");
    my $ip = $host->{'ldap-host-ip'} 
       or ($errors .= "Missing host ip.\n");
    my $mac = $host->{'ldap-host-mac'};

    $errors .= "Invalid dnsname $dns.\n" 
	if($dns !~ /^[\w\-]+(\.[\w\-]+)*(\,\s*[\w\-]+(\.[\w\-]+)*)*$/);

    if($ip) {
	my $ripb = Socket::inet_aton($net->{'ldap-net-reservedipbegin'});
	my $ripe = Socket::inet_aton($net->{'ldap-net-reservedipend'});
	foreach my $nip (split(/\,\s*/, $ip)) {
	    if(!(Socket::inet_aton($nip))) {
		$errors .= "Invalid ip address $nip.\n";
	    } else {
#  		my $nm = new Net::Netmask($net->{'ldap-net-mask'});
#  		$errors .= "IP address $nip does not match netmask "
#  		    . $net->{'ldap-net-mask'} . ".\n" unless($nm->match($nip));
		my $tip = Socket::inet_aton($nip);
		$errors .= "IP address $nip is in the reserved IP block.\n"
		    if (($ripb && $ripe) && (($tip ge $ripb) && 
					     ($tip le $ripe)));
		}
	}
    }

    if($mac) {
	$errors .= "Invalid MAC address $mac.\n" if ($mac !~ /^([\dA-Fa-f]{2}\:){5}[\dA-Fa-f]{2}$/);
    }

    $host->{'ldap-host-objectClass'} = 'host';

    die $errors if $errors;

    $host->AttrScalar2Ref('ip', 'dnsname');
    $host->DN('host=' . $name . ', ' . $base);
    $host->Modified(1);
    $self->Store($wiz, 1);
    $self->OnChange('host');
    $self->Action_Reset($wiz);
}


sub Action_ModifyHost {
    my $self = shift; my $wiz = shift; 
    my $button = shift || 'Modify Host';
    my $action = shift || 'Action_EditHost'; 
    my ($prefs, $admin, $net) = $self->init();
    my $base = "network=" . $net->{'ldap-net-netname'} . ', ' . $prefs->{'ldap-prefs-netbase'};

    my @items = $self->ItemList($prefs, $admin, $base, 'hostname');
    return $self->Action_Reset($wiz) unless @items;
    @items = sort @items;
    if(@items == 1) {
	$wiz->param('ldap-host', $items[0]);
	return $self->$action($wiz);
    }
    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => "LDAP Wizard Host Selection"],
     ['Wizard::Elem::Select', 'options' => \@items, 'name' => 'ldap-host',
      'descr' => 'Select a host'],
     ['Wizard::Elem::Submit', 'value' => $button, 'name' => $action,
      'id' => 1]);
}

sub Load {
    my($self, $wiz, $prefs, $admin, $dn) = @_;
    my $host = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'ldap-host-',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'},
					   'dn' => $dn, 'load' => 1);
    $host->AttrRef2Scalar('ip', 'dnsname');
    $host->DN($dn);
    $self->{'host'} = $host;
    $self->Store($wiz);
    $host;
}


sub Action_EditHost {
    my($self, $wiz) = @_;
    my($prefs, $admin, $net) = $self->init();
    my $host = $wiz->param('ldap-host') || die "Missing host name.";
    my $dn = "host=$host, network=" . $net->{'ldap-net-netname'} . ', ' . $prefs->{'ldap-prefs-netbase'};
    $self->ShowMe($wiz, $prefs, $self->Load($wiz, $prefs, $admin, $dn));
}

sub Action_DeleteHost {
    shift->Action_ModifyHost(shift, 'Delete Host', 'Action_DeleteHost2');
}

sub Action_DeleteHost2 {
    my ($self, $wiz) = @_;
    my($prefs, $admin, $net) = $self->init();
    my $hostname = $wiz->param('ldap-host') || die "Missing host.";
    my $dn = "host=$hostname, network=" . $net->{'ldap-net-netname'} . ', ' . $prefs->{'ldap-prefs-netbase'};
    my $host = $self->Load($wiz, $prefs, $admin, $dn);

    (['Wizard::Elem::Title', 'value' => 'Deleting an LDAP Host'],
     ['Wizard::Elem::Data', 'descr' => 'Host name',
      'value' => $host->{'ldap-host-hostname'}],
     ['Wizard::Elem::Data', 'descr' => 'Host dnsname',
      'value' => $host->{'ldap-host-dnsname'}],
     ['Wizard::Elem::Data', 'descr' => 'Host ip',
      'value' => $host->{'ldap-host-ip'}],
     ['Wizard::Elem::Data', 'descr' => 'Host MAC address',
      'value' => $host->{'ldap-host-mac'}],
     ['Wizard::Elem::Data', 'descr' => 'Host timezone',
      'value' => $host->{'ldap-host-timezone'}],
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteHost3'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Host Menu',
      'id' => 97, 'name' => 'Action_Reset'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Net Menu',
      'id' => 98, 'name' => 'Wizard::LDAP::Net::Action_Reset'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'id' => 99, 'name' => 'Wizard::LDAP::Action_Reset']);
}

sub Action_DeleteHost3 {
    my($self, $wiz) = @_;
    my($prefs, $admin, $net, $host) = $self->init(1);
    $host->Delete();
    $self->OnChange('host');
    $self->Action_Reset($wiz);
}

