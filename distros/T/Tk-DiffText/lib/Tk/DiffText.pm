#===============================================================================
# Tk/DiffText.pm
# Last Modified: 3/21/2008 1:07:01 PM
#===============================================================================
BEGIN {require 5.005} # for qr//
use strict;
use Tk;
use Tk::widgets qw'ROText Scrollbar';

package Tk::DiffText;
use Carp qw'carp';
use vars qw'$VERSION';
$VERSION = '0.19';

use base qw'Tk::Frame';
Tk::Widget->Construct('DiffText');

#-------------------------------------------------------------------------------
# Method  : ClassInit
# Purpose : Class initialization.
# Notes   : 
#-------------------------------------------------------------------------------
sub ClassInit {
	my ($class, $mw) = @_;
	$class->SUPER::ClassInit($mw);

	# This module is pretty crippled if we can't do diffs, but let's degrade
	# nicely instead of dieing.
	eval {
		require Algorithm::Diff;
		require Tie::Tk::Text;
	};
	*compare = $@ ? \&_pad_text : \&_compare_text;

	# Only needed to resolve passing data inputs as *FH{IO} or *FH{FILEHANDLE}
	eval {require IO::File};
}


#-------------------------------------------------------------------------------
# Method  : Populate
# Purpose : Create a DiffText composite widget.
# Notes   : 
#-------------------------------------------------------------------------------
sub Populate {
	my ($self, $arg) = @_;

	my $gutter = delete $arg->{-gutter};
	my $orient = delete $arg->{-orient};

	$gutter = 1          unless defined $gutter;
	$orient = 'vertical' unless defined $orient;

	$self->bind('<Configure>', [\&_rescale_map, $self]);

	# I'm not sure whether it's a bug of a feature, but Frames with contents
	# always collapse down to just what's needed by the widgets they contain.
	# This makes setting the width and height of the composite widget worthless.
	# Empty Frames, on the other hand, *do* respect height and width settings.
	# We exploit this by creating invisible frames along the top and left edges
	# of the composite widget and using them to control its (minimum) size.
	my $f  = $self;
	my $wf = $f->Frame(-height => 0, -borderwidth => 0)->pack(-side => 'top');
	my $hf = $f->Frame(-width  => 0, -borderwidth => 0)->pack(-side => 'left');

	my $diffcolors = {
		add => [-background => '#ccffcc'],
		del => [-background => '#ffcccc'],
		mod => [-background => '#aed7ff'],
		pad => [-background => '#f0f0f0'],
		cur => [-background => '#ffff80'],
	};

	if ($arg->{-diffcolors}) {
		while (my ($k, $v) = each %{$arg->{-diffcolors}}) {
			$diffcolors->{$k} = $v;
		}
		delete $arg->{-diffcolors};
	}

	$self->{_map}{type}   = delete $arg->{-map} || 'scaled';
	$self->{_map}{colors} = _get_map_colors($diffcolors);

	$self->SUPER::Populate($arg);

	my $side = $orient eq 'horizontal' ? 'top' : 'left';

	my $dm = $f->Canvas(
		-width              => 20, #
		-height             => 1,  # fills to match Text areas
		-takefocus          => 0,  #
		-highlightthickness => 0,  #
	);
	$dm->Tk::bind('<Button-1>', [\&_mapjump, $self, Tk::Ev('x'), Tk::Ev('y')]);

	unless ($self->{_map}{type} eq 'none') {
		$self->{_map}{height} = 0;
		$self->{_map}{scale}  = 1;
		$dm->pack(-side => 'left', -fill => 'y');
	}

	my @p = (
		_make_pane($f, $side, $diffcolors, $gutter),
		_make_pane($f, $side, $diffcolors, $gutter),
	);

	$self->{_textarray} = {
		a => $p[0]->{textarray},
		b => $p[1]->{textarray},
	};
	$self->{_scroll_lock} = 0;

	$self->{_diffloc} = [];
	$self->{_current}    = undef;

	# Set up synchronized scrolling between panes. It can be turned on/off by
	# toggling the _scroll_lock flag.
	for my $i (0 .. 1) {
		foreach my $w (@{$p[$i]->{scroll_locked}}) {
			$w->configure(-yscrollcommand =>
				[\&_scroll_panes, $w, \@p, $i, $self]);
		}	
	}

	$self->ConfigSpecs(
		# overall widget size
		-width            => [{-width      => $wf }, qw'width  Width  780'],
		-height           => [{-height     => $hf }, qw'height Height 580'],

		# aliases for controlling gutter configuration
		-gutterbackground => [{-background => [_gw('gutter', @p)]}, qw'background Background', '#f0f0f0'],
		-gutterforeground => [{-foreground => [_gw('gutter', @p)]}, qw'foreground Foreground', '#5c5c5c'],

		# We want the gutter to look like it's part of the main ROText widget, 
		# not a seperate one. To do that we set -borderwidth to 0 on the widgets 
		# and use the frames enclosing them to provide the borders.
		-relief           => [[_gw('frame', @p)], qw'relief      Relief      sunken'],
		-borderwidth      => [[_gw('frame', @p)], qw'borderwidth borderWidth 2'     ],

		# pass most options through to the ROText widgets.
		# Sometimes to just the text ones, sometimes to the gutters too.
		DEFAULT           => [[_gw('text', @p)]],
		-background       => [[_gw('text', @p), $dm]], # DEFAULT doesn't catch fg/bg?
		-foreground       => [[_gw('text', @p), $dm]],
		-font             => [[_gw('text', @p), _gw('gutter', @p)]], # sync gutter font to text for vertical alignment
		-pady             => [[_gw('text', @p), _gw('gutter', @p)]], # pad gutter too for y, (valign) but not for x
		-wrap             => [[_gw('text', @p)], qw'wrap Wrap none'],
	);

	$self->Advertise(text_a       => $p[0]->{text}      );
	$self->Advertise(gutter_a     => $p[0]->{gutter}    );
	$self->Advertise(xscrollbar_a => $p[0]->{xscrollbar});
	$self->Advertise(yscrollbar_a => $p[0]->{yscrollbar});

	$self->Advertise(text_b       => $p[1]->{text}      );
	$self->Advertise(gutter_b     => $p[1]->{gutter}    );
	$self->Advertise(xscrollbar_b => $p[1]->{xscrollbar});
	$self->Advertise(yscrollbar_b => $p[1]->{yscrollbar});

	$self->Advertise(canvas => $dm);
}


