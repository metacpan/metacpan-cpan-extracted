package Tk::Program;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision           = '$Revision: 1.7 $';
our $CheckinDate        = '$Date: 2003/06/20 13:53:18 $';
our $CheckinUser        = '$Author: xpix $';
# we need to clean these up right here
$Revision               =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
#-------------------------------------------------
#-- package Tk::DBI::Tree -----------------------
#-------------------------------------------------

use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Tk::MainWindow);
use strict;

use IO::File;
use Tk::Balloon;
use Tk::Getopt;
use Tk::Splashscreen; 
use Tk::ToolBar;
use Tk::DialogBox;
use Tk::ROText;

use Data::Dumper;

Construct Tk::Widget 'Program';

# ------------------------------------------
sub Populate {
# ------------------------------------------
	my ($obj, $args) = @_;

	$obj->{app} 		= delete $args->{'-app'} 	|| 'Program';
	$obj->{cfg} 		= delete $args->{'-cfg'} 	|| sprintf( '%s/.%s.cfg', ($ENV{HOME} ? $ENV{HOME} : $ENV{HOMEDRIVE}.$ENV{HOMEPATH}), $obj->{app} );
	$obj->{add_prefs} 	= delete $args->{'-add_prefs'};
	$obj->{about} 		= delete $args->{'-about'};
	$obj->{help} 		= delete $args->{'-help'}	|| $0;

	$obj->SUPER::Populate($args);
	
	$obj->ConfigSpecs(
		-set_logo	=> ["METHOD", 	"set_logo", 	"Set_Logo", 	undef],
		-set_icon	=> ["METHOD", 	"set_icon", 	"Set_Icon", 	undef],

		-init_menu	=> ["METHOD", 	"init_menu", 	"Init_Menu", 	undef],
		-init_prefs	=> ["METHOD", 	"init_prefs", 	"Init_Prefs", 	undef],
		-init_main	=> ["METHOD", 	"init_main", 	"Init_Main", 	undef],
		-init_status	=> ["METHOD", 	"init_status", 	"Init_Status", 	undef],

		-add_status	=> ["METHOD", 	"add_status", 	"Add_Status", 	undef],
		-add_toolbar	=> ["METHOD", 	"add_toolbar", 	"Add_Toolbar", 	undef],

		-config		=> ["METHOD", 	"config", 	"Config", 	undef],
		-skin		=> ["METHOD", 	"skin", 	"Skin", 	undef],
		-prefs		=> ["METHOD", 	"prefs", 	"Prefs", 	undef],
		-splash		=> ["METHOD", 	"splash", 	"Splash", 	undef],
		-exit		=> ["METHOD", 	"exit", 	"Exit", 	undef],

		-exit_cb	=> ["CALLBACK",	"exit_cb", 	"Exit_Cb", 	undef],
           	);
	
	$obj->bind( "<Configure>", sub{ $obj->{opt}->{'Geometry'} = $obj->geometry } );
	$obj->bind( "<Destroy>", sub{ $obj->{optobj}->save_options() } );
	$obj->bind( "<Double-Escape>", sub { $obj->exit } );

	$obj->Icon('-image' => $obj->Photo( -file => $obj->{icon} ) ) if($obj->{icon});
	$obj->optionAdd("*tearOff", "false");
	$obj->configure(-title 	=> $obj->{app});

	$obj->init_menu();
	$obj->init_main();
	$obj->init_status();

	$obj->packall();

	$obj->Advertise('menu' => $obj->{menu});
	$obj->Advertise('main' => $obj->{main});
	$obj->Advertise('status' => $obj->{status});

	$obj->init_prefs();
	$obj->update;
}

# ------------------------------------------
sub exit {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	$obj->Callback(-exit_cb);
	$obj->{optobj}->save_options();
	exit; 
}

# ------------------------------------------
sub set_icon {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	$obj->{icon} = shift || return $obj->{icon};
	
	my $image = $obj->{icon};
	$image = $obj->Photo( -file => $obj->{icon} )
			unless(ref $obj->{icon});
	$obj->Icon('-image' => $image );
}


