package Tk::Pod;
use strict;
use Tk ();
use Tk::Toplevel;

use vars qw($VERSION $DIST_VERSION @ISA);
$VERSION = '5.41';
$DIST_VERSION = '0.9943';

@ISA = qw(Tk::Toplevel);

Construct Tk::Widget 'Pod';

my $openpod_history;
my $searchfaq_history;

sub Pod_Text_Widget { "PodText" }
sub Pod_Text_Module { "Tk::Pod::Text" }

sub Pod_Tree_Widget { "PodTree" }
sub Pod_Tree_Module { "Tk::Pod::Tree" }

sub Populate
{
 my ($w,$args) = @_;

 if ($w->Pod_Text_Module)
  {
   eval q{ require } . $w->Pod_Text_Module;
   die $@ if $@;
  }
 if ($w->Pod_Tree_Module)
  {
   eval q{ require } . $w->Pod_Tree_Module;
   die $@ if $@;
  }

 $w->SUPER::Populate($args);

 my $tree = $w->Scrolled($w->Pod_Tree_Widget,
			 -scrollbars => 'oso'.($Tk::platform eq 'MSWin32'?'e':'w')
			);
 $w->Advertise('tree' => $tree);

 my $searchcase = 0;
 my $p = $w->Component($w->Pod_Text_Widget => 'pod', -searchcase => $searchcase)->pack(-expand => 1, -fill => 'both');

 my $exitbutton = delete $args->{-exitbutton} || 0;

 # Experimental menu compound images:
 # XXX Maybe there should be a way to turn this off, as the extra
 # icons might be memory consuming...
 my $compound = sub { ($_[0]) };
 if ($Tk::VERSION >= 800 && eval { require Tk::ToolBar; 1 }) {
     $w->ToolBar->destroy; # hack to load images
     if (!$Tk::Pod::empty_image_16) { # XXX multiple MainWindows?
	 $Tk::Pod::empty_image_16 = $w->MainWindow->Photo(-data => <<EOF);
R0lGODlhEAAQAIAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgABACwA
AAAAEAAQAAACDoyPqcvtD6OctNqLsz4FADs=
EOF
     }
     if ($Tk::VERSION >= 804) {
	 # Tk804 has native menu item compounds
	 $compound = sub {
	     my($text, $image) = @_;
	     if ($image) {
		 ($text, -image => $image . "16", -compound => "left");
	     } else {
		 ($text, -image => $Tk::Pod::empty_image_16, -compound => "left");
	     }
	 };
     } elsif (eval { require Tk::Compound; 1 }) {
	 # For Tk800 we have to create our own compounds using Tk::Compund
	 # get the default font (taken from bbbike):
	 my $std_font = $w->optionGet('font', 'Font');
	 if (!defined $std_font || $std_font eq '') {
	     my $l = $w->Label;
	     $std_font = $l->cget(-font);
	     $l->destroy;
	 }
	 my %std_font = $w->fontActual($std_font);
	 # create an underlined font which matches the default font
	 my $underline_font = join(" ", map { "{" . $std_font{$_} . "}" } qw(-family -size -weight -slant));
	 $underline_font .= " overstrike" if $std_font{-overstrike};
	 $underline_font .= " underline";
	 $compound = sub {
	     my($text, $image) = @_;
	     my $c = $w->MainWindow->Compound; # XXX multiple MainWindows?
	     if ($image) {
		 $c->Image(-image => $image."16");
	     } else {
		 $c->Image(-image => $Tk::Pod::empty_image_16);
	     }
	     $c->Space(-width => 4);
	     my($text_before, $underlined_text, $text_after) = $text =~ /^(.*)~(.)(.*)/;
	     if (defined $underlined_text) {
		 $c->Text(-text => $text_before) if $text_before ne "";
		 $c->Text(-text => $underlined_text, -font => $underline_font);
		 $c->Text(-text => $text_after) if $text_after ne "";
	     } else {
		 $c->Text(-text => $text);
	     }
	     ($text, -image => $c);
	 };
     }
 }

 my $menuitems =
 [

  [Cascade => '~File', -menuitems =>
   [
    [Button => $compound->('~Open File...', "fileopen"),
     '-accelerator' => 'F3',
     '-command' => ['openfile',$w],
    ],
    [Button => $compound->('Open ~by Name...'),
     '-accelerator' => 'Ctrl+O',
     '-command' => ['openpod',$w,$p],
    ],
    [Button => $compound->('~New Window...'),
     '-accelerator' => 'Ctrl+N',
     '-command' => ['newwindow',$w,$p],
    ],
    [Button => $compound->('~Edit', "edit"),
     '-command' => ['edit',$p],
    ],
    [Button => $compound->('Edit with p~tked'),
     '-command' => ['edit',$p,'ptked'],
    ],
    [Button => $compound->('~Print'. ($p->PrintHasDialog ? '...' : ''), "fileprint"),
     '-accelerator' => 'Ctrl+P',
     '-command' => ['Print',$p],
    ],
    [Separator => ""],
    [Button => $compound->('~Close', "fileclose"),
     '-accelerator' => 'Ctrl+W',
     '-command' => ['quit',$w],
    ],
    ($exitbutton
     ? [Button => $compound->('E~xit', "actexit"),
	'-accelerator' => 'Ctrl+Q',
	'-command' => sub { $p->MainWindow->destroy },
       ]
     : ()
    ),
   ]
  ],

  [Cascade => '~View', -menuitems =>
   [
    [Checkbutton => $compound->('Pod ~Tree'),
     '-variable' => \$w->{Tree_on},
     '-command' => sub { $w->tree($w->{Tree_on}) },
    ],
    '-',
    [Button => $compound->("Zoom ~in", "viewmag+"),
     '-accelerator' => 'Ctrl++',
     '-command' => [$w, 'zoom_in'],
    ],
    [Button => $compound->("~Normal"),
     '-command' => [$w, 'zoom_normal'],
    ],
    [Button => $compound->("Zoom ~out", "viewmag-"),
     '-accelerator' => 'Ctrl+-',
     '-command' => [$w, 'zoom_out'],
    ],
    '-',
    [Button => $compound->('~Reload', "actreload"),
     '-accelerator' => 'Ctrl+R',
     '-command' => ['reload',$p],
    ],
    [Button => $compound->("~View source"),
     '-accelerator' => 'Ctrl+U',
     '-command' => ['view_source',$p],
    ],
    '-',
    [Button => $compound->('Pod on ~search.cpan.org'),
     '-command' => sub {
	 require Tk::Pod::Util;
	 my $url = $p->{pod_title};
	 eval {
	     require URI::Escape;
	     $url = URI::Escape::uri_escape($url);
	 };
	 Tk::Pod::Util::start_browser("http://search.cpan.org/perldoc?" . $url);
     },
    ],
    [Button => $compound->('Pod on ~metacpan.org'),
     '-command' => sub {
	 require Tk::Pod::Util;
	 my $url = $p->{pod_title};
	 eval {
	     require URI::Escape;
	     $url = URI::Escape::uri_escape($url);
	 };
	 Tk::Pod::Util::start_browser("https://metacpan.org/module/" . $url);
     },
    ],
    [Button => $compound->('Pod on ~annocpan.org'),
     '-command' => sub {
	 require Tk::Pod::Util;
	 my $url = $p->{pod_title};
	 eval {
	     require URI::Escape;
	     $url = URI::Escape::uri_escape($url);
	 };
	 ## It seems that the search works better than the direct link on annocpan.org...
	 Tk::Pod::Util::start_browser("http://www.annocpan.org/?mode=search&field=Module&name=$url");
	 #Tk::Pod::Util::start_browser("http://www.annocpan.org/perldoc?" . $url);
     },
    ],
   ]
  ],

  [Cascade => '~Search', -menuitems =>
   [
    [Button => $compound->('~Search', "viewmag"),
     '-accelerator' => '/',
     '-command' => ['Search', $p, 'Next'],
    ],
    [Button => $compound->('Search ~backwards'),
     '-accelerator' => '?',
     '-command' => ['Search', $p, 'Prev'],
    ],
    [Button => $compound->('~Repeat search'),
     '-accelerator' => 'n',
     '-command' => ['ShowMatch', $p, 'Next'],
    ],
    [Button => $compound->('R~epeat backwards'),
     '-accelerator' => 'N',
     '-command' => ['ShowMatch', $p, 'Prev'],
    ],
    [Checkbutton => $compound->('~Case sensitive'),
     '-variable' => \$searchcase,
     '-command' => sub { $p->configure(-searchcase => $searchcase) },
    ],
    [Separator => ""],
    [Button => $compound->('Search ~full text', "filefind"),
     '-command' => ['SearchFullText', $p],
    ],
    [Button => $compound->('Search FA~Q'),
     '-command' => ['SearchFAQ', $w, $p],
    ],
   ]
  ],

  [Cascade => 'H~istory', -menuitems =>
   [
    [Button => $compound->('~Back', "navback"),
     '-accelerator' => 'Alt-Left',
     '-command' => ['history_move', $p, -1],
    ],
    [Button => $compound->('~Forward', "navforward"),
     '-accelerator' => 'Alt-Right',
     '-command' => ['history_move', $p, +1],
    ],
    [Button => $compound->('~View'),
     '-command' => ['history_view', $p],
    ],
    '-',
    [Button => $compound->('Clear cache'),
     '-command' => ['clear_cache', $p],
    ],
   ]
  ],

  [Cascade => '~Help', -menuitems =>
   [
    # XXX restructure to not reference to tkpod
    [Button => '~Usage...',       -command => ['help', $w]],
    [Button => '~Programming...', -command => ['help_programming', $w]],
    [Button => '~About...', -command => ['about', $w]],
    ($ENV{'TKPODDEBUG'}
     ? ('-',
	[Button => 'WidgetDump', -command => sub { $w->WidgetDump }],
	[Button => 'Ptksh', -command => sub {
	     # Code taken from bbbike
	     # Is there already a (withdrawn) ptksh?
	     foreach my $mw0 (Tk::MainWindow::Existing()) {
		 if ($mw0->title =~ /^ptksh/) {
		     $mw0->deiconify;
		     $mw0->raise;
		     return;
		 }
	     }

	     require Config;
	     my $perldir = $Config::Config{'scriptdir'};
	     require "$perldir/ptksh";

	     # Code taken from bbbike and slightly modified
	     foreach my $mw0 (Tk::MainWindow::Existing()) {
		 if ($mw0->title eq 'ptksh') {
		     $mw0->protocol('WM_DELETE_WINDOW' => [$mw0, 'withdraw']);
		 }
	     }
	 }],
	[Button => 'Reloader', -command => sub {
	     if (eval { require Module::Refresh; 1 }) {
		 Module::Refresh->refresh;
		 $w->messageBox(-title   => "Reloader",
				-icon    => "info",
				-message => "Modules were reloaded.",
			       );
	     } else {
		 $w->messageBox(-title   => "Reloader",
				-icon    => "error",
				-message => "To use this functionality you have to install Module::Refresh from CPAN",
			       );
		 # So we have a chance to try it again...
		 delete $INC{"Module/Refresh.pm"};
	     }
	 }],
       )
     : ()
    ),
   ]
  ]
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

  # This is somewhat hackish: to make sure that the Tk::Pod bindings
  # win over the embedded Tk::More/Tk::Text bindings, the bindtags of
  # all child widgets are re-shuffled, so the Tk::Pod bindings come
  # first. Additionally, all the Tk::Pod bindings need additionally a
  # Tk->break call, so no other binding of embedded widgets is fired.
  $p->Walk(sub {
     my $w = shift;
     my @bindtags = $w->bindtags;
     if (grep { $_ eq $path } @bindtags)
      {
       $w->bindtags([$path, grep { $_ ne $path } @bindtags]);
      }
  });

  foreach my $mod (qw(Alt Meta))
   {
    $w->bind($path, "<$mod-Left>"  => sub { $p->history_move(-1); Tk->break });
    $w->bind($path, "<$mod-Right>" => sub { $p->history_move(+1); Tk->break });
   }

  $w->bind($path, "<Control-minus>" => sub { $w->zoom_out; Tk->break });
  $w->bind($path, "<Control-plus>"  => sub { $w->zoom_in; Tk->break });
  $w->bind($path, "<F3>" => sub { $w->openfile; Tk->break });
  $w->bind($path, "<Control-o>" => sub { $w->openpod($p); Tk->break });
  $w->bind($path, "<Control-n>" => sub { $w->newwindow($p); Tk->break });
  $w->bind($path, "<Control-r>" => sub { $p->reload; Tk->break });
  $w->bind($path, "<Control-p>" => sub { $p->Print; Tk->break });
  $w->bind($path, "<Print>"     => sub { $p->Print; Tk->break });
  $w->bind($path, "<Control-u>" => sub { $p->view_source; Tk->break });
  $w->bind($path, "<Control-w>" => sub { $w->quit; Tk->break });
  $w->bind($path, "<Control-q>" => sub { $p->MainWindow->destroy; Tk->break })
      if $exitbutton;
 }

 $w->protocol('WM_DELETE_WINDOW',['quit',$w]);
}

