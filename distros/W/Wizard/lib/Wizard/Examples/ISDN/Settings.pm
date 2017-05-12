# -*- perl -*-

use strict;

use Wizard::State ();
use Wizard::SaveAble ();
use Wizard::SaveAble::ShellVars ();
use Wizard::Examples::ISDN ();
use File::Spec ();
use File::Path ();
use Socket ();
use Symbol ();


package Wizard::Examples::ISDN::Settings;

@Wizard::Examples::ISDN::Settings::ISA = qw(Wizard::Examples::ISDN);
$Wizard::Examples::ISDN::Settings::VERSION = '0.01';

sub init {
    my $self = shift; 
    return $self->SUPER::init(1) unless shift;
    my $item = $self->{'settings'} || die "Missing settings";
    ($self->SUPER::init(1), $item);
}

sub GetKey { 'host';};

sub ShowMe {
    my($self, $wiz, $sets) = @_;
    (['Wizard::Elem::Title',
      'value' => 'Edit ISDN settings'],
     ['Wizard::Elem::Select', 'name' => 'isdn-settings-I4L_HARDWARE_ENABLED',
      'options' => ['yes', 'no'],
      'value' => $sets->{'isdn-settings-I4L_HARDWARE_ENABLED'},
      'descr' => 'Enable ISDN subsystem'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-I4L_HARDWARE',
      'value' => $sets->{'isdn-settings-I4L_HARDWARE'},
      'descr' => 'Name of the ISDN cards, for example "Fritz"'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-I4L_HARDWARE_IO',
      'value' => $sets->{'isdn-settings-I4L_HARDWARE_IO'},
      'descr' => 'IO address of the ISDN hardware'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-I4L_HARDWARE_IRQ',
      'value' => $sets->{'isdn-settings-I4L_HARDWARE_IRQ'},
      'descr' => 'IRQ number of the ISDN hardware'],
     ['Wizard::Elem::Select', 'name' => 'isdn-settings-I4L_HARDWARE_PROTO',
      'options' => ['1TR6 (1)', 'Euro ISDN (2)'],
      'value' => ($sets->{'isdn-settings-I4L_HARDWARE_PROTO'} eq '1' ? '1TR6 (1)' : 'Euro ISDN (2)'),
      'descr' => 'ISDN protocol, 1TR6 or Euro ISDN'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-I4L_HARDWARE_PHONE',
      'value' => $sets->{'isdn-settings-I4L_HARDWARE_PHONE'},
      'descr' => 'Local MSN or EAZ; maybe empty'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-INTERNET_PHONE_OUT',
      'value' => $sets->{'isdn-settings-INTERNET_PHONE_OUT'},
      'descr' => 'Phone number of the Internet dailup line; may be empty'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-INTERNET_PHONE_IN',
      'value' => $sets->{'isdn-settings-INTERNET_PHONE_IN'},
      'descr' => 'Phone number of the Internet dailin line; may be empty'],
     ['Wizard::Elem::Select', 'name' => 'isdn-settings-INTERNET_ENABLED',
      'options' => ['yes', 'no'],
      'value' => $sets->{'isdn-settings-INTERNET_ENABLED'},
      'descr' => 'Use this ISDN card for Internet'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-INTERNET_USER',
      'value' => $sets->{'isdn-settings-INTERNET_USER'},
      'descr' => 'User name to login as'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-INTERNET_PASSWORD',
      'value' => $sets->{'isdn-settings-INTERNET_PASSWORD'},
      'descr' => 'Password to use'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-SERVICE_PHONE_OUT',
      'value' => $sets->{'isdn-settings-SERVICE_PHONE_OUT'},
      'descr' => 'Phone number of the service dialup line; may be empty'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-SERVICE_PHONE_IN',
      'value' => $sets->{'isdn-settings-SERVICE_PHONE_IN'},
      'descr' => 'Phone number of the service dialin line; may be empty'],
     ['Wizard::Elem::Select', 'name' => 'isdn-settings-SERVICE_ENABLED',
      'options' => ['yes', 'no'],
      'value' => $sets->{'isdn-settings-SERVICE_ENABLED'},
      'descr' => 'Use this ISDN card for Service dailup'],
     ['Wizard::Elem::Select', 'name' => 'isdn-settings-SERVICE_RAWIP',
      'options' => ['yes', 'no'],
      'value' => $sets->{'isdn-settings-SERVICE_RAWIP'},
      'descr' => 'Use RawIp on the Service line'],
     ['Wizard::Elem::Select', 'name' => 'isdn-settings-SERVICE_CALLBACK',
      'options' => ['yes', 'no'],
      'value' => $sets->{'isdn-settings-SERVICE_CALLBACK'},
      'descr' => 'Enable Callback on the service line'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-SERVICE_USER',
      'value' => $sets->{'isdn-settings-SERVICE_USER'},
      'descr' => 'Service user name (used only if RawIp is disabled; may be empty'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-SERVICE_PASSWORD',
      'value' => $sets->{'isdn-settings-SERVICE_PASSWORD'},
      'descr' => 'Password of the service user'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-SERVICE_IP_LOCAL',
      'value' => $sets->{'isdn-settings-SERVICE_IP_LOCAL'},
      'descr' => 'Local IP address of the service line'],
     ['Wizard::Elem::Text', 'name' => 'isdn-settings-SERVICE_IP_REMOTE',
      'value' => $sets->{'isdn-settings-SERVICE_IP_REMOTE'},
      'descr' => 'Rempote IP address of the service line'],
     ['Wizard::Elem::Submit', 'name' => 'Action_SettingsSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to ISDN menu', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Wizard::Examples::ISDN::Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


sub Action_SettingsSave {
    my($self, $wiz) = @_;
    my ($prefs, $basedir, $sets) = $self->init(1);
    
    foreach my $opt ($wiz->param()) {
	$sets->{$opt} = $wiz->param($opt) if (($opt =~ /^isdn-settings/) && defined($wiz->param($opt)));
    }
    
    $sets->{'isdn-settings-I4L_HARDWARE_PROTO'} = '1' if $sets->{'isdn-settings-I4L_HARDWARE_PROTO'} =~ /^1TR6/i;
    $sets->{'isdn-settings-I4L_HARDWARE_PROTO'} = '2' if $sets->{'isdn-settings-I4L_HARDWARE_PROTO'} =~ /^Euro/i;

    # Verify the new settings
    my $errors = '';
    my $ip_local = $sets->{'isdn-settings-SERVICE_IP_LOCAL'};
    my $ip_remote = $sets->{'isdn-settings-SERVICE_IP_REMOTE'};

    if ($ip_local) {
	$errors .= "Cannot resolve Service Local IP address $ip_local.\n"
	    unless Socket::inet_aton($ip_local);
    }
    if ($ip_remote) {
	$errors .= "Cannot resolve Service Remote IP address $ip_remote.\n"
	    unless Socket::inet_aton($ip_remote);
    }
    die $errors if $errors;

    $sets->Modified(1);
    $self->Store($wiz, 1);
    my $cmd = $prefs->{'isdn-prefs-upadatecmd'};
    my $cmdp = $cmd; $cmdp =~ s/\ .*$//g;
    system($cmd) if(-x $cmdp);

    $self->Wizard::Examples::ISDN::Action_Reset($wiz);
}

sub Action_Reset {
    my($self, $wiz) = @_;
    my ($prefs) = $self->init();

    my $cfile = $prefs->{'isdn-prefs-cfile'};
    $self->{'settings'} = Wizard::SaveAble::ShellVars->new('file' => $cfile, 'load' => 1, 'prefix' => 'isdn-settings-');
    $self->Store($wiz);

    return $self->ShowMe($wiz, $self->{'settings'});
}