# ------------------------------------------
sub set_logo {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	$obj->{logo} = shift || $obj->{logo};

	my $image = $obj->{logo};
	$image = $obj->Photo( -file => $obj->{logo} )
			unless(ref $obj->{logo});
	return $image;
}

# ------------------------------------------
sub help {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	unless(defined $obj->{pod_text}) {
		$obj->{pod_text} = `pod2text $0`;
	}	
	$obj->{pod_window}->{dialog} = my $dialog = $obj->DialogBox(
		-title          => sprintf('Help for %s:', $obj->{app}),
		-buttons        => [ 'Ok' ],
		-default_button => 'Ok'
	);
	my $e = $dialog->add(
		'ROText',
	)->pack;
	$e->insert('end', $obj->{pod_text});

	my $answer = $dialog->Show;
}

# ------------------------------------------
sub about {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $text = shift || $obj->{about};
	
	$obj->splash(4000, $text);
}

# ------------------------------------------
sub splash {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $mseconds = shift || 0;
	my $text = shift;	
        
	if($obj->{splash} and ! $mseconds) {
		$obj->{splash}->Destroy();
	} elsif(defined $obj->{logo} or defined $text) {
		$obj->{splash} = $obj->Splashscreen;

		$obj->{splash}->Label(
			-image => $obj->set_logo,
			)->pack(); 

		$obj->{splash}->Label(
			-textvariable => $text,  
			)->pack()	if($text); 

		$obj->{splash}->Splash();
		$obj->{splash}->Destroy( $mseconds );
		return $obj->{splash};
	} else {
		return error('Can\'t find a logo. Please define first -set_logo!');
	}

}

# ------------------------------------------
sub prefs {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	return error('Please call Tk::Program::init_prefs before call prefs')
		unless defined $obj->{optobj};
	my $w = $obj->{optobj}->option_editor(
		$obj,
		-buttons => [qw/ok save cancel defaults/],
		-delaypagecreate => 0,
		-wait	=> 1,
		-transient => $obj,
	);
}

# ------------------------------------------
sub packall {
# ------------------------------------------
	my $obj = shift || return error('No Object');

	$obj->{status}	->pack( -side => 'bottom', -fill => 'x');
	$obj->{main}	->pack( -side => 'top', -expand => 1, -fill => 'both');
}

# ------------------------------------------
sub init_main {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	$obj->{main} = shift || $obj->Frame();

	return $obj->{main};
}

# ------------------------------------------
sub init_status {
# ------------------------------------------
	my $obj = shift || return error('No Object');
        return $obj->{status} if(defined $obj->{status});

	# Statusframe
	$obj->{status} = $obj->Frame();

	return $obj->{status};
}

# ------------------------------------------
sub config {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $name = shift;
	my $cfg = shift;

	$obj->{'UserCfg'} = {}
		unless(ref $obj->{'UserCfg'});

	return $obj->{'UserCfg'}->{$name}
		unless( $cfg );	

	$obj->{'UserCfg'}->{$name} = $cfg;	
	$obj->{opt}->{'UserCfg'} = Data::Dumper->Dump([$obj->{'UserCfg'}]);
	$obj->{optobj}->save_options;
	return $obj->{'UserCfg'}->{$name};
}

# ------------------------------------------
sub add_toolbar {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $typ = shift || return error('No Type!');
	my @par = @_;

	unless(defined $obj->{toolbar}) {
		$obj->{toolbar} = $obj->ToolBar(
			-movable => 1,
			-side => 'top',
			);
	}
	$obj->{toolbar}->$typ(@par);
}