my $fsbox;

sub openfile {
    my ($cw,$p) = @_;
    my $file;
    if ($cw->can("getOpenFile")) {
	$file = $cw->getOpenFile
	    (-title => "Choose Pod file",
	     -filetypes => [['Pod containing files', ['*.pod',
						      '*.pl',
						      '*.pm']],
			    ['Pod files', '*.pod'],
			    ['Perl scripts', '*.pl'],
			    ['Perl modules', '*.pm'],
			    ['All files', '*']]);
    } else {
	unless (defined $fsbox && $fsbox->IsWidget) {
	    require Tk::FileSelect;
	    $fsbox = $cw->FileSelect();
	}
	$file = $fsbox->Show();
    }
    $cw->configure(-file => $file) if defined $file && -r $file;
}

sub openpod {
    my($cw,$p) = @_;
    my $t = $cw->Toplevel(-title => "Open Pod by Name");
    $t->transient($cw);
    $t->grab;
    my($pod, $e, $go);
    {
	my $Entry = 'Entry';
	eval {
	    require Tk::HistEntry;
	    Tk::HistEntry->VERSION(0.40);
	    $Entry = "HistEntry";
	};

	my $f = $t->Frame->pack(-fill => "x");
	$f->Label(-text => "Pod:")->pack(-side => "left");
	$e = $f->$Entry(-textvariable => \$pod)->pack(-side => "left", -fill => "x", -expand => 1);
	if ($e->can('history') && $openpod_history) {
	    $e->history($openpod_history);
	}
	$e->focus;
	$go = 0;
	$e->bind("<Return>" => sub { $go = 1 });
	$e->bind("<Escape>" => sub { $go = -1 });
    }

    {
	my $f = $t->Frame->pack;
	Tk::grid($f->Label(-text => "Use 'Module::Name' for module documentation"), -sticky => "w");
	Tk::grid($f->Label(-text => "Use '-f function' for function documentation"), -sticky => "w");
	Tk::grid($f->Label(-text => "Use '-q terms' for FAQ entries"), -sticky => "w");
    }

    {
	my $f = $t->Frame->pack;
	$f->Button(-text => "OK",
		   -command => sub { $go = 1 })->pack(-side => "left");
	$f->Button(-text => "New window",
		   -command => sub { $go = 2 })->pack(-side => "left");
	$f->Button(-text => "Cancel",
		   -command => sub { $go = -1 })->pack(-side => "left");
    }
    $t->Popup(-popover => $cw);
    $t->OnDestroy(sub { $go = -1 unless $go });
    $t->waitVariable(\$go);
    if (Tk::Exists($t)) {
	if (defined $pod && $pod ne "" && $go > 0 && $e->can('historyAdd')) {
	    $e->historyAdd($pod);
	    $openpod_history = [ $e->history ];
	}
	$t->grabRelease;
	$t->destroy;
    }

    my %pod_args;
    if (defined $pod && $pod =~ /^(-[fq])\s+(.+)/) {
	my $switch = $1;
	my $func = $2;
	%pod_args = $cw->getpodargs($switch, $func);
    } else {
	%pod_args = $cw->getpodargs($pod);
    }

    if (defined $pod && $pod ne "") {
	if ($go == 1) {
	    $cw->configure(%pod_args);
	} elsif ($go == 2) {
	    my $new_cw = $cw->clone(%pod_args);
	}
    }
}

