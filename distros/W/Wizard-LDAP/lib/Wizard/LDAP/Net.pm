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
use Wizard::LDAP::Config ();

@Wizard::LDAP::Net::ISA = qw(Wizard::LDAP);
$Wizard::LDAP::Net::VERSION = '0.01';

package Wizard::LDAP::Net;

sub init {
    my $self = shift; 
    return ($self->SUPER::init(1)) unless shift;
    my $item = $self->{'net'} || die "Missing net";
    ($self->SUPER::init(1), $item);
}


sub ShowMe {
    my($self, $wiz, $prefs, $net) = @_;
    (['Wizard::Elem::Title',
      'value' => $net->CreateMe() ?
          'LDAP Wizard: Create a new net' :
          'LDAP Wizard: Edit an existing net'],
     ($net->CreateMe() ? 
        ['Wizard::Elem::Text', 'name' => 'ldap-net-netname',
	 'value' => $net->{'ldap-net-netname'},
	 'descr' => 'Name of net']
      : ['Wizard::Elem::Data' => 'value' => $net->{'ldap-net-netname'},
	 'descr' => 'Name of net']),
     ['Wizard::Elem::Text', 'name' => 'ldap-net-mask',
      'value' => $net->{'ldap-net-mask'},
      'descr' => 'Netmask of the net'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-domain',
      'value' => $net->{'ldap-net-domain'},
      'descr' => 'Netmask domain'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-dns',
      'value' => $net->{'ldap-net-dns'},
      'descr' => 'DNS Server(s) for the network, seperated by ","'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-wins',
      'value' => $net->{'ldap-net-wins'},
      'descr' => 'WINS Server(s) for the network, seperated by ","'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-gateway',
      'value' => $net->{'ldap-net-gateway'},
      'descr' => 'Gateway for this net'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-timeserver',
      'value' => $net->{'ldap-net-timeserver'},
      'descr' => 'Timeserver for this net'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-reservedipbegin',
      'value' => $net->{'ldap-net-reservedipbegin'},
      'descr' => 'Reserved IP Block begin'],
     ['Wizard::Elem::Text', 'name' => 'ldap-net-reservedipend',
      'value' => $net->{'ldap-net-reservedipend'},
      'descr' => 'Reserved IP Block end'],
     ['Wizard::Elem::Submit', 'name' => 'Action_NetSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to Net menu', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::LDAP::Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


sub Action_Reset {
    my($self, $wiz) = @_;
    $self->init();

    delete $self->{'net'};
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard Net Menu'],
     ['Wizard::Elem::Submit', 'value' => 'Create a new net',
      'name' => 'Action_CreateNet',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Host menu',
      'name' => 'Action_HostMenu',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Modify an existing net',
      'name' => 'Action_ModifyNet',
      'id' => 3],
     ['Wizard::Elem::Submit', 'value' => 'Delete an existing net',
      'name' => 'Action_DeleteNet',
      'id' => 4],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'name' => 'Wizard::LDAP::Action_Reset',
      'id' => 98],
     ['Wizard::Elem::Submit', 'value' => 'Exit LDAP Wizard',
      'id' => 99]);
}

sub Action_CreateNet {
    my($self, $wiz) = @_;
    my ($prefs, $admin) = $self->init();
    my $net = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'ldap-net-',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'},
					   );
    $net->CreateMe(1);
    $self->{'net'} = $net;
    $self->Store($wiz);
    $self->ShowMe($wiz, $prefs, $net);
}

