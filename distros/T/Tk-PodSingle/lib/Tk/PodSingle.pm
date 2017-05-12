package Tk::PodSingle;
our $VERSION = '1.01';

=head1 NAME

Tk::PodSingle - Pod browser toplevel widget for single pod files

=head1 DESCRIPTION

This module inherits Tk::Pod and slightly changes its' features by removing menu entries
(and bindings) that pertain to opening a different pod file.

It is suitable for when you want to only display a single pod file
or a group of self-contained pod files. It hides access to the system's pod archive
and removes the options that allow opening a new pod file.

What it does not do is prevent going to a different pod file through a link
in the loaded pod file. This is why I kept the History menu intact.

The widget is created like this:

	use Tk::PodSingle;
	$Pod = $Parent->PodSingle(-file => $name);

Other than the removed menu entries and bindings, it behaves exactly as Tk::Pod does.

=head1 AUTHOR

Ken Prows (perl@xev.net)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

use base qw(Tk::Derived Tk::Pod);
use strict;

Construct Tk::Widget 'PodSingle';

sub Populate
{
 my ($w,$args) = @_;

 $args->{-tree} = 0;

 if ($w->Pod_Text_Module)
  {
   eval q{ require } . $w->Pod_Text_Module;
   die $@ if $@;
  }
 #if ($w->Pod_Tree_Module)
 # {
 #  eval q{ require } . $w->Pod_Tree_Module;
 #  die $@ if $@;
 # }
  
 # SUPER wont work here because it will use the Populate from Tk::Pod, which is wrong
 #$w->SUPER::Populate($args);
 $w->Tk::Toplevel::Populate($args); 

 #my $tree = $w->Scrolled($w->Pod_Tree_Widget,
 #			 -scrollbars => 'oso'.($Tk::platform eq 'MSWin32'?'e':'w')
 #			);
 #$w->Advertise('tree' => $tree);

 my $searchcase = 0;
 my $p = $w->Component($w->Pod_Text_Widget => 'pod', -searchcase => $searchcase)->pack(-expand => 1, -fill => 'both');
 $p->bind('<Double-1>', sub  { }); # disable double-click file loading
 $p->menu(undef); # disable right-click menu

 my $exitbutton = delete $args->{-exitbutton} || 0;

 # Experimental menu compound images:
 # XXX Maybe there should be a way to turn this off, as the extra
 # icons might be memory consuming...
 my $compound = sub { () };
 if ($Tk::VERSION >= 804 && eval { require Tk::ToolBar; 1 }) {
     $w->ToolBar->destroy;
     if (!$Tk::Pod::empty_image_16) { # XXX multiple MainWindows?
	 $Tk::Pod::empty_image_16 = $w->MainWindow->Photo(-data => <<EOF);
R0lGODlhEAAQAIAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgABACwA
AAAAEAAQAAACDoyPqcvtD6OctNqLsz4FADs=
EOF
     }
     $compound = sub {
	 if (@_) {
	     (-image => $_[0] . "16", -compound => "left");
	 } else {
	     (-image => $Tk::Pod::empty_image_16, -compound => "left");
	 }
     };
 }

 my $menuitems =
 [

  [Cascade => '~File', -menuitems =>
   [
    #[Button => '~Open File...', '-accelerator' => 'F3',
    # '-command' => ['openfile',$w],
    # $compound->("fileopen"),
    #],
    #[Button => 'Open ~by Name...', '-accelerator' => 'Ctrl+O',
    # '-command' => ['openpod',$w,$p],
    # $compound->(),
    #],
    #[Button => '~New Window...', '-accelerator' => 'Ctrl+N',
    # '-command' => ['newwindow',$w,$p],
    # $compound->(),
    #],
    #[Button => '~Reload',    '-accelerator' => 'Ctrl+R',
    # '-command' => ['reload',$p],
    # $compound->("actreload"),
    #],
    #[Button => '~Edit',      '-command' => ['edit',$p],
    # $compound->("edit"),
    #],
    #[Button => 'Edit with p~tked', '-command' => ['edit',$p,'ptked'],
    # $compound->(),
    #],
    [Button => '~Print'. ($p->PrintHasDialog ? '...' : ''),
     '-accelerator' => 'Ctrl+P', '-command' => ['Print',$p],
     $compound->("fileprint"),
    ],
    [Separator => ""],
    [Button => '~Close',     '-accelerator' => 'Ctrl+W',
     '-command' => ['quit',$w],
     $compound->("fileclose"),
    ],
    ($exitbutton
     ? [Button => 'E~xit',   '-accelerator' => 'Ctrl+Q',
	'-command' => sub { $p->MainWindow->destroy },
	$compound->("actexit"),
       ]
     : ()
    ),
   ]
  ],

  #[Cascade => '~View', -menuitems =>
  # [
  #  [Checkbutton => '~Pod Tree', -variable => \$w->{Tree_on},
  #   '-command' => sub { $w->tree($w->{Tree_on}) },
  #   $compound->(),
  #  ],
  #  '-',
  #  [Button => "Zoom ~in",  '-accelerator' => 'Ctrl++',
  #   -command => ['zoom_in', $p],
  #   $compound->("viewmag+"),
  #  ],
  #  [Button => "~Normal",   -command => ['zoom_normal', $p],
  #   $compound->(),
  #  ],
  #  [Button => "Zoom ~out", '-accelerator' => 'Ctrl+-',
  #   -command => ['zoom_out', $p],
  #   $compound->("viewmag-"),
  #  ],
  # ]
  #],

  [Cascade => '~Search', -menuitems =>
   [
    [Button => '~Search',
     '-accelerator' => '/', '-command' => ['Search', $p, 'Next'],
     $compound->("viewmag"),
    ],
    [Button => 'Search ~backwards',
     '-accelerator' => '?', '-command' => ['Search', $p, 'Prev'],
     $compound->(),
    ],
    [Button => '~Repeat search',
     '-accelerator' => 'n', '-command' => ['ShowMatch', $p, 'Next'],
     $compound->(),
    ],
    [Button => 'R~epeat backwards',
     '-accelerator' => 'N', '-command' => ['ShowMatch', $p, 'Prev'],
     $compound->(),
    ],
    [Checkbutton => '~Case sensitive', -variable => \$searchcase,
     '-command' => sub { $p->configure(-searchcase => $searchcase) },
     $compound->(),
    ],
    #[Separator => ""],
    #[Button => 'Search ~full text', '-command' => ['SearchFullText', $p],
    # $compound->("filefind"),
    #],
    #[Button => 'Search FA~Q', '-command' => ['SearchFAQ', $w, $p],
    # $compound->(),
    #],
   ]
  ],

  [Cascade => 'H~istory', -menuitems =>
   [
    [Button => '~Back',    '-accelerator' => 'Alt-Left',
     '-command' => ['history_move', $p, -1],
     $compound->("navback"),
    ],
    [Button => '~Forward', '-accelerator' => 'Alt-Right',
     '-command' => ['history_move', $p, +1],
     $compound->("navforward"),
    ],
    [Button => '~View',    '-command' => ['history_view', $p],
     $compound->(),
    ],
    '-',
    [Button => 'Clear cache', '-command' => ['clear_cache', $p],
     $compound->(),
    ],
   ]
  ],

#  [Cascade => '~Help', -menuitems =>
#   [
#    # XXX restructure to not reference to tkpod
#    [Button => '~Usage...',       -command => ['help', $w]],
#    [Button => '~Programming...', -command => sub { $w->parent->Pod(-file=>'Tk/Pod.pm', -exitbutton => $w->cget(-exitbutton)) }],
#    [Button => '~About...', -command => ['about', $w]],
#    ($ENV{'TKPODDEBUG'}
#     ? ('-',
#	[Button => 'WidgetDump', -command => sub { $w->WidgetDump }],
#	(defined &Tk::App::Reloader::reload_new_modules
#	 ? [Button => 'Reloader', -command => sub { Tk::App::Reloader::reload_new_modules() }]
#	 : ()
#	),
#       )
#     : ()
#    ),
#   ]
#  ]
 ];

 my $mbar = $w->Menu(-menuitems => $menuitems);
 $w->configure(-menu => $mbar);
 $w->Advertise(menubar => $mbar);

 $w->Delegates('Menubar' => $mbar);
 $w->ConfigSpecs(
    -tree => ['METHOD', 'tree', 'Tree', 0],
    -exitbutton => ['PASSIVE', 'exitButton', 'ExitButton', $exitbutton],
    -background => ['PASSIVE'], # XXX see comment in Tk::More
    -cursor => ['CHILDREN'],
    'DEFAULT' => [$p],
 );

 {
  my $path = $w->toplevel->PathName;
  foreach my $mod (qw(Alt Meta))
   {
    $w->bind($path, "<$mod-Left>"  => [$p, 'history_move', -1]);
    $w->bind($path, "<$mod-Right>" => [$p, 'history_move', +1]);
   }

  #$w->bind($path, "<Control-minus>" => [$p, 'zoom_out']);
  #$w->bind($path, "<Control-plus>" => [$p, 'zoom_in']);
  #$w->bind($path, "<F3>" => [$w,'openfile']);
  #$w->bind($path, "<Control-o>" => [$w,'openpod',$p]);
  #$w->bind($path, "<Control-n>" => [$w,'newwindow',$p]);
  $w->bind($path, "<Control-r>" => [$p, 'reload']);
  $w->bind($path, "<Control-p>" => [$p, 'Print']);
  $w->bind($path, "<Control-w>" => [$w, 'quit']);
  $w->bind($path, "<Control-q>" => sub { $p->MainWindow->destroy })
      if $exitbutton;
 }

 $w->protocol('WM_DELETE_WINDOW',['quit',$w]);
}

1;