sub getpodargs {
    my($cw, @args) = @_;
    my @pod_args;
    if (@args == 1) {
	@pod_args = ('-file' => $args[0]);
    } elsif (@args == 2 && $args[0] =~ /^-([fq])$/) {
	my $switch = $1;
	my $func = $args[1];
	my $func_pod = "";
	open(FUNCPOD, "-|") or do {
	    exec "perldoc", "-u", "-$switch", $func;
	    warn "Can't execute perldoc: $!";
	    CORE::exit(1);
	};
	local $/ = undef;
	$func_pod = join "", <FUNCPOD>;
	close FUNCPOD;
	if ($func_pod ne "") {
	    push @pod_args, '-text' => $func_pod;
	    if ($switch eq "f") {
		push @pod_args, '-title' => "Function $func";
	    } else {
		push @pod_args, '-title' => "FAQ $func";
	    }
	}
    }
    @pod_args;
}

sub newwindow {
    shift->clone;
}

sub Dir {
    require Tk::Pod::Text;
    require Tk::Pod::Tree;
    Tk::Pod::Text::Dir(@_);
    Tk::Pod::Tree::Dir(@_);
}


sub quit { shift->destroy }

sub help {
    my $w = shift;
    $w->clone('-tree' => 0,
	      '-file' => 'Tk::Pod_usage.pod',
	     );
}

