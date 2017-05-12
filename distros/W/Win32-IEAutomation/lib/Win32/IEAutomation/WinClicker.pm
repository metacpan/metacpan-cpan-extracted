package Win32::IEAutomation::WinClicker;

use strict;
use vars qw($VERSION $warn);
$VERSION = '0.5';

sub new {
	my $class = shift;
	my %options = @_;
	if (exists $options{warnings}){
		$warn = $options{warnings};
	}
	my $self  = { };
	$self->{autoit} = Win32::OLE->new("AutoItX3.Control");
	unless ($self->{autoit}){
		my $autoitx_dll = find_autoitx_dll();
		if ($autoitx_dll){
			register_autoitx_dll($autoitx_dll);
			$self->{autoit} = Win32::OLE->new("AutoItX3.Control") || die "Could not start AutoItX3 Control through OLE\n";
		}else{
			print "ERROR: AutoItX3.dll is not present in the module\n";
			exit;
		}
	}
	$self = bless ($self, $class);
	return $self;
}

sub find_autoitx_dll{
	foreach my $libdir (@INC){
		my $dllpath = "$libdir/Win32/IEAutomation/AutoItX3.dll";
		if (-e  $dllpath){
			return $dllpath;
		}
	}
}

sub register_autoitx_dll{
	my $dll = shift;
	system ("regsvr32 /s $dll");
}

sub push_security_alert_yes{
	my ($self, $wait) = @_;
	$wait = 5 unless $wait;
	my $window = $self->{autoit}->WinWait("Security Alert", "", $wait);
	if ($window){
		$self->{autoit}->WinActivate("Security Alert");
		$self->{autoit}->Send('!y');
	}else{
		print "WARNING: No Security Alert dialog is present. Function push_security_alert_yes is timed out.\n" if $warn;
	}
}

sub push_confirm_button_ok{
	my ($self, $title, $wait) = @_;
	$wait = 5 unless $wait;
	my $window = $self->{autoit}->WinWait($title, "", $wait);
	if ($window){
		$self->{autoit}->WinActivate($title);
		$self->{autoit}->Send('{ENTER}');
	}
}

sub push_button_yes{
	my ($self, $title, $wait) = @_;
	$wait = 5 unless $wait;
	my $window = $self->{autoit}->WinWait($title, "", $wait);
	if ($window){
		$self->{autoit}->WinActivate($title);
		$self->{autoit}->Send('!y');
	}else{
		print "WARNING: No dialog is present with title: $title. Function push_button_yes is timed out.\n" if $warn;
	}
}

sub push_confirm_button_cancle{
	my ($self, $title, $wait) = @_;
	$wait = 5 unless $wait;
	my $window = $self->{autoit}->WinWait($title, "", $wait);
	if ($window){
		$self->{autoit}->WinActivate($title);
		$self->{autoit}->Send('{ESCAPE}');
	}
}

sub logon{
	my ($self, $title, $user, $password, $wait) = @_;
	$wait = 5 unless $wait;
	my $window = $self->{autoit}->WinWait($title, "", $wait);
	if ($window){
		$self->{autoit}->WinActivate($title);
		$self->{autoit}->Send($user);
		$self->{autoit}->Send('{TAB}');
		$self->{autoit}->Send($password);
		$self->{autoit}->Send('{ENTER}');
	}else{
		print "WARNING: No logon dialog is present with title \'$title\'. Function logon is timed out.\n" if $warn;
	}
}

sub maximize_ie{
	my ($self, $title) = @_;
	$self->{autoit}->AutoItSetOption("WinTitleMatchMode", 2);
	$self->{autoit}->WinSetState("Microsoft Internet Explorer", "", $self->{autoit}->SW_MAXIMIZE);
	$self->{autoit}->AutoItSetOption("WinTitleMatchMode", 1);
}
	

1;
__END__ 
	
	