# ------------------------------------------
sub add_status {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $name = shift || return error('No Name');
	my $value = shift || return error('No Value');
	my $w;

        return $obj->{status}->{$name} 
        	if(defined $obj->{status}->{$name});
	
	$obj->{status} = $obj->init_status()
		unless(defined $obj->{status});

	if(ref $$value) {
		$w = $$value->pack(
				-side => 'left', 
				-fill => 'x', 
				-expand => 1,
				);
	} else {
		$w = $obj->{status}->Label(
			-textvariable => $value,
			-relief => 'sunken',
			-borderwidth => 2,
			-padx => 5,
			-anchor => 'w')->pack(
				-side => 'left', 
				-fill => 'x', 
				-expand => 1,
				);
	}
	$obj->Advertise('status_'.$name => $w); 
}

# ------------------------------------------
sub init_prefs {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	return $obj->{optobj} if defined $obj->{optobj}; 

	my $optionen = shift || $obj->get_prefs($obj->{add_prefs});
	my %opts;
	$obj->{opt} = \%opts;
		
	$obj->{optobj} = Tk::Getopt->new(
			-opttable => $optionen,
			-options => \%opts,
			-filename => $obj->{cfg}
		);
	$obj->{optobj}->set_defaults;
	$obj->{optobj}->load_options;
	if (! $obj->{optobj}->get_options) {
	    die $obj->{optobj}->usage;
	}
	$obj->{optobj}->process_options;
	return $obj->{opt};
}

# ------------------------------------------
sub get_prefs {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $to_add = shift || [];

	if(! ref $to_add and -e $to_add) {
		$to_add = $obj->load_config($to_add);		
	}


	my $default = 
	[
		'Display',
		['Geometry', '=s', '640x480',
		    'help' => 'Set geometry from Programm',
		    'subtype' => 'geometry',
		    'callback' => sub {    	
				if (my $geo = $obj->{opt}->{'Geometry'}) {
					$obj->geometry($geo);
					$obj->update;
				}
		     },
   		], 
		['Color', '=s', 'gray85',
		    'help' => 'Set color palette to Program',
		    'subtype' => 'color',
			'callback' => sub {    	
				if (my $col = $obj->{opt}->{'Color'}) {
					$obj->setPalette($col);
					$obj->update;
				}
			},
   		], 
   		['Font', '=s', 'Helvetica 10 normal',
			'callback-interactive' => sub{
					$obj->messageBox(
						-message => 'Please restart program to apply changes!', 
						-title => 'My title', 
						-type => 'Ok', 
						-default => 'Ok');
					$obj->{optobj}->save_options();
			},
			'callback' => sub {    	
				if (my $font = $obj->{opt}->{'Font'}) {
					$obj->optionAdd("*font", $font);
					$obj->optionAdd("*Font", $font);
					$obj->Walk( 
						sub { 
							#XXX Uiee, böser Hack ;-)
							if( exists $_[0]->{Configure}->{'-font'} ) {
								$_[0]->configure(-font => $font) 
							} 
						} );
					$obj->update;
				}
			},
			'subtype' => 'font',
			'help' => 'Default font',
		],
		['UserCfg', '=s', undef,
		 'nogui' => 1,
		 'callback' => sub {    	
			if (my $str = $obj->{opt}->{'UserCfg'}) {
				my $VAR1;
				$obj->{'UserCfg'} = eval($str);
				return error($@) if($@);
			}
		 },
   		], 
		@$to_add
	];
	return $default;
}

# ------------------------------------------
sub init_menu {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	return $obj->{menu} if defined $obj->{menu}; 
	my $menuitems = shift || [
		[Cascade => "File", -menuitems =>
			[
				[Button => "Prefs", 	-command => sub{ $obj->prefs() } ],
				[Button => "Quit", 	-command => sub{ $obj->exit }],
			]	
		],	
		
		
		[Cascade => "Help", -menuitems =>
			[
				[Button => "Help", -command => sub{ $obj->help() } ],
				[Button => "About", -command => sub{ $obj->about() } ],
			]	
		],
	];

	# Menu
	if ($Tk::VERSION >= 800) {
		$obj->{menu} = $obj->Menu(
			-menuitems => $menuitems,
			-tearoff => 0,
			-font => $obj->{opt}->{Font},
			);
		$obj->configure(-menu => $obj->{menu});
	} else {
		$obj->{menu} = $obj->Menubutton(-text => "Pseudo menubar",
				 	 -menuitems => $menuitems)->pack;
	}

	return $obj->{menu};
}