sub help_programming {
    my $w = shift;
    $w->clone('-tree' => 0,
	      '-file' => 'Tk/Pod.pm',
	      );
}

sub about {
    my $w = shift;
    require Tk::DialogBox;
    require Tk::ROText;
    my $d = $w->DialogBox(-title => "About Tk::Pod",
			  -buttons => ["OK"],
			 );
    my $message = <<EOF;
Tk::Pod - a Pod viewer written in Perl/Tk

Version information:
    Tk-Pod distribution $DIST_VERSION
    Tk::Pod module $VERSION

System information:
    @{[ $Pod::Simple::VERSION ? "Pod::Simple $Pod::Simple::VERSION\n"
			  : ""
]}    Tk $Tk::VERSION
    Perl $]
    OS $^O

Please contact <srezic\@cpan.org> in case of problems.
Send the contents of this window for diagnostics.

EOF
    my @lines = split /\n/, $message, -1;
    my $width = 0;
    for (@lines) {
	$width = length $_ if length $_ > $width;
    }
    my $txt = $d->add("Scrolled", "ROText",
		      -height => scalar @lines,
		      -width => $width + 1,
		      -relief => "flat",
		      -scrollbars => "oe",
		     )->pack(-expand => 1, -fill => "both");
    $txt->insert("end", $message);
    $d->Show;
}