sub Action_NetSave {
    my($self, $wiz) = @_;
    my ($prefs, $admin, $net) = $self->init(1);
    my $base = $prefs->{'ldap-prefs-netbase'};
    local $SIG{'__WARN__'} = 'IGNORE';

    foreach my $opt ($wiz->param()) {
	$net->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^ldap\-net/) && (defined($wiz->param($opt))));
    }

    # Verify settings
    my $errors = '';
    my $name = $net->{'ldap-net-netname'} 
       or ($errors .= "Missing net name.\n");
    my $mask = $net->{'ldap-net-mask'} 
       or ($errors .= "Missing net mask.\n");
    my $domain = $net->{'ldap-net-domain'} 
       or ($errors .= "Missing net domain.\n");
    my $dns = $net->{'ldap-net-dns'};
    my $wins = $net->{'ldap-net-winns'};
    my $gateway = $net->{'ldap-net-gateway'};
    my $times = $net->{'ldap-net-timeserver'};
    my $ripb = $net->{'ldap-net-reservedipbegin'};
    my $ripe = $net->{'ldap-net-reservedipend'};

    my @servs = map { s/[\ ]*//g; (($_ ne '') ? $_ : ()); 
		  } (split(/\,/, $dns), split(/\,/, $wins), $times) ;
    my $serv;
    foreach $serv (@servs) {
	unless(Socket::inet_aton($serv)) {
	    $errors .= "Cannot resolve $serv.\n";
	}
    }
    my $nmask = new Net::Netmask($mask);
    $errors .= "Invalid netmask $mask, due to "
	      . $nmask->{'ERROR'} if $nmask->{'ERROR'};
    
    $errors .= "Only begin or end of reserved IP block has been specified.\n"
	if (($ripb && !$ripe) || (!$ripb && $ripe));
    if($ripb) {
	$errors .= "Invalid IP adress $ripb.\n" 
	    unless Socket::inet_aton($ripb);
	$errors .= "IP adress $ripb does not match the netmask $mask.\n" 
	    unless $nmask->match($ripb);
    }
    if($ripe) {
	$errors .= "Invalid IP adress $ripe.\n" 
	    unless Socket::inet_aton($ripe);
	$errors .= "IP adress $ripe does not match the netmask $mask.\n" 
	    unless $nmask->match($ripe);
    }

    if($domain !~ /^[\w\-]+(\.[\w\-]+)*$/) {
	$errors .= "Invalid domainnname $domain.\n";
    }

    $net->{'ldap-net-objectClass'} = 'net';
    die $errors if $errors;

    $net->AttrScalar2Ref('dns', 'wins');
    $net->Modified(1);
    $net->DN("network=$name, $base");

    $self->Store($wiz, 1);
    $self->OnChange('net');
    $self->Action_Reset($wiz);
}

sub Action_HostMenu {
    my $self = shift; my $wiz = shift;
    $self->Action_ModifyNet($wiz, 'Manage hosts in this net',
			     'Wizard::LDAP::Host::Action_Enter');
}

sub Action_ModifyNet {
    my $self = shift; my $wiz = shift; 
    my $button = shift || 'Modify Net';
    my $action = shift || 'Action_EditNet'; 
    my ($prefs, $admin) = $self->init();
    my $base = $prefs->{'ldap-prefs-netbase'};

    my @items = $self->ItemList($prefs, $admin, $base, 'netName');
    return $self->Action_Reset($wiz) unless @items;
    if(@items == 1) {
	# Hack: If there's only one net, pick it up immediately.
	# We need to load the class and bless ... :-(
	if ($action =~ /(.*)::/) {
	    my $class = $1;
	    my $cl = "$class.pm";
	    $cl =~ s/\:\:/\//g;
	    require $cl;
	    bless $self, $class;
	}
	$wiz->param('ldap-net', $items[0]);
	return $self->$action($wiz);
    }
    @items = sort @items;
    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => "LDAP Wizard Net Selection"],
     ['Wizard::Elem::Select', 'options' => \@items, 'name' => 'ldap-net',
      'descr' => 'Select an net'],
     ['Wizard::Elem::Submit', 'value' => $button, 'name' => $action,
      'id' => 1]);
}

sub Load {
    my($self, $wiz, $prefs, $admin, $dn) = @_;
    my $net = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'ldap-net-',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'},
					   'dn' => $dn, 'load' => 1);
    $net->DN($dn);
    $self->{'net'} = $net;
    $self->Store($wiz);
    $net->AttrRef2Scalar('dns', 'wins');
    $net;
}