# ------------------------------------------
sub load_config {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $file = shift || return error('No Configfile');

	my @VAR = eval( _load_file($file) ); 

	return \@VAR;
}

#--------------------------------------------------------
sub _load_file {
#--------------------------------------------------------
	my $file = shift || die "Kein File bei Loader $!";
	my $fh = IO::File->new("< $file") 
	    or return debug("Can't open File $file $! ");
	my $data;
	while ( defined (my $l = <$fh>) ) {
	        $data .= $l;
	}
	$fh->close;
	return $data;
}


#-------------------------------------------------
sub error {
#-------------------------------------------------
	my ($package, $filename, $line, $subroutine, $hasargs,
    		$wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
	my $msg = shift || return undef;
	warn sprintf("ERROR in %s:%s #%d: %s",
		$package, $subroutine, $line, sprintf($msg, @_));
	return undef;
}

1;

=head1 NAME

Tk::Program - MainWindow Widget with special features.

=head1 SYNOPSIS

	use Tk;
	use Tk::Program;
	
	my $top = Tk::Program->new(
		-app => 'xpix',
		-cfg => './testconfig.cfg',
		-set_icon => './icon.gif',
		-set_logo => './logo.gif',
		-about => \$about,
		-help => '../Tk/Program.pm',
		-add_prefs => [
			'Tools',
			['acrobat', '=s', '/usr/local/bin/acroread',
			{ 'subtype' => 'file',
			'help' => 'Path to acrobat reader.'
			} ],
		],
	);
	
	MainLoop;

=head1 DESCRIPTION

This  is  a  megawidget to  display  a  program window. I was tired of creating 
menues, prefs dialogues, about dialogues,... for every new application..... I 
searched for a generic way wrote this module. This modules stores the main 
window's font, size and position and embodies the fucntions from the 
Tk::Mainwindow module.


=head1 WIDGET-SPECIFIC OPTIONS

=head2 -app => $Applikation_Name

Set a Application name, default is I<Program>

=head2 -set_icon => $Path_to_icon_image

Set a Application Icon, please give this in 32x32 pixel and in gif format.

=head2 -cfg => $path_to_config_file;

Set the path to the config file, default:

   $HOME/.$Application_Name.cfg

=head2 -add_prefs => $arrey_ref_more_prefs or $path_to_cfg_file;

This allows to include your Preferences into default:

   -add_prefs => [
	  'Tools',
	   ['acrobat', '=s', '/usr/local/bin/acroread',
	   { 'subtype' => 'file',
	    'help' => 'Path to acrobat reader.'
	   } ],
   ],

Also you can use a config file as parameter:

   -add_prefs => $path_to_cfg_file;

=head2 -set_logo => $image_file;

One logo for one program  This picture will be use from the Splash and About
Method.
Carefully, if  not defined in the Splash then an error is returned.

=head2 -help => $pod_file;

This includes a Help function as a topwindow with Poddisplay. Look for more
Information on Tk::Pod. Default is the program source ($0).


=head1 METHODS

These are the methods you can use with this Widget.

=head2 $top->init_prefs( I<$prefs> );

This will initialize the user or default preferences. It returns a
reference  to the options hash. More information about the prefsobject look at
B<Tk::Getopt> from
slaven. The Program which uses  this Module has a  configuration dialog in tk
and on the commandline with the following standard options:

=over 4

=item I<Geometry>: Save the geometry (size and position) from mainwindow.

=item I<Font>: Save the font from mainwindow.

=item I<Color>: Save the color from mainwindow.

=back

In the Standard menu you find the preferences dialog under I<File - Prefs>.

I.E.:

	my $opt = $top->init_prefs();
	print $opt->{Geometry};
	....

=head2 $top->prefs();

Display the Configuration dialog.

=head2 $top->set_icon( I<$path_to_icon> );

Set a new Icon at runtime.

=head2 $top->set_logo( I<$path_to_logo> );

Set a new Logo at runtime.


=head2 $top->init_menu( I<$menuitems> );

Initialize the user or default Menu and return the Menuobject. You can set
your own menu with the first parameter. the other (clever) way: you add your own
menu to the standart menu.
I.E:

	# New menu item
	my $edit_menu = $mw->Menu();
	$edit_menu->command(-label => '~Copy', -command => sub{ print "Choice Copy\n" });
	$edit_menu->command(-label => '~Cut', -command => sub{ print "Choice Cut\n" });
	# ....
	
	my $menu = $mw->init_menu();
	$menu->insert(1, 'cascade', -label => 'Edit', -menu => $edit_menu);


=head2 $top->splash( I<$milliseconds> );

Display the  Splashscreen for  (optional) x  milliseconds. The  -set_logo option
is
required to initialize with a Picture. Also you can use this as Switch,
without any Parameter:

	$top->splash(); # Splash on
	....
	working
	...
	$top->splash(); # Splash off

=head2 $top->config( I<Name>, I<$value> );

You have data from your widgets and you will make this data persistent? No Problem:

	$top->config( 'Info', $new_ref_with_importand_informations )
	...
	my $info = $top->config( 'Info' );	

=head2 $top->add_status( I<$name>, I<\$value> or I<\$widget> );

Display a Status text field or a widget in the status bar, if you first call 
add_status then will Tk::Program create a status bar:

	my $widget = $mw->init_status()->Entry();
	$widget->insert('end', 'Exampletext ....');
	
	my $status = {
		One => 'Status one',
		Full => 'Full sentence ....',
		Time => sprintf('%d seconds', time),
		Widget => $widget, 
	};
	
	# Add Status fields
	foreach (sort keys %$status) {
		$mw->add_status($_, \$status->{$_}) ;
	}

=head2 $top->add_toolar( I<$typ>, I<$options> );

Display the ToolbarWidget at first call and include the Widget ($typ) with options ($options):

	# Add Button to toolbar
	$mw->add_toolbar('Button', 
		-text  => 'Button', 
		-tip   => 'tool tip', 
		-command => sub { print "hi\n" });
	$mw->add_toolbar('Label', -text  => 'Label');
	$mw->add_toolbar('separator');

Look for more Information on Tk::ToolBar.

=head2 $top->exit( );

Close the program, you can include your code (before call the exit command) with:

	...
	$mw->configure(-exit_cb => sub{ .... })
	$mw->exit;

=head1 ADVERTISED WIDGETS

You can use the advertise widget with the following command '$top->Subwidget('name_from_adv_widget')'.

=head2 B<menu>: Menubar

=head2 B<main>: Mainframe

=head2 B<status>: Statusframe

=head2 B<status_I<name>>: StatusEntry from $top->add_status

=head1 BINDINGS

=head2 I<Double-Escape>: Exit the Programm

=head1 CHANGES

  $Log: Program.pm,v $
  Revision 1.7  2003/06/20 13:53:18  xpix
  ! wrong english in font dialog ;-)

  Revision 1.6  2003/06/20 12:52:27  xpix
  ! change from Tk::Pod to standart way with ROText

  Revision 1.5  2003/06/06 16:48:11  xpix
  * add toolbar function
  ! liitle bugfix in change font

  Revision 1.4  2003/06/06 12:56:03  xpix
  * correct docu, thanks on susy ;-)

  Revision 1.3  2003/06/05 15:32:26  xpix
  * with new Module Tk::Program
  ! unitialized values in tm2unix

  Revision 1.2  2003/06/05 12:51:56  xpix
  ! add better docu
  * add help function

  Revision 1.1  2003/06/04 17:14:35  xpix
  * New Modul for standart way to build a Programwindow.

=head1 AUTHOR

Copyright (C) 2003 , Frank (xpix) Herrmann. All rights reserved.

http://xpix.dieserver.de

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

Tk, Tk::MainWindow