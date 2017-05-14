#!/usr/local/bin/perl -w

use lib '../.';

use strict;
use Carp;
use Tk;
use Tk::Graph;

my %data;
my $typ = 'Bars';
my $field = 'pctcpu';


# Dump all the information
# in the current process table
use Proc::ProcessTable;
my $t 	= Proc::ProcessTable->new;
my $mw 	= MainWindow->new;

my $cc = $mw->Graph(
	-type		=> $typ,
	-borderwidth	=> 2,
	-title		=> $field,
	-titlecolor	=> 'Brown',
	-yformat	=> '%2.2f',

#	-ylabel		=> 'cpu',
#	-xlabel		=> 'seconds',

        -barwidth 	=> 15,
	-padding	=> [20,20,20,100],	# Padding [top, right, buttom, left]
	-linewidth	=> 1,
	-shadow		=> 'gray50',
	-shadowdepth	=> 3,
	-maxmin		=> 1,
	-look		=> 50,
	-balloon	=> 1,
	-legend		=> 1,
	)->pack(-expand => 1, -fill => 'both');

# Create Menu
&menu($mw, $t, $cc);

# Daten holen und dem Widget zuschieben
refresh(\%data, $cc, $field);

# ... und das alle X Sekunden
NOCHMA:
$mw->after(5000, sub{ 
	&refresh(\%data, $cc, $field);
	goto NOCHMA;
} );

MainLoop;
exit;

# Subs ----------------------------------
sub set3d {
	my $val = shift || 0;
	$cc->configure(-threed => $val);
}

sub setdisplay {
	$typ = shift;
	$cc->configure(-type => $typ);
}

sub setprocess {
	$field = shift || $field;
	$cc->configure(-title => $field);
	$cc->clear;
}

sub menu {
	my $top = shift || die;
	my $t 	= shift || die;
	my $cc 	= shift || die;

	# Fields
	my @fields = $t->fields;
	@fields = sort grep(! /^$/, @fields);

	my @menu_process;
	foreach my $fd (@fields) {
		push(@menu_process, [Radiobutton => $fd, -variable => \$field, -command => [\&setprocess, $fd]]);
	}

	my $menuitems = 
	    [
	
	     [Cascade => "File", -menuitems =>
	      [
	       [Button => "Quit", -command => \&quitapp],
	      ]
	     ],
	
	     [Cascade => "View", -menuitems =>
	      [
	       [Radiobutton => "~Bars",  -variable => \$typ, -command => [\&setdisplay, 'Bars'] ],
	       [Radiobutton => "~HBars", -variable => \$typ, -command => [\&setdisplay, 'Hbars']],
	       [Radiobutton => "~Circle", -variable => \$typ, -command => [\&setdisplay, 'Circle']],
	       [Radiobutton => "~Line", -variable => \$typ, -command => [\&setdisplay, 'Line']],
	       [Cascade => "Type", -menuitems =>
		[
		  @menu_process,
		]	
	       ],
	     [Cascade => "~3d", -menuitems =>
		[
		 [Button => "Off", -command => [\&set3d, 0] ],
		 [Button => "3", -command => [\&set3d, 3] ],
		 [Button => "5", -command => [\&set3d, 5] ],
		 [Button => "7", -command => [\&set3d, 7] ],
		 [Button => "10", -command => [\&set3d, 10] ],
		]
	       ], 

	      ]
	     ],
	    ];
	
	    if ($Tk::VERSION >= 800) {
		my $menubar = $top->Menu(-menuitems => $menuitems);
		$top->configure(-menu => $menubar);
	    } else {
		$top->Menubutton(-text => "Pseudo menubar",
				 -menuitems => $menuitems)->pack;
	    }
}

sub quitapp {
	exit;
}

sub refresh {
	my $data = shift 	|| warn 'Keine Daten!';
	my $widget = shift 	|| warn 'Kein Widget!';
	my $field = shift 	|| return;

	foreach my $p (@{$t->table}) {
		if($p->{ $field }>0) {
			$$data{$p->{fname}} = $p->{$field};
		} else {
			delete $data->{$p->{fname}}
				if(defined $data->{$p->{fname}});
		}
	}   
	$widget->set($data);
}

         
