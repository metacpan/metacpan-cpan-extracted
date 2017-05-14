
package ZooZ::Options;

use strict;
use Tk;
use Tk::BrowseEntry;
use ZooZ::Forms;

# I need to get the height of an optionmenu widget.
# this will be the height we configure the rows to be at.
our $maxHeight;

# this package defines all the options and their possible values.

our %options = ( # generics
		Name                => ['Name'],
		Title               => ['String'],
		-activebackground   => ['Color'],
		-activeborderWidth  => ['Integer', 'positive'],
		-activeforeground   => ['Color'],
		-activeimage        => ['Image'],
		-activetile         => ['Image'],
		-anchor             => ['List', qw/n s e w ne se sw nw center/],
		-background         => ['Color'],
		-bitmap             => ['Image'],
		-borderwidth        => ['Integer', 'positive'],
		-command            => ['Callback'],
		-compound           => ['TBD'],
		-createcmd          => ['Callback'],
		-cursor             => ['Image'],
		#-dash              => [],
		-default            => ['TBD'],
		-disabledforeground => ['Color'],
		-disabledtile       => ['Image'],
		-exportselection    => ['Boolean'],
		-font               => ['Font'],
		-foreground         => ['Color'],
		-height             => [qw/Integer positive/],
		-highlightbackground => ['Color'],
		-highlightcolor     => ['Color'],
		-highlightthickness => ['Integer', 'positive'],
		-image              => ['Image'],
		-indicatoron        => ['Boolean'],
		-insertbackground   => ['Color'],
		-insertborderwidth  => [qw/Integer positive/],
		-insertofftime      => [qw/Integer positive/],
		-insertontime       => [qw/Integer positive/],
		-insertwidth        => [qw/Integer positive/],
		-ipadx              => [qw/Integer positive/],
		-ipady              => [qw/Integer positive/],
		-jump               => ['Boolean'],
		-justify            => [qw/List left right center/],
		-label              => ['String'],
		-minsize            => [qw/Integer positive/],  # for gridConfigure
		-offset             => [qw/List n s e w ne se sw nw center/],
		-offvalue           => ['String'],
		-onvalue            => ['String'],
		-orient             => [qw/List horizontal vertical/],
		-pad                => [qw/Integer positive/],  # for gridConfigure
		-padx               => [qw/Integer positive/],
		-pady               => [qw/Integer positive/],
		-raisecmd           => ['Callback'],
		-relief             => [qw/List raised sunken flat ridge solid groove/],
		-repeatdelay        => [qw/Integer positive/],
		-repeatinterval     => [qw/Integer positive/],
		-selectbackground   => ['Color'],
		-selectborderwidth  => [qw/Integer positive/],
		-selectcolor        => ['Color'],
		-selectforeground   => ['Color'],
		-selectimage        => ['Image'],
		-setgrid            => ['Boolean'],
		-state              => [qw/List normal disabled/],
		-takefocus          => ['Boolean'],
		-text               => ['String'],
		-textvariable       => ['VarRef'],
		-tile               => ['Image'],
		-troughColor        => ['Color'],
		-troughtile         => ['Image'],
		-underline          => [qw/Integer positive/],
		-value              => ['String'],
		-variable           => ['VarRef'],
		-weight             => [Hash =>
					'Not Greedy'        => 0,
					'A Little Greedy'   => 1,
					'Very Greedy',      => 2,
					'Very Very Greedy', => 3,
					'Ebenezer Scrooge'  => 4],
		-width              => [qw/Integer positive/],
		-wraplength         => [qw/Integer positive/],
#		-xscrollcommand     => ['Callback'],
#		-yscrollcommand     => ['Callback'],
	       );


###############
#
# Generic functions
#
###############

# args to this are:
# 1. option name.
# 2. option text to use in the label.
# 3. frame to add stuff to.
# 4. row to add stuff to.
# 5. col to add stuff to.
# 6. var ref to save result to.
# 7. additional args that depend on type of option.
#    for -font,     $args[0] is a ZooZ::Fonts object.
#    for Callbacks, $args[0] is a ZooZ::Callbacks object.
#    for varrefs,   $args[0] is a ref to the -text var ref.
#    for Name,      $args[0] is an optional bg color of the label.