#-------------------------------------------------------------------------------
# Subroutine : _make_pane
# Purpose    : Create a frame with a text widget, gutter, and scrollbars
# Notes      : 
#-------------------------------------------------------------------------------
sub _make_pane {
	my $pw         = shift; # parent widget
	my $side       = shift; # where to pack pane
	my $diffcolors = shift;
	my $gutter     = shift; # gutter displayed?

	my $f = $pw->Frame()->pack(
		-side   => $side,
		-fill   => 'both',
		-expand => 1,
	);

	# would like a padded corner between these
	my $vsb = $f->Scrollbar(-orient => 'vertical')
		->pack(-side => 'right', -fill => 'y');
	my $hsb = $f->Scrollbar(-orient => 'horizontal')
		->pack(-side => 'bottom', -fill => 'x');

	my $gw = $f->ROText(
		-height      => 1, # height fills to match text areas
		-width       => 1, # just for starters
		-borderwidth => 0,
		-state       => 'disabled',
		-wrap        => 'none',
	)->pack(-side => 'left', -fill => 'y');

	my $tw = $f->ROText(
		-width          => 1, # size controlled via parent so that panes are
		-height         => 1, # always balanced even when window resized.
		-borderwidth    => 0,
		-xscrollcommand => ['set' => $hsb],
	)->pack(-side => 'left', -fill => 'both', -expand => 1);

	my @text; tie @text, 'Tie::Tk::Text', $tw;
	
	$gw->tagConfigure('pad',  @{[]});
	$tw->tagConfigure('pad',  @{$diffcolors->{pad}});
	$tw->tagConfigure('add',  @{$diffcolors->{add}});
	$tw->tagConfigure('del',  @{$diffcolors->{del}});
	$tw->tagConfigure('mod',  @{$diffcolors->{mod}});
	$tw->tagConfigure('cur',  @{$diffcolors->{cur}});
	$tw->tagRaise('sel');

	$hsb->configure(-command => sub { $tw->xview(@_) });

	# scroll-locked widgets. Don't lock the gutter if it's not packed!
	my @slw = $gutter ? ($tw, $gw) : ($tw);

	$gw->packForget() unless $gutter;

	# scrollbar controls both text and gutter (if visible)
	$vsb->configure(-command => sub { $_->yview(@_) foreach (@slw) });

	# widgets will have their yscrollcommand set *after* we're done creating
	# all of the panes so that we can regulate the synchronized scrolling
	# between them.
	
	return {
		frame         => $f,
		yscrollbar    => $vsb,
		xscrollbar    => $hsb,
		gutter        => $gw,
		text          => $tw,
		textarray     => \@text,
		scroll_locked => \@slw,
	};

}


