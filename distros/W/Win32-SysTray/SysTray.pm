package Win32::SysTray;
$VERSION = '0.20';

=pod

=head1 NAME

Win32::SysTray

=head1 SYNOPSIS

	use strict;
	use Win32::SysTray;
	use File::Basename;
	use File::Spec::Functions qw[ catfile rel2abs updir ];
	
	my $tray = new Win32::SysTray (
		'icon' => rel2abs(dirname($0)).'\img\icon.ico',
		'single' => 1,
	) or exit 0;
	
	$tray->setMenu (
		"> &Test" => sub { print "Hello from the Tray\n"; },
		">-"	  => 0,
		"> E&xit" => sub { return -1 },
	); 
	
	$tray->runApplication;

=cut

=head1 DESCRIPTION

The Win32::SysTray module allows the programmer to create perl applications
that are stored in the Windows system tray.

=head1 AUTHOR

Andreas Mahnke

=cut

use strict;
use Win32 ();
use Win32::GUI qw(MB_ICONINFORMATION);
use Win32::Mutex;
use Carp;

=head1 Methods:

=head2 new

	creates a new object of the class
	
	parameters:
		name:    Name of the Tray Application (default -> 'MyTray')
		tooltip: Text to be displayed when moving the mouse over the tray icon (default -> name attribute)
		icon:    path to *.ico file to be used as icon for the tray (MANDATORY!)
		single:  only one running instance of the application is allowed
		
=cut


sub new {
	my $class = shift;
	my %opt = @_;
	my $self  = {
	  	caller  => caller(),
		popup   => undef,
		menu    => [
			"tray"   		=> "tray",
			" > E&xit"		=> "Exit",
		],
	};
	
	$self->{name}    = $opt{name} || 'MyTray';
	$self->{tooltip} = $opt{tooltip} || $self->{name};
	$self->{icon}	 = $opt{icon};
	$self->{single}  = $opt{single} || 0;
	
	if (! -f $self->{icon}) {
		croak "Error - please pass valid icon to constructor!\n";
	}
	
	if ($self->{single}) {
		$self->{mutex} = Win32::Mutex->new(0,$self->{name});
		if (! $self->{mutex}->wait(100)) {
			Win32::MsgBox("Another Instance of the Program already started.", MB_ICONINFORMATION, $self->{name});
			return undef;
		}
	}
	
	$self->{DummyWindow} = new Win32::GUI::Window(
		-left   => 1,
		-top    => 1,
		-width  => 0,
		-height => 0,
		-name   => "Main",
		-text   => $self->{name},
	);	
	
	$self->{trayicon} = new Win32::GUI::Icon($self->{icon});
	if (! $self->{trayicon}) {
		croak "Error - Could not load icon ($self->{icon})\n";
	} 
	
	$self->{popup} = Win32::GUI::MakeMenu(
		@{$self->{menu}}
	);
	
	$self->{Tray} = Win32::GUI::NotifyIcon->new($self->{DummyWindow},
			-name   => "SysTray",
			-icon   => $self->{trayicon},
			-tip    => $self->{tooltip},
	);
	

	no strict 'refs';
	*{"SysTray_Click"} = sub {
		my ($x, $y) = Win32::GUI::GetCursorPos();
		$self->{DummyWindow}->TrackPopupMenu($self->{popup}->{tray}, $x, $y);
		return(1);
	};
	
	*{"SysTray_RightClick"} = *{"SysTray_Click"};
	
	*{"Exit_Click"} = sub {
		return -1;
	};
	
	*{$self->{caller}."::SysTray_Click"} = *{"SysTray_Click"};
	*{$self->{caller}."::SysTray_RightClick"} = *{"SysTray_RightClick"};
	*{$self->{caller}."::Exit_Click"} = *{"Exit_Click"};
		
	bless($self,$class);
  
  return $self;	
}

=head2 setMenu

	sets the popup menu of the tray application which is dislayed when (right)clicking on the icon
	
	see synopsis for example of using
		
=cut

sub setMenu (@) {
	my $self  = shift;
	$self->{menu} = [@_];
	return 0 if (! $self->{menu});
	
	no strict 'refs';	
	for (my $i = 0; $i <= $#{$self->{menu}}; $i+=2) {
		*{$self->{caller}."::MenuItem".int($i/2 + 1)."_Click"} = $self->{menu}[$i+1];
		$self->{menu}[$i+1] = "MenuItem".int($i/2 + 1);
	}	
	unshift @{$self->{menu}}, ("tray" => "tray");
	
	$self->{popup} = Win32::GUI::MakeMenu(@{$self->{menu}});
}

=head2 runApplication

	run the application (invokes Win32::GUI::Dialog)
		
=cut

sub runApplication {
	my $self = shift;
	eval { Win32::GUI::Dialog() };
}

return 1;