sub add_section_menu {
    my($pod) = @_;

    my $screenheight = $pod->screenheight;
    my $mbar = $pod->Subwidget('menubar');
    my $sectionmenu = $mbar->Subwidget('sectionmenu');
    if (defined $sectionmenu) {
        $sectionmenu->delete(0, 'end');
    } else {
	$mbar->insert($mbar->index("last"), "cascade",
		      '-label' => 'Section', -underline => 1);
	$sectionmenu = $mbar->Menu;
	$mbar->entryconfigure($mbar->index("last")-1, -menu => $sectionmenu);
	$mbar->Advertise(sectionmenu => $sectionmenu);
    }

    my $podtext = $pod->Subwidget('pod');
    my $text    = $podtext->Subwidget('more')->Subwidget('text');

    $text->tag('configure', '_section_mark',
               -background => 'red',
               -foreground => 'black',
              );

    my $sdef;
    foreach $sdef (@{$podtext->{'sections'}}) {
        my($head_level, $subject, $pos) = @$sdef;

	my @args;
	if ($sectionmenu &&
	    $sectionmenu->yposition("last") > $screenheight-40) {
	    push @args, -columnbreak => 1;
	}

        $sectionmenu->command
	  (-label => ("  " x ($head_level-1)) . $subject,
	   -command => sub {
	       my($line) = split(/\./, $pos);
	       $text->tag('remove', '_section_mark', qw/0.0 end/);
	       $text->tag('add', '_section_mark',
			  $line-1 . ".0",
			  $line-1 . ".0 lineend");
	       $text->yview("_section_mark.first");
	       $text->after(500, [$text, qw/tag remove _section_mark 0.0 end/]);
	   },
	   @args,
	  );
    }
}