#-------------------------------------------------------------------------------
# Subroutine : _gw
# Purpose    : get all widgets of a particular type from all panes
# Notes      : 
#-------------------------------------------------------------------------------
sub _gw { my $t = shift; return map {$_->{$t}} @_ }


#-------------------------------------------------------------------------------
# Subroutine : _scroll_panes
# Purpose    : synchronize scrolling between panes
# Notes      :
#-------------------------------------------------------------------------------
sub _scroll_panes {
	my $w      = shift; # calling widget
	my $pane   = shift; # list of panes
	my $i      = shift; # which pane widget is in
	my $self   = shift;

	my ($top, $bottom) = $w->yview();

	foreach my $p (@$pane) {
		next unless ($self->{_scroll_lock} || $p eq $pane->[$i]);
		$p->{yscrollbar}->set(@_);
		$_->yviewMoveto($top) foreach @{$p->{scroll_locked}};
	}
	
	if ($self->{_map}{type} eq 'scrolled') {
		$self->Subwidget('canvas')->yviewMoveto($top);
	}
	elsif ($self->{_map}{type} eq 'scaled') {
		my $h = $self->{_map}{height} * $self->{_map}{scale};
		$self->Subwidget('canvas')->coords('view', 0, $top * $h, 19, $bottom * $h);
	}
}


#-------------------------------------------------------------------------------
# Method  : diff
# Purpose : Load and compare files
# Notes   : 
#-------------------------------------------------------------------------------
sub diff {
	carp("Method diff() deprecated"); # tidy this with "use warnings" ?
	$_[0]->load(a => $_[1]);
	$_[0]->load(b => $_[2]);
	$_[0]->compare();
}


#-------------------------------------------------------------------------------
# Subroutine : _pad_text
# Purpose    : Make both files the same length (for scrolling). No markup.
# Notes      :
#-------------------------------------------------------------------------------
sub _pad_text {
	my $self = shift;
	my $a    = $self->{_textarray}{a};
	my $b    = $self->{_textarray}{b};
	my $z    = $#$b - $#$a;

	return if $z == 0;

	my $x  = $z > 0 ? 'a' : 'b';
	my $tw = $self->Subwidget("text_$x");
	my $gw = $self->Subwidget("gutter_$x");

	$gw->configure(-state => 'normal');

	for (1 .. abs $z) {
		$gw->insert('end', "\n", 'pad');
		$tw->insert('end', "\n", 'pad');
	}

	$gw->configure(-state => 'disabled');

	$self->{_scroll_lock} = 1;

}


#-------------------------------------------------------------------------------
# Subroutine : _reset_tags
# Purpose    : Removes padding and clears markup tags from pane.
# Notes      : 
#-------------------------------------------------------------------------------
sub _reset_tags {
	my $self = shift;
	my $p    = shift; # 'a' or 'b'

	my $tw = $self->Subwidget("text_$p"  );
	$tw->tagRemove('add', '1.0', 'end');
	$tw->tagRemove('del', '1.0', 'end');
	$tw->tagRemove('mod', '1.0', 'end');
	$tw->tagRemove('cur', '1.0', 'end');
	$tw->DeleteTextTaggedWith('pad');

	my $gw = $self->Subwidget("gutter_$p");
	$gw->configure(-state => 'normal');
	$gw->DeleteTextTaggedWith('pad');
	$gw->configure(-state => 'disabled');

}