sub Action_EditNet {
    my($self, $wiz) = @_;
    my($prefs, $admin) = $self->init();
    my $net = $wiz->param('ldap-net') || die "Missing net name.";
    my $dn = "network=$net, " . $prefs->{'ldap-prefs-netbase'};
    my $n = $self->Load($wiz, $prefs, $admin, $dn);
    $self->ShowMe($wiz, $prefs, $n);
}

sub Action_DeleteNet {
    shift->Action_ModifyNet(shift, 'Delete Net', 'Action_DeleteNet2');
}

sub Action_DeleteNet2 {
    my ($self, $wiz) = @_;
    my($prefs, $admin) = $self->init();
    my $netname = $wiz->param('ldap-net') || die "Missing net.";
    my $dn = "network=$netname, " . $prefs->{'ldap-prefs-netbase'};
    my $net = $self->Load($wiz, $prefs, $admin, $dn);

    (['Wizard::Elem::Title', 'value' => 'Deleting an LDAP Net ' . 
      '(and all the hosts belonging to it)'],
     ['Wizard::Elem::Data', 'descr' => 'Net name',
      'value' => $net->{'ldap-net-netname'}],
     ['Wizard::Elem::Data', 'descr' => 'Netmask',
      'value' => $net->{'ldap-net-mask'}],
     ['Wizard::Elem::Data', 'descr' => 'Net domain',
      'value' => $net->{'ldap-net-domain'}],
     ['Wizard::Elem::Data', 'descr' => 'Net DNS server(s)',
      'value' => $net->{'ldap-net-dns'}],
     ['Wizard::Elem::Data', 'descr' => 'Net WINS server(s)',
      'value' => $net->{'ldap-net-wins'}],
     ['Wizard::Elem::Data', 'descr' => 'Net gateway',
      'value' => $net->{'ldap-net-gateway'}],
     ['Wizard::Elem::Data', 'descr' => 'Net timeserver',
      'value' => $net->{'ldap-net-timeserver'}],
     ['Wizard::Elem::Data', 'descr' => 'Reserved IP begin',
      'value' => $net->{'ldap-net-reservedipbegin'}],
     ['Wizard::Elem::Data', 'descr' => 'Reserved IP end',
      'value' => $net->{'ldap-net-reservedipend'}],
     ['Wizard::Elem::Data', 'descr' => 'Net timeserver',
      'value' => $net->{'ldap-net-timeserver'}],
     ['Wizard::Elem::Submit', 'value' => 'Yes, delete it',
      'id' => 1, 'name' => 'Action_DeleteNet3'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Net Menu',
      'id' => 98, 'name' => 'Action_Reset'],
     ['Wizard::Elem::Submit', 'value' => 'Return to Top Menu',
      'id' => 99, 'name' => 'Wizard::LDAP::Action_Reset']);
}

sub Action_DeleteNet3 {
    my($self, $wiz) = @_;
    my($prefs, $admin, $net) = $self->init(1);
    ($prefs, $admin) = $self->init();
    my $base =  "network=" . $net->{'ldap-net-netname'} . ", " . $prefs->{'ldap-prefs-netbase'};
    my $mesg = $self->ItemList($prefs, $admin, $base, 'objectClass');
    my $entry;
    my $item = Wizard::SaveAble::LDAP->new('adminDN' => $admin->{'ldap-admin-dn'},
					   'adminPassword' => $admin->{'ldap-admin-password'},
					   'prefix' => 'NONE',
					   'serverip' => $prefs->{'ldap-prefs-serverip'},
					   'serverport' => $prefs->{'ldap-prefs-serverport'});
	
    foreach $entry ($mesg->entries) {
	$item->DN($entry->dn());
	$item->Delete();
    }
    
    $net->Delete();
    $self->OnChange('net');
    $self->Action_Reset($wiz);
}