sub addOptionGrid {
  my ($class,
      $option,
      $optionLabel,
      $frame,
      $row,
      $col,
      $ref,
      @args) = @_;

  unless (exists $options{$option}) {
    # hmmm .. should change this to some default. Just an entry.
    # TBD
    return undef;
  }

  unless ($maxHeight) { # this feels like a hack.
    #my $om     = $frame->Optionmenu;
    my $om     = $frame->Button(-pady => 0);
    $maxHeight = $om   ->reqheight;
    $om->destroy;
  }

  my @list = @{$options{$option}};
  my $type = shift @list;

  my $label = $frame->Label(-text          => $optionLabel,
			    -anchor        => 'w',
			    -font          => 'OptionText',
			   )->grid(-column => $col,
				   -row    => $row,
				   -sticky => 'ewns',
				  );

  if ($type eq 'Color') {
    $frame->Entry(-textvariable  => $ref,
		 )->grid(-column => $col + 1,
			 -row    => $row,
			 -sticky => 'ew',
			);
    my $b;
    $b = $frame->Button(
			-bitmap  => 'transparent',
			-fg      => Tk::NORMAL_BG,
			-command => [\&_chooseColor, $frame, $ref, \$b],
			-height  => 9,
			-width   => 9,
		       )->grid(-column => $col + 2,
			       -row    => $row,
			       -padx   => 1,
			       -sticky => 'ew',
			 );

  } elsif ($type eq 'Image') {
    my $types;
    if ($optionLabel eq '-image') {
      $types = [
		['GIF Files',    '.gif'],
		['PGM Files',    '.pgm'],
		['PPM Files',    '.ppm'],
		['Bitmap Files', '.bmp'],
		['Pixmap Files', '.xpm'],
		['All Files',    '*'   ],
	       ];
    } elsif ($optionLabel eq '-bitmap') {
      $types = [
		['Bitmap Files', '.bmp'],
		['All Files', '*'   ],
	       ];
    } else {
      $types = [
		['GIF Files',    '.gif'],
		['PGM Files',    '.pgm'],
		['PPM Files',    '.ppm'],
		['Bitmap Files', '.bmp'],
		['Pixmap Files', '.xpm'],
		['All Files',    '*'   ],
	       ];
    }

    my $file;
    $frame->Entry(-textvariable       => \$file,
		  -state              => 'disabled',
		  -disabledforeground => 'black',
		 )->grid(-column => $col + 1,
			 -row    => $row,
			 -sticky => 'ew',
			);
    $frame->Button(-text    => '...',
		   -padx    => 0,
		   -pady    => 0,
		   -command => sub {
		     my $ans = $frame->getOpenFile(-title     => 'Select Image',
						   -filetypes => $types);
		     return unless $ans;
		     $file = $ans;

		     my $type;
		     if      ($file =~ /\.(?:gif|pgm|ppm)$/) {
		       $type = 'Photo';
		     } elsif ($file =~ /\.bmp$/) {
		       $type = 'Bitmap';
		     } elsif ($file =~ /\.xpm$/) {
		       $type = 'Pixmap';
		     } else { # reset
		       $$ref = 'image-zooz';
		       return;
		     }
		     $$ref = $frame->$type(-file => $file);
		   })->grid(-column => $col + 2,
			    -row    => $row,
			    -padx   => 1,
			    -sticky => 'ew',
			   );

  } elsif ($type eq 'Hash') {
    my %h   = @list;
    my $key = $$ref ? do {
      (grep $h{$_} eq $$ref => keys %h)[0]
    } : $list[0];
    $$ref   = $h{$key};

    my $e = $frame->BrowseEntry(
				-choices            => [sort {$h{$a} <=> $h{$b}} keys %h],
				-state              => 'readonly',
				-variable           => \$key,
				-disabledforeground => 'black',
				-browsecmd          => sub { $$ref = $h{$key} },
			       )->grid(-column     => $col + 1,
				       -row        => $row,
				       -columnspan => 2,
				       -sticky     => 'ew',
				      );

  } elsif ($type eq 'List') {
    my $e = $frame->BrowseEntry(
				-choices            => [@list],
				-state              => 'readonly',
				-variable           => $ref,
				-disabledforeground => 'black',
			       )->grid(-column     => $col + 1,
				       -row        => $row,
				       -columnspan => 2,
				       -sticky     => 'ew',
				      );

  } elsif ($type eq 'Integer') {
    my $pos = shift @list || 0;
    my $rgx = $pos ? qr/^\d$/ : qr/^(?:-|\d|\.)$/;

    $frame->Entry(
		  -textvariable    => $ref,
		  -validate        => 'key',
		  -validatecommand => sub {
		    return 1 unless $_[4] == 1 || $_[4] == 8;  # Tk800 and Tk804
		    return 0 unless $_[1] =~ /$rgx/;
		    return 1;
		  },
		 )->grid(-column     => $col + 1,
			 -row        => $row,
			 -columnspan => 2,
			 -sticky     => 'ew',
			);

  } elsif ($type eq 'String') {
    $frame->Entry(
		  -textvariable      => $ref,
		 )->grid(-column     => $col + 1,
			 -row        => $row,
			 -columnspan => 2,
			 -sticky     => 'ew',
			);

  } elsif ($type eq 'Boolean') {
    $frame->Checkbutton(-text     => 'On/Off',
			-variable => $ref,
			-anchor   => 'w',
		       )->grid(-column     => $col + 1,
			       -row        => $row,
			       -columnspan => 2,
			       -sticky     => 'ew',
			      );

  } elsif ($type eq 'Font') {
    $$ref ||= 'Default';
    $frame->Entry(-textvariable  => $ref,
		  -relief        => 'flat',
		  -state         => 'disabled',
		  -disabledforeground => 'black',
		 )->grid(-column => $col + 1,
			 -row    => $row,
			 -sticky => 'ew',
			);
    $frame->Button(
		   -bitmap  => 'transparent',
		   -fg      => Tk::NORMAL_BG,
		   -height  => 9,
		   -width   => 9,
		   -command => sub {
		     my $f = ZooZ::Forms->chooseFont;
		     return unless $f;

		     $$ref = $f;
		     #$l->configure(-text => $f);
		   },
		  )->grid(-column => $col + 2,
			  -row    => $row,
			  -padx   => 1,
			  -sticky => 'ew',
			 );

  } elsif ($type eq 'Callback') {
    #$$ref = 'Select Callback' unless $$ref;
    my $b;

    $b = $frame->Button(-text         => $$ref || 'Select Callback',
			-pady         => 0,
			-command      => sub {
			  my $cb = ZooZ::Forms->chooseCallback;
			  return unless $cb;

			  if ($cb eq 'UNSET') {
			    $b->configure(-text => 'Select Callback');
			    $$ref = undef;
			    return;
			  }

			  $b->configure(-text => '\&' . $cb);
			  $$ref = eval "\\&$cb";

			  $::CALLBACKOBJ->name2code($cb, $$ref);
			},
		       )->grid(-column     => $col + 1,
			       -row        => $row,
			       -columnspan => 2,
			       -sticky     => 'ew',
			      );

  } elsif ($type eq 'VarRef') {
    $$ref = 'Select Variable' unless $$ref;
    my $b;

    $b = $frame->Button(-text    => $$ref,
			-pady    => 0,
			-command => sub {
			  my $vr = ZooZ::Forms->chooseVar;
			  return unless $vr;

			  if ($vr eq 'UNSET') {
			    $b->configure(-text => 'Select Variable');
			    $$ref = '';

			    # if a textvariable, reset the -text.
			    # it doesn't happen automatically.
			    if ($option eq '-textvariable') {
			      $ {$args[0]} .= '';  # it is tied.
			    }

			    return;
			  }

			  $b->configure(-text => "\\" . $vr);

			  my $cp = $vr;
			  # create the var
			  {
			    $vr =~ s/^.//;
			    no strict;
			    $$ref = \${"main::$vr"};
			  }

			  $::VARREFOBJ->name2ref($cp, $$ref);

			})->grid(-column     => $col + 1,
				 -row        => $row,
				 -columnspan => 2,
				 -sticky     => 'ew',
				);

  } elsif ($type eq 'Name') {
    $frame->Entry(
		  -textvariable      => $ref,
		  -validate          => 'key',
		  -validatecommand   => sub { #disallow spaces
		    return 1 unless $_[4] == 1 || $_[4] == 8;  # Tk800 and Tk804
		    return 0 if     $_[1] =~ /\s/;
		    return 1;
		  })->grid(-column     => $col + 1,
			 -row        => $row,
			 -columnspan => 2,
			 -sticky     => 'ew',
			);

    $label->configure(-font => 'Default', -relief => 'solid', -bg => $args[0] || Tk::NORMAL_BG);
  }

  # configure the row to make it look nice.
  $frame->gridRowconfigure($row, -minsize => $maxHeight, -weight => 2);

  return $label;
}

sub _chooseColor {
  my ($f, $ref, $b) = @_;

  my $color = $f->chooseColor;
  $color or return;

  $$ref = $color;
  $$b->configure(-bg => $color);
}

1;