#-------------------------------------------------------------------------------
# Method  : _compare_text
# Purpose : Compares the data in the text frames and highlights the differences.
# Notes   : 
#-------------------------------------------------------------------------------
sub _compare_text {
	my $self = shift;
	my %opt  = @_;
	my $kg   = $opt{-keygen} || _make_sdiff_keygen(%opt);

	$self->_reset_tags('a');
	$self->_reset_tags('b');

	my $ga  = $self->Subwidget('gutter_a');
	my $gb  = $self->Subwidget('gutter_b');
	my $ta  = $self->Subwidget('text_a'  );
	my $tb  = $self->Subwidget('text_b'  );
	my $map = $self->Subwidget('canvas'  );

	$ga->configure(-state => 'normal');
	$gb->configure(-state => 'normal');

	$map->delete('all');

	# force both panes to scroll to top so that dlineinfo() works
	$_->see('1.0') foreach ($ga, $ta, $gb, $tb);
	my $lh = ($ta->dlineinfo('1.0'))[3];
	my $cy = $self->cget(-borderwidth) + $self->cget(-pady); # canvas y position

	my @diff = _sdiff(
		$self->{_textarray}{a},
		$self->{_textarray}{b},
		$kg,
	);

	my $re;
	for ($opt{-granularity}) {
		defined         || do { last };
		ref eq 'Regexp' && do { $re = $_;           last };
		/^line$/        && do { $re = undef;        last };
		/^word$/        && do { $re = qr/(\s+|\b)/; last };
		/^char$/        && do { $re = qr//;         last };
		! ref           && do { $re = qr/$_/;       last };
	}

	my @pads = (undef, 0, 0);
	my @loc; # track locations of differences for navigation
	my $prev;

	foreach my $d (@diff) {
		next if ($d->[0] eq 'u'); # line matches. stop.

		if ($d->[0] eq '-') {
			my $l = $d->[1] + $pads[1]; $pads[2]++;
			$ta->tagAdd('del', "$l.0", "$l.end + 1 chars");
			$gb->insert("$l.0", "\n", 'pad');
			$tb->insert("$l.0", "\n", 'pad');
			$map->createRectangle(0, $cy, 20, $cy+$lh-1, -tags => 'del');

			if ($prev eq $d->[0]) {
				# extend endpoint
				$loc[-1][1] = "$l.end + 1 chars";
			}
			else {
				# create new location
				push @loc, ["$l.0", "$l.end + 1 chars"];
			}
		}
		elsif ($d->[0] eq '+') {
			my $l = $d->[2] + $pads[2]; $pads[1]++;
			$tb->tagAdd('add', "$l.0", "$l.end + 1 chars");
			$ga->insert("$l.0", "\n", 'pad');
			$ta->insert("$l.0", "\n", 'pad');
			$map->createRectangle(0, $cy, 20, $cy+$lh-1, -tags => 'add');

			if ($prev eq $d->[0]) {
				# extend endpoint
				$loc[-1][1] = "$l.end + 1 chars";
			}
			else {
				# create new location
				push @loc, ["$l.0", "$l.end + 1 chars"];
			}
		}
		elsif ($d->[0] eq 'c') {
			if ($re) {
				# Provide detail on changes within the line.
				my $l1 = $d->[1] + $pads[1];
				my $l2 = $d->[2] + $pads[2];
				my $dx = [split($re, $ta->get("$l1.0", "$l1.end"))];
				my $dy = [split($re, $tb->get("$l2.0", "$l2.end"))];
				my @dd = Algorithm::Diff::sdiff($dx, $dy, $kg);
			
				if ($prev eq $d->[0]) {
					# extend endpoint
					$loc[-1][1] = "$l1.end + 1 chars";
				}
				else {
					# create new location
					push @loc, ["$l1.0", "$l1.end + 1 chars"];
				}

				my ($c1, $c2) = (0, 0);
				foreach my $d (@dd) {
					my $n1 = length $d->[1];
					my $n2 = length $d->[2];

					if ($d->[0] eq '-') {
						$ta->tagAdd('del', "$l1.$c1", "$l1.$c1 + $n1 chars");
					}
					elsif ($d->[0] eq '+') {
						$tb->tagAdd('add', "$l2.$c2", "$l2.$c2 + $n2 chars");
					}
					elsif ($d->[0] eq 'c') {
						$ta->tagAdd('mod', "$l1.$c1", "$l1.$c1 + $n1 chars");
						$tb->tagAdd('mod', "$l2.$c2", "$l2.$c2 + $n2 chars");
					}
					# else $d->[0] eq 'u' -- no change

					$c1 += $n1;
					$c2 += $n2;
				}

			}
			else {
				my $l1 = $d->[1] + $pads[1];
				my $l2 = $d->[2] + $pads[2];
				$ta->tagAdd('mod', "$l1.0", "$l1.0 lineend + 1 chars");
				$tb->tagAdd('mod', "$l2.0", "$l2.0 lineend + 1 chars");

				if ($prev eq $d->[0]) {
					# extend endpoint
					$loc[-1][1] = "$l1.end + 1 chars";
				}
				else {
					# create new location
					push @loc, ["$l1.0", "$l1.end + 1 chars"];
				}
			}
			$map->createRectangle(0, $cy, 20, $cy+$lh-1, -tags => 'mod');
		}

	} continue {
		$prev  = $d->[0];
		$cy   += $lh;
	}	
	$self->{_map}{height} = $cy;
	$self->{_map}{scale}  = 1;

	$self->{_diffloc} = \@loc;
	$self->{_current} = -1;

	$map->itemconfigure('del', @{$self->{_map}{colors}{del}});
	$map->itemconfigure('add', @{$self->{_map}{colors}{add}});
	$map->itemconfigure('mod', @{$self->{_map}{colors}{mod}});

	if ($self->{_map}{type} eq 'scaled') {
		# marker for current view
		my ($t, $b) = $self->Subwidget('text_a')->yview();
		$map->createRectangle(0, $t*$cy, 19, $b*$cy, -tags => 'view');
		$self->_rescale_map;
	}
	elsif ($self->{_map}{type} eq 'scrolled') {
		# scrollable region
		$map->configure(-scrollregion => [0, 0, 20, $cy+$lh]);
	}

	$ga->configure(-state => 'disabled');
	$gb->configure(-state => 'disabled');

	$self->{_scroll_lock} = 1;

}


#-------------------------------------------------------------------------------
# Subroutine : _sdiff
# Purpose    : Replacement for Algorithm::Diff::sdiff that returns indices of
#              sequences instead of copies of them. (This is to reduce memory
#              usage.)
# Notes      : Text widgets use 1 based indexing but we're tie()d to a
#              zero-based array
#-------------------------------------------------------------------------------
sub _sdiff {
	my $a = shift;
	my $b = shift;
	my $d = [];

	Algorithm::Diff::traverse_balanced($a, $b,
		{
			MATCH     => sub { push @$d, ['u', $_[0]+1, $_[1]+1] },
			DISCARD_A => sub { push @$d, ['-', $_[0]+1, undef  ] },
			DISCARD_B => sub { push @$d, ['+', undef,   $_[1]+1] },
			CHANGE    => sub { push @$d, ['c', $_[0]+1, $_[1]+1] },
		},
		@_
	);

	return wantarray ? @$d : $d;
}


#-------------------------------------------------------------------------------
# Subroutine : _make_sdiff_keygen
# Purpose    : Create a callback for tuning sdiff behavior based on options
# Notes      :
#-------------------------------------------------------------------------------
sub _make_sdiff_keygen {
	my %opt = 	(
		-whitespace => 1, # whitespace matters by default
		-case       => 1, # case matters by default
		@_
	);

	return sub {$_[0]} if ($opt{-case} && $opt{-whitespace});

	my $sub = 'sub { local $_ = $_[0]; ';
	$sub .= '$_ = lc $_; '                    if ! $opt{-case};
	$sub .= 's/^\s+//; s/\s+$//; tr/ \t/ /s;' if ! $opt{-whitespace};
	$sub .= 'return $_; }';

	return eval $sub;
}


#-------------------------------------------------------------------------------
# Method  : load
# Purpose : Load data into one of the text panes.
# Notes   : 
#-------------------------------------------------------------------------------
sub load {
	my $self  = $_[0];
	my $where = lc $_[1];
	my ($tw, $gw, $ta);
	my $ok = 1;

	unless ($where =~ /^[ab]$/) {
		carp("Invalid load destination '$_[1]'");
		return;
	}

	$self->{_scroll_lock} = 0;

	$self->Subwidget('canvas')->delete('all');
	$self->_reset_tags('a');
	$self->_reset_tags('b');

	$tw = $self->Subwidget("text_$where");
	$gw = $self->Subwidget("gutter_$where");
	$ta = $self->{_textarray}{$where};

	$gw->configure(-state => 'normal');
	$gw->delete('1.0', 'end');
	$tw->delete('1.0', 'end');

	$self->update();

	# Accept naive user input
	$_[2] = ${$_[2]} if ref $_[2] eq 'REF';  # \*FH{IO} instead of *FH{IO}
	$_[2] = *{$_[2]} if ref $_[2] eq 'GLOB'; # \*FH     instead of *FH

	if (ref $_[2]) {
		if (ref $_[2] eq 'ARRAY') {
			# assume lines of file data
			$tw->insert('end', $_) foreach @{$_[2]};
		}
		elsif ($_[2]->can('getline')) {
			# IO::File must be loaded for this to work
			while (my $x = $_[2]->getline) {
				$tw->insert('end', $x); # assume IO::File or equiv
			}
		}
		else {
			carp(sprintf("Don't know how to load from '%s' reference", ref $_[2]));
			$ok = 0;
		}
	}
	elsif ($_[2] =~ /^\*(\w*::)+\$?\w+$/) {
		# GLOB; assume open filehandle
		# copy to scalar so that <> interprets it as a filehandle
		# and not a glob pattern. cf. perlop - I/O Operators
		my $fh = $_[2];
		local $_;
		do { $tw->insert('end', $_) } while (<$fh>);
	}
	elsif ($_[2] =~ /\n/) {
		# assume contents of slurped file
		$tw->insert('end', $_[2]);
	}		
	else {
		# assume file name
		# Need two-arg open() for perls < v5.6
		# what version added open($fh...) in place of open(FH...)
		local *FH;
		if (open(FH, "< $_[2]")) {
			local $_;
			do { $tw->insert('end', $_) } while (<FH>);
			close(FH);
		}
		else {
			carp("Can't read file '$_[2]' [$!]");
			$ok = 0;
		}
	}

	if ($tw->get('end - 2 chars', 'end') ne "\n\n") {
		# The last line of file doesn't contain a newline. This horks up 
		# synchronized scrolling, so we add one to prevent that from happening.
		$tw->insert('end', "\n");
	}	

	my $n = $ok ? @$ta       :  0;
	my $w = $ok ? length($n) : -1;
	$gw->insert('end', sprintf("%${w}i\n", $_)) foreach (1 .. $n);
	$gw->configure(-width => $w + 1);
	$gw->configure(-state => 'disabled');

	$self->update();
	return $ok;
}


#-------------------------------------------------------------------------------
# Method  : _set_current
# Purpose : 
# Notes   : 
#-------------------------------------------------------------------------------
sub _set_current {
	my $self = shift;
	my $n    = shift; # index of diff to make current
	my $c    = $self->{_current};
	my $loc  = $self->{_diffloc};

	# clear current markers
	$self->Subwidget('text_a')->tagRemove('cur', @{$loc->[$c]});
	$self->Subwidget('text_b')->tagRemove('cur', @{$loc->[$c]});

	# set new markers
	$self->Subwidget('text_a')->tagAdd('cur', @{$loc->[$n]});
	$self->Subwidget('text_b')->tagAdd('cur', @{$loc->[$n]});

	# make difference visible
	$self->Subwidget('text_a')->see($loc->[$n][0]);

	# update index of current difference
	$self->{_current} = $n;
}


#-------------------------------------------------------------------------------
# Method  : first
# Purpose : Navigate to the first difference
# Notes   : 
#-------------------------------------------------------------------------------
sub first {
	my $self = shift;
	$self->_set_current(0) if @{$self->{_diffloc}};
}


#-------------------------------------------------------------------------------
# Method  : prev
# Purpose : Navigate to the previous difference
# Notes   : 
#-------------------------------------------------------------------------------
sub prev {
	my $self = shift;
	$self->_set_current($self->{_current} - 1) if $self->{_current} > 0;
}


#-------------------------------------------------------------------------------
# Method  : next
# Purpose : Navigate to the next difference
# Notes   : 
#-------------------------------------------------------------------------------
sub next {
	my $self = shift;
	$self->_set_current($self->{_current} + 1) if $self->{_current} < $#{$self->{_diffloc}};
}


#-------------------------------------------------------------------------------
# Method  : last
# Purpose : Navigate to the lat difference
# Notes   : 
#-------------------------------------------------------------------------------
sub last {
	my $self = shift;
	$self->_set_current($#{$self->{_diffloc}}) if $#{$self->{_diffloc}} >= 0;
}


#-------------------------------------------------------------------------------
# Method  : _rescale_map
# Purpose : Rescale the difference map canvas when the window is resized.
# Notes   : 
#-------------------------------------------------------------------------------
sub _rescale_map {
	my $self   = shift;
	return unless $self->{_map}{type} eq 'scaled';

	my $canvas = $self->Subwidget('canvas');
	my $wh     = $self->height;
	my $mh     = $self->{_map}{height} or return;
	my $cs     = $self->{_map}{scale};
	my $sf     = $wh > $mh ? 1 : $wh / $mh;

	$canvas->scale('all', 0, 0, 1, $sf/$cs);
	$self->{_map}{scale} = $sf;
}


#-------------------------------------------------------------------------------
# Subroutine : _get_map_colors
# Purpose    : Match colors use in map to text areas.
# Notes      : 
#-------------------------------------------------------------------------------
sub _get_map_colors {
	my $diffcolors = shift;
	my %mapcolors;

	foreach my $t ('mod', 'add', 'del') {
		my %x = @{$diffcolors->{$t}};
		my $c = $x{-background} || $x{-bg} || $x{-foreground} || $x{-fg};
		$mapcolors{$t} = [-outline => $c, -fill => $c];
	}
	return \%mapcolors;
}


#-------------------------------------------------------------------------------
# Subroutine : _mapjump
# Purpose    : recenter view on location from map
# Notes      : 
#-------------------------------------------------------------------------------
sub _mapjump {
	my ($canvas, $self, $x, $y) = @_;

	return unless $self->{_scroll_lock};

	my $w = $self->Subwidget('gutter_a');
	my $top;

	if ($self->{_map}{type} eq 'scaled') {
		my (undef, $y1, undef, $y2) = $canvas->coords('view');
		my $h  = $y2 - $y1;             # height of current view
		my $vh = $self->{_map}{height}; # virtual height of canvas
		my $sf = $self->{_map}{scale};  # canvas scale factor

		$top = ($y - $h/2) / ($vh * $sf);
	}
	elsif ($self->{_map}{type} eq 'scrolled') {
		my ($ct, undef) = $w->yview();               # current view
		my $ph = $self->Subwidget('canvas')->height; # physical height of canvas
		my $vh = $self->{_map}{height};              # virtual height of canvas

		$top = $ct + ($y - $ph/2) / $vh;
	}

	# limiter scrolling to valid range
	$top = 0 if $top < 0;
	$top = 1 if $top > 1;

	# cause the real motion by moving (just one!) of the scroll-locked widgets
	$w->yviewMoveto($top);
}


1;

__END__

=pod

=head1 NAME

Tk::DiffText - Perl/Tk composite widget for colorized diffs.

=head1 SYNOPSIS

  use Tk::DiffText;

  my $w = $mw->DiffText()->pack();

  $w->diff($file0, $file1);

=head1 DESCRIPTION

This module defines a composite widget that makes it simple to provide basic
"diff" functionality to your Tk applications.

=head1 OPTIONS

C<-orient =E<gt> 'horizontal'|'vertical'>

Controls the arrangement of the text panes. Defaults to B<vertical>.

C<-gutter =E<gt> 0|1>

Hides and displays the line number gutter. Defaults to B<1>.

C<-gutterforeground =E<gt> color>

Sets the gutter foreground color.

C<-gutterbackground =E<gt> color>

Sets the gutter background color.

C<-diffcolors =E<gt> {...}>

Sets the colors used for highlighting diff results. The structure of the
value hash is as follows:

  {
    add => [-fg => 'green'  ],               # tag for additions
    del => [-fg => 'red', -overstrike => 1], # tag for deletions
    mod => [-fg => 'blue'   ],               # tag for changes
    pad => [-bg => '#f0f0f0'],               # tag for blank line padding
    cur => [-bg => 'yellow'],                # tag for navigation
  }

For each of the tags you can specify any option that is valid for use in a 
ROText widget tag: -foreground, -background, -overstrike, etc.

C<-map =E<gt> 'scaled'|'scrolled'|'none'>

Controls the display and type of difference map. Defaults to B<scaled>.

The difference map will match its colors to those from C<-diffcolors> by 
default. It uses the background color if specified, otherwise it uses 
the foreground color.

=head1 METHODS

=head2 C<load>

  $w->load(a => I<data>);
  $w->load(b => I<data>);

Load I<data> into frames a (top or left) and b (bottom or right), respectively.

Normally I<data> is a filename but it can also be a reference to an array of 
lines of data, a string containing a slurped file, an open filehandle, a glob 
(which is interpreted as a filehandle), an IO::File object or any other object 
with a C<getline> method.

Returns true on success, false otherwise.

=head2 C<compare>

  $w->compare(
  	-case        => 0,
  	-whitespace  => 0,
  	-keygen      => \&makekey,
  	-granularity => 'line', # or 'word' 'char' or regexp
  );

Compares the data in the text frames and highlights the differences.

Setting either C<-case> or C<-whitespace> to 0 instructs the diff algorithm to 
ignore case and whitespace, respectively.

You can provide your own key generation function via the C<-keygen> argument. 
This overrides the C<-case> and C<-whitespace> options, so you'll have to build 
that functionality into your function if you want it. See L<Algorithm::Diff> for 
more details on key generation functions.

The C<-granularity> option controls the level of detail at which the diff is 
performed. The default value, 'line,' shows differences between lines. Changing 
it to 'word' or 'char' will show differences I<within> a line at the word or 
character level. You may also pass a C<qr//> quoted regular expression or a 
string which will be interpreted as a regular expression.

Note: For performance reasons, diffs are always performed line-by-line first. 
Finer granularity settings are only applied to lines marked as changed by the 
initial comparison. This can lead to slightly different results than you would 
get if you did a single diff at the higher level of resolution. (The results
aren't wrong, just different.)

=head2 C<diff> B<Deprecated>

  $w->diff($data1, $data2, -case => 0);

Equivalent to:

  $w->load(a => $data1);
  $w->load(b => $data1);
  $w->compare(-case => 0);

This method has been deprecated and may be removed in future versions.

=head2 C<first>

Highlights the first difference and scrolls to bring it in view.

=head2 C<prev>

Highlights the previous difference and scrolls to bring it in view.

=head2 C<next>

Highlights the next difference and scrolls to bring it in view.

=head2 C<last>

Highlights the last difference and scrolls to bring it in view.

=head1 NOTES

=head2 Unicode

Tk::DiffText supports Unicode provided that your versions of Perl (5.8+) and Tk 
(804+) do. To compare Unicode files, open the files with the appropriate IO 
layer and pass C<load> the filehandles.

  open(my $fha, '<:utf8', $file_a) or die;
  open(my $fhb, '<:utf8', $file_b) or die;
  
  $w->load(a => $fha);
  $w->load(b => $fhb);

=head1 BUGS

Some configuration settings (-gutter, -orient, -diffcolors, -map) are 
only valid at creation time and cannot be changed later.

The line numbers in the gutter can get out of sync with the file display if you 
set -wrap to something other than 'none' (so don't do that).

=head1 AUTHOR

Michael J. Carman <mjcarman@mchsi.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2008 by Michael J. Carman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
 