sub tree {
    my $w = shift;
    if (@_) {
	my $val = shift;
	$w->{Tree_on} = $val;
	my $tree = $w->Subwidget('tree');
	my $p = $w->Subwidget("pod");
	if ($val) {
	    $p->packForget;
	    $tree->packAdjust(-side => 'left', -fill => 'y');
	    $p->pack(-side => "left", -expand => 1, -fill => 'both');
	    if (!$tree->Filled) {
		$w->_configure_tree;
		$w->Busy(-recurse => 1);
		eval {
		    $tree->Fill(-fillcb => sub {
				    $tree->SeePath("file:" . $p->cget(-path)) if $p->cget(-path);
				});
		};
		my $err = $@;
		$w->Unbusy;
		if ($err) {
		    die $err;
		}
	    }
	} else {
	    if ($tree && $tree->manager) {
		$tree->packForget;
		$p->packForget;
		eval {
		    $w->Walk
			(sub {
			     my $w = shift;
			     if ($w->isa('Tk::Adjuster') &&
				 $w->cget(-widget) eq $tree) {
				 $w->destroy;
				 die;
			     }
			 });
		};
		$p->pack(-side => "left", -expand => 1, -fill => 'both');
	    }
	}
    }
    $w->{Tree_on};
}

sub _configure_tree {
    my($w) = @_;
    my $tree = $w->Subwidget("tree");
    my $p    = $w->Subwidget("pod");

    my $common_showcommand = sub {
	my($e) = @_;
	my $uri = $e->uri;
	my $type = $e->type;
	if (defined $type && $type eq 'func') {
	    my $text = $Tk::Pod::Tree::FindPods->function_pod($e->name);
	    (-text => $text, -title => $e->name);
	} elsif (defined $uri && $uri =~ /^file:(.*)/) {
	    (-file => $1);
	} else {
	    # ignore
	}
    };

    $tree->configure
	(-showcommand  => sub {
	     my $e = $_[1];
	     my %args = $common_showcommand->($e);
	     my $title = delete $args{-title};
	     $p->configure(-title => $title) if defined $title;
	     $p->configure(%args);
	 },
	 -showcommand2 => sub {
	     my $e = $_[1];
	     my @args = $common_showcommand->($e);
	     # XXX -title?
	     $w->clone(-tree => !!$tree,
		       @args);
	 },
	);
}

sub SearchFAQ {
    my($cw, $p) = @_;
    my $t = $cw->Toplevel(-title => "Perl FAQ Search");
    $t->transient($cw);
    $t->grab;
    my($keyword, $go, $e);
    {
	my $Entry = 'Entry';
	eval {
	    require Tk::HistEntry;
	    Tk::HistEntry->VERSION(0.40);
	    $Entry = "HistEntry";
	};

	my $f = $t->Frame->pack(-fill => "x");
	$f->Label(-text => "FAQ keyword:")->pack(-side => "left");
	$e = $f->$Entry(-textvariable => \$keyword)->pack(-side => "left");
	if ($e->can('history') && $searchfaq_history) {
	    $e->history($searchfaq_history);
	}
	$e->focus;
	$go = 0;
	$e->bind("<Return>" => sub { $go = 1 });
	$e->bind("<Escape>" => sub { $go = -1 });
    }
    {
	my $f = $t->Frame->pack;
	$f->Button(-text => "OK",
		   -command => sub { $go = 1 })->pack(-side => "left");
	$f->Button(-text => "New window",
		   -command => sub { $go = 2 })->pack(-side => "left");
	$f->Button(-text => "Cancel",
		   -command => sub { $go = -1 })->pack(-side => "left");
    }
    $t->Popup(-popover => $cw);
    $t->OnDestroy(sub { $go = -1 unless $go });
    $t->waitVariable(\$go);
    if (Tk::Exists($t)) {
	if (defined $keyword && $keyword ne "" && $go > 0 && $e->can('historyAdd')) {
	    $e->historyAdd($keyword);
	    $searchfaq_history = [ $e->history ];
	}
	$t->grabRelease;
	$t->destroy;
    }
    if (defined $keyword && $keyword ne "") {
	if ($go) {
	    require File::Temp;
	    my($fh, $pod) = File::Temp::tempfile(UNLINK => 1,
						 SUFFIX => "_tkpod.pod");
	    my $out = `perldoc -u -q $keyword`; # XXX protect keyword
	    print $fh $out;
	    close $fh;

	    if (-z $pod) {
		$cw->messageBox(-title   => "No FAQ keyword",
				-icon    => "error",
				-message => "FAQ keyword not found",
			       );
	    } else {
		if ($go == 1) {
		    $cw->configure(-file => $pod);
		} elsif ($go == 2) {
		    my $new_cw = $cw->clone('-file' => $pod);
		}
	    }
	}
    }
}

sub zoom {
    my($w, $method) = @_;
    my $p = $w->Subwidget("pod");
    $p->$method();
    $w->set_base_font_size($p->base_font_size);
}

sub zoom_in     { shift->zoom("zoom_in") }
sub zoom_out    { shift->zoom("zoom_out") }
sub zoom_normal { shift->zoom("zoom_normal") }

sub base_font_size {
    my $w = shift;
    $w->{Base_Font_Size};
}

sub set_base_font_size {
    my($w, $font_size) = @_;
    $w->{Base_Font_Size} = $font_size;
}

sub clone {
    my($w, %pod_args) = @_;
    my %pre_args;
    for ('-tree', '-exitbutton') {
	if (exists $pod_args{$_}) {
	    $pre_args{$_} = delete $pod_args{$_};
	} else {
	    $pre_args{$_} = $w->cget($_);
	}
    }
    my $new_w = $w->MainWindow->Pod
	(%pre_args,
	 '-basefontsize' => $w->base_font_size,
	);
    $new_w->configure(%pod_args) if %pod_args;
    $new_w;
}

1;

__END__

=head1 NAME

Tk::Pod - Pod browser toplevel widget


=head1 SYNOPSIS

    use Tk::Pod

    Tk::Pod->Dir(@dirs)			# add dirs to search path for Pod

    $pod = $parent->Pod(
		-file = > $name,	# search and display Pod for name
		-tree = > $bool		# display pod file tree
		);


=head1 DESCRIPTION

Simple Pod browser with hypertext capabilities in a C<Toplevel> widget

=head1 OPTIONS

=over

=item -tree

Set tree view by default on or off. Default is false.

=item -exitbutton

Add to the menu an exit entry. This is only useful for standalone pod
readers. Default is false. This option can only be set on construction
time.

=back

Other options are propagated to the embedded L<Tk::Pod::Text> widget.

=head1 BUGS

If you set C<-file> while creating the Pod widget,

    $parent->Pod(-tree => 1, -file => $pod);

then the title will not be displayed correctly. This is because the
internal setting of C<-title> may override the title setting caused by
C<-file>. So it is better to configure C<-file> separately:

    $pod = $parent->Pod(-tree => 1);
    $pod->configure(-file => $pod);

=head1 SEE ALSO

L<Tk::Pod_usage>, L<Tk::Pod::Text>, L<tkpod>, L<perlpod>,
L<Gtk2::Ex::PodViewer>, L<Prima::PodView>.

=head1 AUTHOR

Nick Ing-Simmons <F<nick@ni-s.u-net.com>>

Current maintainer is Slaven Rezic <F<slaven@rezic.de>>.

Copyright (c) 1997-1998 Nick Ing-Simmons.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
