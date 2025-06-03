package Tk::ListBrowser;

=head1 NAME

Tk::ListBrowser - Tk::IconList inspired chameleon list box.

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION = '0.09';

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'ListBrowser';

use Math::Round;
use Tk;
require Tk::PopList;
require Tk::ListBrowser::Entry;
require Tk::ListBrowser::FilterEntry;
require Tk::ListBrowser::HashList;
require Tk::ListBrowser::Item;
require Tk::ListBrowser::LBCanvas;
require Tk::ListBrowser::LBHeader;
require Tk::ListBrowser::SideColumn;

#available refresh handlers
my %handlers = (
	bar => 'Bar',
	column => 'Column',
	list => 'List',
	hlist => 'HList',
	row => 'Row',
	tree => 'Tree',
);
my %columnCapable = (
	list => 1,
	hlist => 1,
	tree => 1,
);

my $minusimg = '#define indicatorclose_width 11
#define indicatorclose_height 11
static unsigned char indicatorclose_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xfd, 0x05,
   0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xff, 0x07 };
';

my $plusimg = '#define indicatoropen_width 11
#define indicatoropen_height 11
static unsigned char indicatoropen_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0xfd, 0x05,
   0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0x01, 0x04, 0xff, 0x07 };
';

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options)->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

B<Tk::ListBrowser> began as an inspiration on L<Tk::IconList>.
Nice, column oriented arrangement, but how about row oriented
arrangement. And while we are at it, also list bar hlist and tree
oriented arrangement. Scrollbars work automatically. Efforts have been
made to follow the conventions of the Tk hierarchical list
family as close as possible.

Screenshots:
L<https://www.perlgui.org/all/tklistbrowser-screenshots/>

This module features:

=head3 Arrange modes

Available arrange modes are 'bar', 'column', 'hlist', 'list'
and 'tree'. You can switch between arrange modes through the
I<-arrange> option while retaining data.

The 'hlist' and 'tree' modes provide a hierarchical list
interface. For it to work properly the I<-separator> option
must be set to a non empty string of one character.

=head3 Sorting

This module allows sorting your list on all kinds of paramenters,
like sorting on column, ascending or descending. Furthemore you 
can choose sort fields like '-data', '-name', or '-text'.

=head3 Headers

Headers are shown in the 'hlist', 'list' and 'tree' modes. You can
create and configure them in any mode. They are resizable and can
be made sortable. You can drag headers left or right with your
mouse to change the column ordering.

=head3 Side columns

Side columns are shown in the 'hlist', 'list' and tree modes. You can create and configure them in any mode.

=head3 Filtering

The keyboard shortcut CTFL+F opens a filter entry at the bottom of the widget. Filtering is case insensitive.
The filter will start updating when I<-filterdelay> milliseconds have past after your last keystroke.
You can choose which data to filter with the I<-filterfield> option. Filtering can be done on the main list
as well as on the side columns.

=head1 OPTIONS

Tk::ListBrowser uses the following standard options: B<-background>, B<-font>,
B<-foreground>, B<-selectbackground>, B<-selectforeground>. In addition the
following options are supported.

=over 4

=item Switch B<-arrange>

Default value I<row>. This option specifies the layout of your list. If you change this
option on the fly you have to call I<refresh> to see the changes. You can set the
following values:

=over 4

=item B<bar>

Presents a one row, horizontal list.

=item B<column>

Presents a column centered two dimensional list.

=item B<hlist>

Presents a L<Tk::HList> like hierarchical interface.

=item B<list>

Presents a one column vertical list.

=item B<row>

Presents a row centered two dimensional list.

=item B<tree>

Presents a L<Tk::Tree> like hierarchical interface.

=back

=item Switch B<-browsecmd>

Callback, called when an is selected. Gets the selection list as parameters.

=item Switch B<-command>

Callback, called when an entry is double clicked or return was pressed. Gets the selection list as parameters.

=item Switch B<-filtercolumns>

By default false. If you set it a button will appear
next to the filter entry that allows you to select
a column.

=item Name B<filterDelay>

=item Class B<FilterDelay>

=item Switch B<-filterdelay>

Default value 300 miliseconds. When the filter bar is active this is the wait time
between a keystroke and a corresponding filter action. If a key is pressed before
time out, the timer is reset.

=item Switch B<-filterfield>

Default value I<name>. Possible values are I<name>, I<text> and I<data>.
Specifies on what data the filter should work.

=item Switch B<-filterforce>

Default value I<false>. If set the filter entry will allways be visible.

=item Switch B<-filteron>

Default value I<main>, which is the main entry list. You may also set it to a valid column.

=item Name B<headerBorderWidth>

=item Class B<headerBorderWidth>

=item Switch B<-headerborderwidth>

Default value 2.

=item Name B<headerHeight>

=item Class B<HeaderHeight>

=item Switch B<-headerheight>

Default value 32.

=item Name B<headerRelief>

=item Class B<HeaderRelief>

=item Switch B<-headerrelief>

Default value 'raised'.

=item Switch B<-indicatorminusimg>

Specifies the image of the minus indicator when I<-arrange> is set to 'tree'.
By default an internal image is loaded.

=item Switch B<-indicatorplusimg>

Specifies the image of the plus indicator when I<-arrange> is set to 'tree'.
By default an internal image is loaded.

=item Name B<indent>

=item Class B<Indent>

=item Switch B<-indent>

Default value 22. Specifies the indent with  when I<-arrange> is set to 'hlist' or 'tree'.

=item Name B<itemPadX>

=item Class B<ItemPadX>

=item Switch B<-itempadx>

Internal padding in x direction in entries and column items.

=item Name B<itemPadY>

=item Class B<ItemPadY>

=item Switch B<-itempady>

Internal padding in y direction in entries and column items.

=item Switch B<-itemtype>

Default value I<imagetext>. Can be I<image>, I<imagetext> or I<text>.

=item Name B<marginBottom>

=item Class B<MarginBottom>

=item Switch B<-marginbottom>

Default value 0. Expands the scrollable canvas size on the bottom.

=item Name B<marginLeft>

=item Class B<MarginLeft>

=item Switch B<-marginleft>

Default value 0. Expands the scrollable canvas size to the left.

=item Name B<marginRight>

=item Class B<MarginRight>

=item Switch B<-marginright>

Default value 0. Expands the scrollable canvas size to the right.

=item Name B<marginTop>

=item Class B<MarginTop>

=item Switch B<-margintop>

Default value 0. Expands the scrollable canvas size to the top.

=item Switch B<-motionselect>

Default value I<false>. Only works when I<-selectmode> is set to single.
Automatically selects an entry when the pointer is hovering over it.

=item Switch B<-nofilter>

Default value I<false>. If set the filter entry is not available.
This option supercedes the I<-filterforce> option.

=item Switch B<-refreshentriespercycle>

Default value 10. Specifies how many entries are refreshed during
one refresh loop cycle.

=item Switch B<-refreshinterval>

Default value 1 milisecond. Specifies the interval between refresh
loop cycles.

=item Switch B<-selectmode>

Default value I<single>. Can either be I<single> or I<multiple>.
In single mode only one entry in the list can be selected at all times.
In multiple mode more than one entry can be selected.

=item Switch B<-selectstyle>

Default value I<anchor>. Can either be I<anchor> or I<simple>.
This option specifies how the arrow keys work. When set to anchor,
the arrow keys only move the anchor, space or enter will select. 
When set to simple the arrow keys also make a single mode selection.

=item Switch B<-separator>

Default value is an empty string. When set to one character, hierarchy mode is enabled.
When I<-arrange> is set to any other than 'hlist' or 'tree', only the root list is shown when hierarchy
mode is enabled.

=item Switch B<-sortbottom>

Default value -(10**32). Used while sorting whenever a column item is found that requires
numerical sort, but the item itself is not defined. A ridiculous low value is used instead.
Are you handling even lower numbers? You can adjust it here.

=item Switch B<-sortcase>

Default value false. You can set it if you require case independent sort.

=item Switch B<-sortfield>

Default value '-name'. Possible values are '-name', '-text' and '-data'.
Specifies which attribute of an entry is used for sorting.

=item Switch B<-sortnumerical>

Default value false. You can set it if you require numerical sorting.

=item Switch B<-sorton>

Default value is an empty string. That means sorting is done on the main entry list.
You can set it to a column name for sorting on column content.

=item Switch B<-sortorder>

Default value 'ascending'.

=item Switch B<-textanchor>

Default value empty string. This value centers the text in it's cativy.
Besides an empty string the possible values are I<n>, I<ne>, I<nw>, I<s>,
I<se>, I<sw>, I<e> and I<w>. The letters stand for the first letter of the
wind directions. They tell where to position the text in it's cavity.

=item Switch B<-textjustify>

Default value I<center>. Can be I<center>, I<left> or I<right>. Specifies
how multiline or wrapped text is justified.

=item Switch B<-textside>

Default value I<bottom>. Possible values are I<bottom>, I<top>, I<left>, I<right>,
or I<none>. It sets at which side the text should appear next to the icon.
If you change this option on the fly you have to call I<refresh>
to see the changes. This option only has meaning when I<-itemtype> is set to 'imagetext'.

=item Switch B<-wraplength>

Default value 0. You can set it to a positive integer of at least 40 to invoke word or
character wrapping. The value determines the maximum width in pixels of a text block. It
will attempt a word wrap and will do a character wrap if that fails.

If you change this option on the fly you have to call I<refresh> to see the changes. 

If you try to set it to a lower value than 40, you will be overruled.
This is to prevent the wrap length to become smaller that the with of one character, which
would freeze you application. This also means watching out for using very big fonts.

=back

=cut

=head1 STANDARD OPTIONS

A number of the options above can also be used when you call the
I<add>, I<columnCreate>, I<add> and I<itemCreate> methods.
These are I<-background>, I<-font>, I<-foreground>, I<-itempadx>,
I<-itempady>, I<-itemtype>, I<-textanchor>, I<-textjustify>,
I<-textside>, and I<-wraplength>.

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	
	#create the canvas
	my $canv = $self->Scrolled('LBCanvas',
		-keycall => ['KeyPress', $self],
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	my $c = $canv->Subwidget('scrolled');
	$c->configure(
		-takefocus => 1,
	);

	#horizontal scroll for headers
	my $xscroll = $canv->Subwidget('xscrollbar');
	$self->Advertise('XScrollbar', $xscroll);
	my $call = $xscroll->cget('-command');
	$xscroll->configure(
		-command => sub {
			$call->Call(@_);
			$self->headerPlace;
		}
	);
	
	#keep track of verticle scroll
	my $yscroll = $canv->Subwidget('yscrollbar');
	$self->Advertise('YScrollbar', $yscroll);

	$self->Advertise('Canvas', $c);
	
	#create the header frame;
	my $hf = $c->Frame;
	$self->Advertise('HeaderFrame', $hf);

	#mouse bindings
	$c->Tk::bind('<Button-1>', [ $self, 'Button1', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<Control-Button-1>', [ $self, 'Button1Control', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<Double-Button-1>', [ $self, 'Button1Double', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<Shift-Button-1>', [ $self, 'Button1Shift', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<Control-f>', [$self, 'filterFlip']);
	$c->Tk::bind('<Button-2>', [ $self, 'Button2', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<B2-Motion>', [ $self, 'Button2Motion', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<ButtonRelease-2>', [ $self, 'Button2Release', Ev('x'), Ev('y') ]);
	$c->Tk::bind('<Motion>', [ $self, 'Motion', Ev('x'), Ev('y') ]);

	$self->{ARRANGE} = undef;
	$self->{COLUMNS} = [];
	$self->{HANDLER} = undef;
	$self->{INDENT} = 0;
	$self->{POOL} = new Tk::ListBrowser::HashList;
	$self->{PRIORITYMAX} = 0;
	$self->{REFRESHLOOPACTIVE} = 0;
	$self->{REFRESHPOS} = 0;
	$self->{SORTACTIVE} = '';

	$self->bind('<Configure>', [ $self, 'OnConfigure' ]);

	my $minusbmp = $self->Bitmap(-data => $minusimg);
	my $plusbmp = $self->Bitmap(-data => $plusimg);
	$self->ConfigSpecs(
		#general
		-arrange => ['METHOD', undef, undef, 'row'],
		-browsecmd => ['CALLBACK'],
		-command => ['CALLBACK'],
		-font => ['PASSIVE', 'font', 'Font', 'Arial 9'],
		-indent => ['PASSIVE', 'indent', 'Indent', 22],
		-motionselect => ['PASSIVE', undef, undef, ''],
		-refreshentriespercycle => ['PASSIVE', undef, undef, 10],
		-refreshinterval => ['PASSIVE', 'refreshInterval', 'RefreshInterval', 1],
		-scrollregion => [$c],
		-selectmode => ['PASSIVE', undef, undef, 'single'],
		-selectstyle => ['PASSIVE', undef, undef, 'anchor'],
		-separator => ['PASSIVE', undef, undef, ''],

		#colors
		-background => [$c, 'background', 'Background', '#E8E8E8'],
		-foreground => [$c, 'foreground', 'Foreground', '#3C3C3C'],
		-selectbackground => ['PASSIVE', 'selectBackground', 'SelectBackground', '#A0A0FF'],
		-selectforeground => ['PASSIVE', 'selectForeground', 'SelectForeground', '#FAF9EA'],

		#filter
		-nofilter => ['PASSIVE', undef, undef, ''],
		-filtercolumns => ['PASSIVE', undef, undef, ''], #boolean
		-filterdelay => ['PASSIVE', undef, undef, 300], #boolean
		-filterfield => ['PASSIVE', undef, undef, 'name'],
		-filterforce => ['PASSIVE', undef, undef, ''], #boolean
		-filteron => ['PASSIVE', undef, undef, 'main'],

		#headers
		-headerborderwidth => ['PASSIVE', 'headerBorderWidth', 'HeaderBorderWidth', 2],
		-headerheight => ['PASSIVE', 'headerHeight', 'HeaderHeight', 32],
		-headerrelief => ['PASSIVE', 'headerRelief', 'HeaderRelief', 'raised'],

		#indicators
		-indicatorminusimg => ['PASSIVE', undef, undef, $minusbmp],
		-indicatorplusimg => ['PASSIVE', undef, undef, $plusbmp],

		#items
		-itempadx => ['PASSIVE', 'itemPadX', 'ItemPadX', 2],
		-itempady => ['PASSIVE', 'itemPadY', 'ItemPadY', 0],
		-itemtype => ['PASSIVE', undef, undef, 'imagetext'],

		#margins
		-marginleft => ['PASSIVE', 'marginLeft', 'MarginLeft', 0],
		-marginright => ['PASSIVE', 'marginRight', 'MarginRight', 0],
		-margintop => ['PASSIVE', 'marginTop', 'MarginTop', 0],
		-marginbottom => ['PASSIVE', 'marginBottom', 'MarginBottom', 0],

		#sort
		-sortbottom => ['PASSIVE', undef, undef, -(10**32)],
		-sortcase => ['PASSIVE', undef, undef, 'name'],
		-sortfield => ['PASSIVE', undef, undef, 'name'],
		-sorton => ['PASSIVE', undef, undef, ''],
		-sortnumerical => ['PASSIVE', undef, undef, ''], #boolean
		-sortorder => ['PASSIVE', undef, undef, 'ascending'],

		#text
		-textanchor => ['PASSIVE', undef, undef, ''],
		-textjustify => ['PASSIVE', undef, undef, 'center'],
		-textside => ['PASSIVE', undef, undef, 'bottom'],
		-wraplength => ['METHOD', undef, undef, 0],

		DEFAULT => [ $self ],
	);
	$self->Delegates(

		#canvas
		CanvasFocus => $c,
		canvasx => $c,
		canvasy => $c,
		createImage => $c,
		createRectangle => $c,
		createText => $c,
		xview => $c,
		yview => $c,
		xviewScroll => $c,
		yviewScroll => $c,

		DEFAULT => $self,
	);
	$self->after(1, sub {
		my @bmpopt = (-foreground => $c->cget('-foreground'), -background => $c->cget('-background'));
		for ($plusbmp, $minusbmp) {
			$_->configure(@bmpopt)
		};
	});
	return $self
}

sub _handler { return $_[0]->{HANDLER} }

=item B<add>I<(?$name?, %options)>

Adds I<$name> to the list with I<%options>. I<$name> must not yet exist.
If you do not specify standard options, the main settings
will be used. Besides the standard options you can also use:

=over 4

=item B<-after>

Insert I<$name> after the entry name held by this option.

=item B<-before>

Insert I<$name> before the entry name held by this option.

=item B<-data>

Assign an arbitray scalar value to this entry.

=item B<-hidden>

Tag the entry as hidden. If you do not specify this option
the entry is shown after I<refresh>

=item B<-image>

A valid L<Tk::Image> class assigned to this entry.

=item B<-priority>

Default priority is 0. Entries with the highest priorities are shown first.

=item B<-text>

Text assigned to this entry.

=back

After a call to I<add> you must call I<refresh> to see your changes.
Returns a reference to the created item object.

=cut

sub add {
	my ($self, $name, %options) = @_;
	if ($self->infoExists($name)) {
		croak "Entry '$name' already exists";
		return
	}

	my $sep = $self->separator;
	my $after = $options{'-after'};
	my $before = $options{'-before'};
	my $parent;
	my @c;

	my $priority = $options{'-priority'};
	$priority = 0 unless defined $priority;
	$self->prioritySet($priority);


	#some show stoppers
	if ((defined $after)  and (not $self->infoExists($after))) {
		croak "Invalid -after option. Entry $after does not exist";
		return
	}
	if ((defined $before)  and (not $self->infoExists($before))) {
		croak "Invalid -before option. Entry $before does not exist";
		return
	}

	if ($sep ne '') { #hierarchy
		if (my $parent = $self->decodeParent($name)) {
			#some show stoppers
			unless ($self->infoExists($parent)) {
				croak "Parent for $name does not exist";
				return
			}
			if (my $a = $options{'-after'}) {
				my $p = $self->infoParent($a);
				if ($p ne $parent) {
					croak "Invalid '-after' option, $name and $a do not share the same parent";
					return
				}
			}
			if (my $b = $options{'-before'}) {
				my $p = $self->infoParent($b);
				if ($p ne $parent) {
					croak "Invalid '-before' option, $name and $b do not share the same parent";
					return
				}
			}

			#go to work
			if ((defined $after) and ($self->get($after)->priority eq $priority)) {
				#do nothing
			} elsif ((defined $before) and ($self->get($before)->priority eq $priority)) {
				#do nothing
			} else {
				my @c = $self->infoChildren($parent);
				my ($pos, $peer) = $self->addGrep($priority, '-after', \@c);
				if (defined $pos) {
					$options{$pos} = $peer;
				} else {
					my $last = $self->infoLastOffspring($parent);
					if (defined $last) {
						$options{'-after'} = $last;
					} else {
						$options{'-after'} = $parent
					}
				}
			}
		} else { #no parent found
			my @c = $self->infoRoot;
			my ($pos, $peer) = $self->addGrep($priority, '-before', \@c);
			if (defined $pos) {
				$options{$pos} = $peer;
			}
		}
	} else { #no hierarchy
		if ($self->priorityMax) {
			my @c = $self->infoList;
			my ($pos, $peer) = $self->addGrep($priority, '-after', \@c);
			if (defined $pos) {
				$options{$pos} = $peer;
			}
		}
	}

	$after = delete $options{'-after'};
	$before = delete $options{'-before'};

	my $item = new Tk::ListBrowser::Entry(
		%options,
		-listbrowser => $self,
		-name => $name,
	);
	my $pool = $self->pool;
	my $index;
	if (defined $after) {
		$index = $self->index($after)+ 1;
	} elsif (defined $before) {
		$index = $self->index($before);
	}
	$pool->add($item, $index);
	return $item
}

sub addGrep {
	my ($self, $priority, $pos, $l) = @_;
	my @list = @$l;
	my @g = grep {$priority > $self->get($_)->priority } @list;
	if (@g) {
		my $i = shift @g;
		return ('-before', $self->get($i)->name);
	}
	my @le = grep { $priority <= $self->get($_)->priority } @list;
	if (@le) {
		my $i = $list[@le + 1];
#		my $i = pop @le;
		return ($pos, $self->get($i)->name) if defined $i;
	}
	return ()
}

sub anchor {
	my $self = shift;
	my $a = $self->{ANCHOR};
	unless (defined $a) {
		$a = $self->createRectangle(0, 0, 1, 1,
			-fill => undef,
			-dash => [3, 2],
		);
		$self->{ANCHOR} = $a
	}
	return $a
}


=item B<anchorClear>

Clears the keyboard anchor.

=cut

sub anchorClear {
	my $self = shift;
	my @pool = $self->getAll;
	for (@pool) {
		$_->anchor(0)
	}
}
=item B<anchorGet>

Returns a reference to the L<Tk::ImageBrowser::Icon> object
that currently holds the anchor.

=cut

sub anchorGet {
	my $self = shift;
	my @pool = $self->getAll;
	for (0 .. @pool - 1) {
		my $obj = $pool[$_];
		return $obj if $obj->anchored
	}
	return undef
}

sub anchorInitialize {
	my $self = shift;
	my $i = $self->anchorGet;
	unless (defined $i) {
		my $a = $self->anchor;
		my $name = $self->infoFirstVisible;
		$self->anchorSet($name) unless defined $self->anchorGet;
		$self->selectionSingle($name) if $self->cget('-selectstyle') eq 'simple';
		$self->see($name);
		return 1
	}
	return ''
}

sub anchorRefresh {
	my $self = shift;
	my $a = $self->anchorGet;
	$a->drawAnchor if defined $a;
}

=item B<anchorSet>I<($name)>

Sets the keyboard anchor to I<$name>

=cut

sub anchorSet {
	my ($self, $name) = @_;
	my $item = $self->get($name);
	if ((defined $item) and (not $item->hidden)) {
		$self->anchorClear;
		$item->anchor(1);
		return 1
	}
	return ''
}

sub anchorSetColumnRow {
	my ($self, $column, $row) = @_;
	my $index = $self->indexColumnRow($column, $row);
	if (defined $index) {
		return $self->anchorSet($self->getIndex($index)->name);
	}
	return ''
}

sub arrange {
	my $self = shift;
	if (@_) {
		my $arr = shift;
		my $mod = $handlers{$arr};
		unless (defined $mod) {
			croak "Invalid handler $arr";
			return
		}
		$self->{ARRANGE} = $arr;
		my $modname = "Tk::ListBrowser::$mod";
		my $error = '';
		eval "use $modname;";
		my $hf = $self->Subwidget('HeaderFrame');
		if (($arr eq 'row') or ($arr eq 'column')) {
			$self->headerClear;
		} else {
			$self->headerPlace;
		}
		$error = $@;
		unless ($error) {
			$self->clear;
			my $h = $modname->new($self);
			$self->{HANDLER} = $h;
		} else {
			croak $error
		}
	}
	return $self->{ARRANGE}
}

sub Button1 {
	my ($self, $x, $y) = @_;
	$self->CanvasFocus;
	my $c = $self->Subwidget('Canvas');

	#return if an indicator was clicked
	my @ind = $c->find('withtag', 'indicator');
	for (@ind) {
		my ($ix, $iy) = $c->coords($_);
		my $img = $self->cget('-indicatorplusimg');
		my $half = int($img->width / 2) + 2;
		my ($x1, $y1, $x2, $y2) = $c->coords($_);
		return if ($ix - $half <= $x) and ($ix + $half >= $x)
			and ($iy - $half <= $y) and ($iy + $half >= $y);
	}

	my $item = $self->initem($x, $y);
	if (defined $item) {
		$self->selectionClear;
		$item->select(1);
		$self->anchorSet($item->name);
		$self->Callback('-browsecmd', $item->name);
		return
	} else {
		$self->selectionClear;
	}
}

sub Button1Control {
	my ($self, $x, $y) = @_;
	return $self->Button1($x, $y) if $self->cget('-selectmode') eq 'single';
	my $item = $self->initem($x, $y);
	if (defined $item) {
		if ($item->selected) {
			$item->select(0)
		} else {
			$item->select(1)
		}
		$self->anchorSet($item->name);
	} else {
		$self->selectionClear;
	}
}

sub Button1Double {
	my ($self, $x, $y) = @_;
	my $item = $self->initem($x, $y);
	if (defined $item) {
		$self->Callback('-command', $item->name);
	} else {
		$self->selectionClear;
	}
}

sub Button1Shift {
	my ($self, $x, $y) = @_;
	return $self->Button1($x, $y) if $self->cget('-selectmode') eq 'single';
	my $item = $self->initem($x, $y);
	if (defined $item) {
		my @pool = $self->getAll;
		$self->anchorSet($item->name);
		my @sel = $self->selectionGet;
		unless (@sel) {
			my $start = $pool[0]->name;
			$self->selectionSet($pool[0]->name, $item->name);
			return
		}
		if ($self->index($item->name) < $self->index($sel[0])) {
			$self->selectionSet($item->name, $sel[0]);
			return
		}
		if ($self->index($item->name) > $self->index($sel[@sel - 1])) {
			$self->selectionSet($sel[@sel - 1], $item->name);
			return
		}
		$self->selectionClear;
	}
}

sub Button2 {
	my ($self, $x, $y) = @_;
	$self->configure(-cursor => 'fleur');
	$self->{'mouse_pos'} = [$x, $y];
}

sub Button2Motion {
	my ($self, $x, $y) = @_;

	my $mousepos = $self->{'mouse_pos'};
	my ($mx, $my) = @$mousepos;
	$self->{'mouse_pos'} = [$x, $y];

	my $dx = $mx - $x;
	my $dy = $my - $y;

	$self->xviewScroll(-$dx, 'units') if $self->_handler->scroll eq 'horizontal';
	$self->yviewScroll(-$dy, 'units') if $self->_handler->scroll eq 'vertical';
}

sub Button2Release {
	my $self = shift;
	$self->configure(-cursor => 'arrow');
	delete $self->{'mouse_pos'};
}

sub canvasSize {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	my $offset = $c->cget('-highlightthickness') + $c->cget('-borderwidth');
	return ($self->width - $offset, $self->height - $offset);
}

sub cellHeight {
	my $self = shift;
	$self->{CELLHEIGHT} = shift if @_;
	return $self->{CELLHEIGHT}
}

sub cellImageHeight {
	my $self = shift;
	$self->{IMAGEHEIGHT} = shift if @_;
	return $self->{IMAGEHEIGHT}
}

sub cellImageWidth {
	my $self = shift;
	$self->{IMAGEWIDTH} = shift if @_;
	return $self->{IMAGEWIDTH}
}

sub cellTextHeight {
	my $self = shift;
	$self->{TEXTHEIGHT} = shift if @_;
	return $self->{TEXTHEIGHT}
}

sub cellTextWidth {
	my $self = shift;
	$self->{TEXTWIDTH} = shift if @_;
	return $self->{TEXTWIDTH}
}


sub cellWidth {
	my $self = shift;
	$self->{CELLWIDTH} = shift if @_;
	if ($self->columnCapable) {
		my $fw = $self->forceWidth;
		return $fw if defined $fw;
	}
	return $self->{CELLWIDTH}
}

=item B<clear>

Clears the display. Does not delete data.

=cut

sub clear {
	my $self = shift;

	$self->anchorClear;
	$self->selectionClear;

	grep { $_->clear } $self->getAll;

	my @columns = $self->columnList;
	for (@columns) {
		$self->columnGet($_)->clear;
	}

	my $c = $self->Subwidget('Canvas');
	$c->xview(moveto => 0);
	$c->yview(moveto => 0);
	$c->configure(-scrollregion => [0, 0, 0, 0]);
}

=item B<close>I<($entry)>

Hides all children of $entry.
Call I<refresh> or I<refreshPurge> to see changes.

=cut

sub close {
	my ($self, $entry) = @_;
	my $i = $self->get($entry);
	unless (defined $i) {
		croak "Entry $entry not found";
		return
	}
	$i->opened(0);
}

=item B<closeAll>

Closes all entries.
Call I<refresh> or I<refreshPurge> to see changes.

=cut

sub closeAll {
	my $self = shift;
	my @list = $self->infoList;
	for (@list) {
		$self->close($_) if $self->infoChildren($_);
	}
}

=item B<columnCapable>

Returns true if I<-arrange> is set to 'hlist', 'list' or 'tree'.

=cut

sub columnCapable {
	my $self = shift;
	return exists $columnCapable{$self->cget('-arrange')}
}

=item B<columnCget>I<($name, $option)>

Returns the value of $option in column $name

=cut

sub columnCget {
	my ($self, $name, $option) = @_;
	my $col = $self->columnGet($name);
	unless (defined $col) {
		croak "Column '$name' not found";
		return
	}
	return $col->cget($option)
}

=item B<columnConfigure>I<($name, %options)>

Configures options in column I<$name>.

=cut

sub columnConfigure {
	my ($self, $name, %options) = @_;
	my $col = $self->columnGet($name);
	unless (defined $col) {
		croak "Column '$name' not found";
		return
	}
	for (keys %options) {
		$col->configure($_, $options{$_})
	}
}

=item B<columnCreate>I<($name, %options)>

Creates a new side column object. Besides the standard options
you can use the following:

=over 4

=item B<-after>

Specify a column name.

=item B<-before>

Specify a column name.

=back

=cut

sub columnCreate {
	my ($self, $name, %options) = @_;

	if ($self->columnExists($name)) {
		croak "Column '$name' already exists";
		return
	}

	my $after = delete $options{'-after'};
	my $before = delete $options{'-before'};
	my $item = new Tk::ListBrowser::SideColumn(
		%options,
		-listbrowser => $self,
		-name => $name,
	);
	my $columns = $self->{COLUMNS};
	if (defined $after) {
		my $index = $self->columnIndex($after);
		splice(@$columns, $index + 1, 0, $item) if defined $index;
		croak "Column for -after '$after' not found" unless defined $index;
	} elsif (defined $before) {
		my $index = $self->columnIndex($before);
		splice(@$columns, $index, 0, $item) if defined $index;
		croak "Column for -before '$before' not found" unless defined $index;
	} else {
		push @$columns, $item
	}
	return $item
}

=item B<columnExists>I<($name)>

Returns true if column $name exists.

=cut

sub columnExists {
	my ($self, $name) = @_;
	my $columns = $self->{COLUMNS};
	my @hit = grep { $_->name eq $name } @$columns;
	return defined $hit[0]
}

=item B<columnGet>I<($name)>

Returns a reference to the L<Tk::ListBrowser::SideColumn> object of I<$name>.

=cut

sub columnGet {
	my ($self, $name) = @_;
	my $columns = $self->{COLUMNS};
	my @hit = grep { $_->name eq $name } @$columns;
	croak "Column '$name' not found" unless @hit;
	return $hit[0]
}

=item B<columnIndex>I<($name)>

Returns the place of column I<$name> inf the viewing order. The first one has index 0.

=cut

sub columnIndex {
	my ($self, $name) = @_;
	my $columns = $self->{COLUMNS};
	my ($index) = grep { $columns->[$_]->name eq $name } 0 .. @$columns - 1;
	return $index
}

=item B<columnList>

Returns the names all available columns.

=cut

sub columnList {
	my $self = shift;
	my $columns = $self->{COLUMNS};
	my @l;
	for (@$columns) {
		push @l, $_->name
	}
	return @l
}

=item B<columnMove>I<($column, $index)>

Moves $column to $index.

=cut

sub columnMove {
	my ($self, $column, $index) = @_;
	my $columns = $self->{COLUMNS};
	return if $index > @$columns - 1;
	return if $index < 0;
	my $place = $self->columnIndex($column);
	my $t = splice(@$columns, $place, 1);
	splice(@$columns, $index, 0, $t);
}

sub columnNext {
	my ($self, $name) = @_;
	my $columns = $self->{COLUMNS};
	my $next;
	if ($name eq '') {
		my $col = $columns->[0];
		$next = $col->name if defined $col;
	} else {
		my $i = $self->columnIndex($name);
		$next = $columns->[$i + 1];
		$next = $next->name if defined $next
	}
	return $next;
}

=item B<columnRemove>I<($name)>

Removes column I<$name> and all its associated data.

=cut

sub columnRemove {
	my ($self, $name) = @_;
	my $columns = $self->{COLUMNS};
	my $index = $self->columnIndex($name);
	if (defined $index) {
		my ($del) = splice(@$columns, $index, 1);
		$del->clear;
		return
	}
	croak "Column '$name' not found"
}

=item B<columnWidth>I<($name, $width)>

By default the main list and all side columns are sized so no information
is lost and no unused space is created. The widths may vary when you add,
remove or modify data. Once you make a call to this method the width of
the column or main list becomes fixed. This works exactly as in L<Tk::HList>.

Specify I<$name> as an empty string for the main list. Otherwise specify a
column name.

=cut

sub columnWidth {
	my ($self, $col, $width) = @_;
	if ($col eq '') {
		$self->forceWidth($width)
	} else {
		my $c = $self->columnGet($col);
		$c->forceWidth($width)
	}
}

sub decodeParent {
	my ($self, $name) = @_;
	my $sep = $self->separator;
	$sep = quotemeta($sep);
	my $parent;
	if ($name =~ /$sep/) {
		$name =~ /^(.*)$sep/;
		$parent = $1 if defined $1;
	}
	return $parent
}

=item B<delete>I<(?$name?)>

Deletes entry I<$name>. Call I<refresh> or refreshPurge to see your changes.

=cut

sub delete {
	my ($self, $name) = @_;
	my $index = $self->index($name);
	if (defined $index) {
		my $pool = $self->pool;
		my $del = $pool->delete($name);
		$del->clear;
		my @columns = $self->columnList;
		for (@columns) {
			$self->itemRemove($name, $_);
		}
		return
	}
	croak "Entry '$name' not found"
}

=item B<deleteAll>

Deletes all entries. Call I<refresh> or I<refreshPurge> to see your changes.

=cut

sub deleteAll {
	my $self = shift;
	my $pool = $self->pool;
	grep { $self->delete($_->name) } $pool->getAll;
}

=item B<entryCget>I<($name, $option)>

Returns the value of I<$option> held by $name. Valid
options are I<-data>, I<-hidden>, I<-image> and I<-text>.

=cut

sub entryCget {
	my ($self, $name, $option) = @_;
	my $i = $self->get($name);
	unless (defined $i) {
		croak "Entry '$name' not found";
		return
	}
	my $val = $i->cget($option);
	if (exists $self->{'insort'}) {
		unless (defined $val) {
			if ($self->cget('-sortnumerical')) {
				$val = $self->cget('-sortbottom')
			} else {
				$val = ''
			}
		}
	}
	return $val
}

=item B<entryConfigure>I<($name, %options)>

Sets the value of I<%options> held by $name. Valid
options are I<-data>, I<-hidden>, I<-image> and I<-text>.
You can specify multiple options.

=cut

sub entryConfigure {
	my ($self, $name, %options) = @_;
	my $i = $self->get($name);
	unless (defined $i) {
		croak "Entry '$name' not found";
		return
	}
	for (keys %options) {
		$i->configure($_, $options{$_})
	}
}

sub filter {
	my ($self, $filter, $value) = @_;
	return 1 if $filter eq '';
	return '' unless (defined $value) and ($value ne '');
	$filter = quotemeta($filter);
	return 1 if $value eq '';
	return $value =~ /$filter/i;
}

sub filterFlip {
	my $self = shift;
	return if $self->cget('-nofilter');
	my $f = $self->Subwidget('FilterFrame');
	if ((defined $f) and ($f->ismapped)) {
		unless ($self->cget('-filterforce')) {
			$self->filterHide;
			$self->CanvasFocus;
		}
	} else {
		$self->filterShow;
		my $e = $self->Subwidget('FilterEntry');
		$e->focus;
	}
}

sub filterHide {
	my $self = shift;
	return if $self->cget('-nofilter');
	my $e = $self->Subwidget('FilterEntry');
	my $f = $self->Subwidget('FilterFrame');
	$e->delete(0, 'end');
	$self->filterRefresh;
	$f->packForget;
}

sub filterRefresh {
	my $self = shift;
	my @pool = $self->getAll;
	my $filter = $self->Subwidget('FilterEntry')->get;
	my $filterfield = $self->cget('-filterfield');
	my $filteron = $self->cget('-filteron');
	for (@pool) {
		my $item;
		if ($filteron eq 'main') {
			$item = $_;
			$filterfield = $self->cget('-filterfield');
		} else {
			$filterfield = $self->columnCget($filteron, '-filterfield');
			$item = $self->itemGet($_->name, $filteron);
		}
		if ($self->filter($filter, $item->$filterfield)) {
			$_->hidden('');
			if ($self->hierarchy) {
				my $par = $self->infoParent($_->name);
				while (defined $par) {
					my $p = $self->get($par);
					$p->hidden('');
					$par = $self->infoParent($p->name);
				}
			}
		} else {
			$_->hidden(1)
		}
	}
	delete $self->{'filter_id'};
	$self->refreshPurge(0);
}

sub filterShow {
	my $self = shift;
	return if $self->cget('-nofilter');

	my $f = $self->Subwidget('FilterFrame');
	unless (defined $f) {
		$f = $self->Frame;
		$self->Advertise('FilterFrame', $f);
	}

	my $e = $self->Subwidget('FilterEntry');
	my $flag = 1;
	unless (defined $e) {
		$e = $f->FilterEntry(
			-filterdelay => $self->cget('-filterdelay'),
			-command => ['filterRefresh', $self],
		)->pack(-side => 'left', -pady => 2, -expand => 1, -fill => 'x');
		$flag = '';
		$self->Advertise('FilterEntry', $e);
		$e->bind('<Control-f>', [$self, 'filterFlip']);
		$e->bind('<Escape>', [$self, 'filterFlip']);
	}
	$e->reset if $flag;

	my $cf = $self->Subwidget('FilterColumn');
	if ($self->cget('-filtercolumns')) {
		unless (defined $cf) {
			my @menu = ();
			my $filteron = $self->cget('-filteron');
			$cf = $f->Frame;
			$cf->Label(-text => 'On:')->pack(-side => 'left');
			my $fl;
			my $fb = $cf->Button(
				-command => sub {
					my @list = ('main', $self->columnList);
					$fl->configure(-values => \@list);
					$fl->popUp;
				},
				-textvariable => \$filteron,
				-relief => 'flat'
			)->pack(-side => 'right');
			$fl = $self->PopList(
				-relief => 'raised',
				-popdirection => 'up',
				-confine => 1,
				-selectcall => sub {
					$filteron = shift;
					$self->configure(-filteron => $filteron)
				},
				-widget => $fb,
			);
			$self->Advertise('FilterColumn', $cf);
		}
		$cf->pack(-side => 'left');
	} else {
		$cf->packForget if defined $cf;
	}
	$f->pack(-fill => 'x');
}

sub focus { $_[0]->CanvasFocus }

sub forceWidth {
	my $self = shift;
	$self->{FORCEWIDTH} = shift if @_;
	return $self->{FORCEWIDTH}
}

=item B<get>I<(?$name?)>

Returns a reference to the L<Tk::ListBrowser::Icon> object of I<$name>.

=cut

sub get {
	my ($self, $name) = @_;
	return $self->pool->get($name)
}

=item B<getAll>I<(?$name?)>

Returns a list of all L<Tk::ListBrowser::Item> objects.

=cut

sub getAll { return $_[0]->pool->getAll }

=item B<getChildren>I<(?$parent?)>

Returns a list of L<Tk::ListBrowser::Item> objects that are children of I<$parent>.

=cut

sub getChildren {
	my ($self, $name) = @_;
	my $sep = quotemeta($self->cget('-separator'));
	my $test = quotemeta($name) . $sep;
	my @pool = $self->getAll;
	my @r;
	my $index = $self->index($name) + 1;
	return @r if $index > $self->indexLast;
	my $item = $self->getIndex($index);
	my $nm = $item->name;
	while ($nm =~/^$test(.*)/) {
		push @r, $item unless $1 =~ /$sep/;
		$index ++;
		return @r if $index > $self->indexLast;
		$item = $self->getIndex($index);
		$nm = $item->name;
	}
	return  @r;
}

=item B<getColumn>I<($column)>

Returns a reference to the L<Tk::ListBrowser::SideColumn> object of column I<$column>.
Only practical when I<-arrange> is set to 'column' or 'row'.

=cut

sub getColumn {
	my ($self, $col) = @_;
	my @hits = grep { (defined $_->column) and ($_->column eq $col) } $self->getAll;
	return @hits
}

=item B<getIndex>I<($index)>

Returns a reference to the L<Tk::ListBrowser::Item> object at index I<$index>.

=cut

sub getIndex {
	my ($self, $index) = @_;
	return $self->pool->getIndex($index)
}

=item B<getRoot>

Returns a list of L<Tk::ListBrowser::Entry> objects that are root.

=cut

sub getRoot {
	my $self = shift;
	my @pool = $self->getAll;
	my $sep = $self->separator;
	$sep = quotemeta($sep);
	return grep {  not $_->name =~ /$sep/ } @pool;
}

=item B<getRow>I<($row)>

Returns a list of references to all L<Tk::ListBrowser::Icon> objects in row I<$row>.
Only practical when I<-arrange> is set to 'column' or 'row'.

=cut

sub getRow {
	my ($self, $row) = @_;
	my @hits = grep { (defined $_->row ) and ($_->row eq $row) } $self->getAll;
	return @hits
}

sub header {
	my $self = shift;
	$self->{HEADER} = shift if @_;
	return $self->{HEADER}
}

=item B<headerAvailable>

Returns true if headers have been defined.

=cut

sub headerAvailable {
	my $self = shift;
	my $a = $self->cget('-arrange');
	return '' if (($a eq 'column') or ($a eq 'row'));
	return 1 if defined $self->header;
	my @columns = $self->columnList;
	for (@columns) {
		return 1 if defined $self->headerGet($_)
	}
	return ''
}

=item B<headerCget>I<($column, $option)>

Returns the value of $option in header $name.

Specify I<$column> as an empty string for the main list. Otherwise specify a column name.

=cut

sub headerCget {
	my ($self, $col, $option) = @_;
	my $h;
	if ($col eq '') {
		$h = $self->header
	} else {
		my $c = $self->columnGet($col);
		$h = $c->header
	}
	return $h->cget($option) if defined $h
}

sub headerClear {
	my $self = shift;
	$self->Subwidget('HeaderFrame')->packForget;
}

=item B<headerConfigure>I<($column, $option, $value)>

Configures options in header $name.

Specify $name as an empty string for the main list. Otherwise specify a column name.

=cut

sub headerConfigure {
	my ($self, $col, $option, $value) = @_;
	my $h;
	if ($col eq '') {
		$h = $self->header
	} else {
		my $c = $self->columnGet($col);
		$h = $c->header
	}
	$h->configure($option, $value) if defined $h
}

=item B<headerCreate>I<($column, %options)>

Creates a new header object. You can use the following options:

=over 4

=item B<-contextcall>

Callback executed when you right click the header.

=item B<-image>

Image to display on the header. This option precedes the I<-text> option.

=item B<-sortable>

Only available at create time. If set to true the list is sorted by clicking on the header.
By default sorting is disabled.

=item B<-text>

Text to display on the header.

=back

Specify I<$column> as an empty string for the main list. Otherwise specify a column name.

=cut

sub headerCreate {
	my ($self, $col, %options) = @_;
	if ($self->headerExists($col)) {
		croak "Header '$col' already exists";
		return
	}
	
	my $sortable = delete $options{'-sortable'};
	$options{'-sortcall'} = ['sortMode', $self] if (defined $sortable) and $sortable;
	my $hf= $self->Subwidget('HeaderFrame');
	my $h = $hf->LBHeader(
		-motioncall => ['headerMotion', $self],
		-releasecall => ['refresh', $self],
		-relief => $self->cget('-headerrelief'),
		-borderwidth => $self->cget('-headerborderwidth'),
		-listbrowser => $self,
		-column => $col,
		%options,
	);
	if ($col eq '') {
		$self->header($h)
	} else {
		my $c = $self->columnGet($col);
		$c->header($h) if defined $c
	}
}

=item B<headerExists>I<($column)>

Returns true if column I<$name> exists.

Specify I<$column> as an empty string for the main list. Otherwise specify a column name.

=cut

sub headerExists {
	my ($self, $col) = @_;
	return defined $self->headerGet($col)
}

sub headerGet {
	my ($self, $col) = @_;
	my $h;
	if ($col eq '') {
		$h = $self->header
	} else {
		my $c = $self->columnGet($col);
		$h = $c->header if defined $c
	}
	return $h
}

sub headerMotion {
	my ($self, $column, $x) = @_;
	return if $column eq '';
	my $c = $self->headerGet($column);
	my ($right, $target);
	my $index = $self->columnIndex($column);
	my $columns = $self->{COLUMNS};
	if ($x > 0) {
		$right = 1;
		return if $index >= @$columns - 1;
		$target = $columns->[$index + 1];
	} else {
		$right = '';
		return if $index <= 0;
		$target = $columns->[$index - 1];
	}
	$target = $self->headerGet($target->name);
	my $t = $target->x + int($target->width / 2);
	$x = $x + $c->x;
	if ($right) {
		if ($x > $t) {
			$self->columnMove($column, $index + 1);
			$self->headerPlace;
		}
	} else {
		if ($x < $t) {
			$self->columnMove($column, $index - 1);
			$self->headerPlace;
		}
	}
}

sub headerPlace {
	my $self = shift;
	return unless $self->columnCapable;
	return unless $self->headerAvailable;

	my $hf = $self->Subwidget('HeaderFrame');
	my $hheight = $self->cget('-headerheight');
	$hf->configure(-height => $hheight);
	$hf->pack(-fill, 'x');

	my $width = $self->cget('-scrollregion');
	$width = $width->[2];

	my ($fract) = $self->Subwidget('Canvas')->xview;
	my $x = - int($width * $fract);

	#configure left margin
	my $lm = $self->cget('-marginleft');
	if ($lm > 0) {
		my $frame = $self->Subwidget("LMFrame");
		unless (defined $frame) {
			$frame = $hf->Frame(
				-borderwidth => $self->cget('-headerborderwidth'),
				-relief => $self->cget('-headerrelief'),
			);
			$self->Advertise('LMFrame', $frame)
		}
		$frame->place(-x => $x, -y => 0, -height => $hheight, -width => $lm - 1);
		$x = $x + $lm;
	} else {
		my $frame = $self->Subwidget("LMFrame");
		$frame->placeForget if defined $frame
	}

	#configure main header
	if (my $h = $self->headerGet('')) {
		$h->place(-x => $x, -y => 0, -height => $hheight, -width => $self->listWidth);
	}
	$x = $x + $self->listWidth + 1;

	#configure columns
	my @columns = $self->columnList;
	for (@columns) {
		my $col = $self->columnGet($_);
		if (my $h = $self->headerGet($_)) {
			$h->place(-x => $x, -y => 0, -height => $hheight, -width => $col->cellWidth);
		}
		$x = $x + $col->cellWidth + 1;
	}

	#configure right margin
	my ($cw) = $self->canvasSize;
	my $rm = $self->cget('-marginright');
	if ($x < $cw) {
		my $frame = $self->Subwidget("RMFrame");
		unless (defined $frame) {
			$frame = $hf->Frame(
				-borderwidth => $self->cget('-headerborderwidth'),
				-relief => $self->cget('-headerrelief'),
			);
			$self->Advertise('RMFrame', $frame)
		}
		my $yscroll = $self->Subwidget('YScrollbar');
		$cw = $cw - $yscroll->width if $yscroll->ismapped;
		$frame->place(-x => $x, -y => 0, -height => $hheight, -width => $cw - $x - 1);
	} else {
		my $frame = $self->Subwidget("RMFrame");
		$frame->placeForget if defined $frame
	}
}

=item B<headerRemove>I<($column)>

Removes the header for column I<$column>.

Specify I<$column> as an empty string for the main list. Otherwise specify a column name.

=cut

sub headerRemove {
	my ($self, $col) = @_;
	my $h;
	if ($col eq '') {
		$h = $self->header;
		$self->header(undef);
	} else {
		my $c = $self->columnGet($col);
		if (defined $c) {
			$h = $c->header;
			$c->header(undef)
		}
	}
	$h->destroy if defined $h;
}

=item B<hide>I<($name)>

Hides entry I<$name>. Call I<refresh> or I<refreshPurge> to see changes.

=cut

sub hide {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return unless defined $a;
	$a->hidden(1);
}

sub hierarchy { return $_[0]->cget('-separator') ne '' }

=item B<index>

Returns the numerical index of entry I<$name>.

=cut

sub index {
	my ($self, $name) = @_;
	return $self->pool->index($name)
}

=item B<indexColumnRow>I<($column, $row)>

Returns the numerical index of the entry at I<$column>, I<$row>.

=cut

sub indexColumnRow {
	my ($self, $column, $row) = @_;
	my @pool = $self->getAll;
	my ($index) = grep {
		(defined $pool[$_]->column) and
		(defined $pool[$_]->row) and
		($pool[$_]->column eq $column) and
		($pool[$_]->row eq $row)
	} 0 .. @pool - 1;
	return $index
}

=item B<indexLast>

Returns the numerical index of the last entry in the list.

=cut

sub indexLast {
	my $self = shift;
	return $self->pool->indexLast
}

=item B<infoAnchor>

Returns the name of the entry that holds the anchor.
Returns undef if the anchor is not held.

=cut

sub infoAnchor {
	my $self = shift;
	my $a = $self->anchorGet;
	return $a->name if defined $a;
	return undef
}

=item B<infoChildren>I<($parent)>

Returns a list with the names of the children of I<$parent>.

=cut

sub infoChildren {
	my ($self, $name) = @_;
	my $sep = quotemeta($self->cget('-separator'));
	my $test = quotemeta($name) . $sep;
	my @pool = $self->getAll;
	my @r;
	my $index = $self->index($name) + 1;
	return @r if $index > $self->indexLast;
	my $item = $self->getIndex($index);
	my $nm = $item->name;
	while ($nm =~/^$test(.*)/) {
		push @r, $nm unless $1 =~ /$sep/;
		$index ++;
		return @r if $index > $self->indexLast;
		$item = $self->getIndex($index);
		$nm = $item->name;
	}
	return  @r;
}

=item B<infoData>I<($name)>

Returns the data associated with entry I<$name>

=cut

sub infoData {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return $a->data if defined $a;
	croak "Entry '$name' not found";
	return undef
}

=item B<infoExists>I<($name)>

Returns a boolean value indicating if entry I<$name> exists.

=cut

sub infoExists {
	my ($self, $name) = @_;
	return $self->pool->exist($name)
}

=item B<infoFirst>

Returns the name of the first entry in the list.

=cut

sub infoFirst {
	my $self = shift;
	my $f = $self->pool->first;
	return $f->name if defined $f;
	return undef;
}

=item B<infoFirstVisible>

Returns the name of the first entry in the list that is not hidden.

=cut

sub infoFirstVisible {
	my $self = shift;
	my @pool = $self->getAll;
	for (@pool) {
		return $_->name unless $_->hidden
	}
	return undef
}

=item B<infoHidden>I<($name)>

Returns the boolean hidden state of entry I<$name>.

=cut

sub infoHidden {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return $a->hidden if defined $a;
	croak "Entry '$name' not found";
	return undef
}

=item B<infoLast>

Returns the name of the last entry in the list.

=cut

sub infoLast {
	my $self = shift;
	my $l = $self->pool->last;
	return $l->name if defined $l;
	return undef
}

sub infoLastChild {
	my ($self, $name) = @_;
	my @c = $self->infoChildren($name);
	return pop @c if @c;
	return undef
}

sub infoLastOffspring {
	my ($self, $name) = @_;
	my $last = $self->infoLastChild($name);
	if (defined $last) {
		my $lo = $self->infoLastOffspring($last);
		return $lo if defined $lo;
	}
	return $last
}

=item B<infoLastVisible>

Returns the name of the last entry in the list that is not hidden.

=cut

sub infoLastVisible {
	my $self = shift;
	my @pool = $self->getAll;
	for (reverse @pool) {
		return $_->name unless $_->hidden
	}
	return undef
}

=item B<infoList>

Returns a list of all entry names in the list.

=cut

sub infoList {
	my ($self, $flag) = shift;
	my @pool = $self->getAll;
	my @list;
	for (@pool) {
		push @list, $_->name;
	}
	return @list
}

=item B<infoNext>I<($name, ?$flag>?)>

The parameter I<$flag> is only usefull in hierarchy mode.
By default it is set to true. You can overwrite that by
specifying it as false.

If I<$flag> is set in hierarchy mode the next peer is returned, 
or undef if I<$name> is the last peer amoung it's peers.

In non hierarchy mode it returns the name of the next entry of
I<$name> or undef if I<$name> is the last entry in the list.

=cut

sub infoNext {
	my ($self, $name, $flag) = @_;
	$flag = 1 unless defined $flag;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return undef
	}
	my $last = $self->infoLast;
	return undef if $a eq $last;
	if ($self->hierarchy and $flag) {
		my $cur = $self->get($name);
		my @c = $self->infoChildren($name);
		if (@c) {
			my $last = pop @c;
			my $li = $self->index($last);
			$a = $li if $li < $self->infoSize;
		}
	}
	return undef if $a eq $self->indexLast;
	return $self->getIndex($a + 1)->name;
}

=item B<infoNextVisible>I<($name)>

Returns the name of the first next entry of I<$name> that is not hidden.
Returns undef if I<$name> is the last entry in the list.

=cut

sub infoNextVisible {
	my ($self, $name) = @_;
	my @pool = $self->getAll;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	for ($a .. @pool - 1) {
		return $pool[$_]->name if $pool[$_]->ismapped
	}
	return undef
}

=item B<infoParent>I<($name)>

Returns the name of parent of I<$name>. Returns undef
if no parent is found.

=cut

sub infoParent {
	my ($self, $name) = @_;
	unless ($self->infoExists($name)) {
		croak "Entry '$name' does not exist";
		return
	}
	my $parent = $self->decodeParent($name);
	return undef unless defined $parent;
	return $parent if $self->infoExists($parent);
	return undef
}

=item B<infoPev>I<($name, ?$flag?)>

The parameter I<$flag> is only usefull in hierarchy mode.
By default it is set to true. You can overwrite that by
specifying it as false.

If I<$flag> is set in hierarchy mode the previous peer is returned, 
or undef if I<$name> is the first peer amoung it's peers.

In non hierarchy mode it returns the name of the previous entry of
I<$name> or undef if I<$name> is the first entry in the list.

=cut

sub infoPrev {
	my ($self, $name, $flag) = @_;
	$flag = 1 unless defined $flag;
	my @pool = $self->getAll;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	return undef if $a eq 0;
	if ($self->hierarchy and $flag) {
		my $cur = $self->get($name);
		my @c = $self->infoChildren($name);
		if (@c) {
			my $first = shift @c;
			my $fi = $self->index($first);
			$a = $fi;
		}
	}
	return undef if $a eq 0;
	return $self->getIndex($a - 1)->name;
}

=item B<infoPrevVisible>I<($name)>

Returns the name of the first previous entry of I<$name> that is not hidden.
Returns undef if I<$name> is the first entry in the list.

=cut

sub infoPrevVisible {
	my ($self, $name) = @_;
	my @pool = $self->getAll;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	for (reverse 0 .. $a) {
		return $pool[$_]->name if $pool[$_]->ismapped
	}
	return undef
}

=item B<infoRoot>

Returns a list of root entry names.

=cut

sub infoRoot {
	my $self = shift;
	my @pool = $self->getAll;
	my $sep = $self->cget('-separator');
	$sep = quotemeta($sep);
	my @root;
	for (@pool) {
		my $name = $_->name;
		push @root, $name unless $name =~ /$sep/;
	}
	return @root
}

=item B<infoSelection>

Same as I<selectionGet>.

=cut

sub infoSelection {	return $_[0]->selectionGet }

sub infoSize {	return $_[0]->pool->size }

sub indent {
	my $self = shift;
	$self->{INDENT} = shift if @_;
	return $self->{INDENT}
}

sub initem {
	my ($self, $x, $y) = @_;
	$x = int($self->canvasx($x));
	$y = int($self->canvasy($y));
	my @pool = $self->getAll;
	for (@pool) {
		if ($_->inregion($x, $y)) {
			return $_;
		}

	}
	return undef
}

=item B<itemCget>I<($name, $column, $option)>

Returns the value of $option of item I<$name> in column I<$column>.

=cut

sub itemCget {
	my ($self, $entry, $column, $option) = @_;
	my $i = $self->itemGet($entry, $column);
	my $val;
	if (defined $i) {
		$val = $i->cget($option);
	}
	if ($self->sortActive) {
		unless (defined $val) {
			if ($i->owner->cget('-sortnumerical')) {
				$val = $self->cget('-sortbottom');
			} else {
				$val = ''
			}
		}
	}
	return $val
}

=item B<itemConfigure>I<($name, $column, %options)>

Configures the options item of I<$name> in column I<$column>.

=cut

sub itemConfigure {
	my ($self, $entry, $column, %options) = @_;
	my $i = $self->itemGet($entry, $column);
	if (defined $i) {
		$i->configure(%options)
	}
}

=item B<itemCreate>I<($name, $column, %options)>

Creates a new item object for I<$name> in column I<$column>. You can use the standard options as well as:

=over 4

=item B<-data>

Data to be assigned to this item item.

=item B<-image>

Image to display in the item.

=item B<-text>

Text to display in the item.

=back

Once an item has been created there is no need to call I<refresh> when you update it's text or image.

=cut

sub itemCreate {
	my ($self, $entry, $column, %options) = @_;
	my $col = $self->columnGet($column);
	my $item = new Tk::ListBrowser::Item(
		%options,
		-listbrowser => $self,
		-name => $entry,
		-owner => $col,
	);
	$col->itemAdd($entry, $item)
}

=item B<itemExists>I<($name, $column)>

Returns true if item for I<$name> in column I<$column> has been created.

=cut

sub itemExists {
	my ($self, $entry, $column) = @_;
	my $col = $self->columnGet($column);
	return $col->itemExists($entry)
}

=item B<itemGet>I<($name, $column)>

Returns a reference to the L<Tk::ListBrowser::Item> object for I<$name> in column I<$column>.

=cut

sub itemGet {
	my ($self, $entry, $column) = @_;
	my $col = $self->columnGet($column);
	return $col->itemGet($entry)
}

=item B<itemRemove>I<($name, $column)>

Removes the item for I<$name> in column I<$column> and it's data.

=cut

sub itemRemove {
	my ($self, $entry, $column) = @_;
	my $col = $self->columnGet($column);
	$col->itemRemove($entry)
}

sub KeyArrowNavig {
	my ($self, $dcol, $drow) = @_;
	return undef if $self->anchorInitialize;
	my $i = $self->anchorGet;
	my $target;
	if ($drow eq 0) { #horizontal move
		my $flag = 1;
		if ($self->hierarchy) {
			my $a = $self->anchorGet;
			if (defined $a) {
				my $n = $a->name;
				my $o = $a->opened;
				my @ch = $self->infoChildren($a->name);
				if ($dcol eq 1) { #move to the right
					if ((! $a->opened) and (@ch)) {
						my $nm = $a->name;
						my $i = $self->index($nm);
						$self->open($nm);
						$self->refreshPurge($i, 1);
						$flag = '';
					}
				} else { #move to the left
					if (($a->opened) and (@ch)) {
						my $nm = $a->name;
						my $i = $self->index($nm);
						$self->close($nm);
						$self->refreshPurge($i, 1);
						$flag = '';
					} else {
						if (my $parent = $self->infoParent($a->name)) {
							$a = $self->get($parent);
							$flag = '';
						}
					}
				}
				$self->anchorSet($a->name);
				$self->selectionSingle($a->name) if $self->cget('-selectstyle') eq 'simple';
			}
		}
		if ($flag) {
			my $rown = $i->row;
			my @row = $self->getRow($rown);
			if (($dcol > 0) and ($i->column >= @row - 1)) {
				$target = $self->moveRow(1);
			} elsif (($dcol < 0) and ($i->column <= 0)) {
				$target = $self->moveRow(-1);
			} else {
				my $ti = $self->indexColumnRow($i->column + $dcol, $rown);
				$target = $self->getIndex($ti)  if defined $ti;
			}
		}
	} else { #vertical move
		my $coln = $i->column;
		my @column = $self->getColumn($coln);
		if (($drow > 0) and ($i->row >= @column - 1)) {
			$target = $self->moveColumn(1);
		} elsif (($drow < 0) and ($i->row <= 0)) {
			$target = $self->moveColumn(-1);
		} else {
			my $ti = $self->indexColumnRow($coln, $i->row + $drow);
			$target = $self->getIndex($ti)  if defined $ti;
		}
	}
	if (defined $target) {
		my $name = $target->name;
		$self->anchorSet($name);
		my $style = $self->cget('-selectstyle');
		$self->selectionSingle($name) if $style eq 'simple';
		$self->see($name);
		return 1
	}
	return ''
}

sub KeyArrowSelect {
	my ($self, $dcol, $drow) = @_;
	return if $self->anchorInitialize;
	my $p = $self->anchorGet;
	if ($self->KeyArrowNavig($dcol, $drow)) {
		my $new = $self->anchorGet->name;
		if ($p->selected) {
			$self->selectionSet($new)
		} else {
			$self->selectionUnSet($new)
		}
	}
}


sub KeyLastColumn {
	my $self = shift;
	return if $self->anchorInitialize;
	my $i = $self->anchorGet;
	my $row = $i->row;
	my $col = $self->lastColumnInRow($row);
	unless ($self->anchorSetColumnRow($col, $row)) {
		my $flag = '';
		while ((not $flag) and ($col >= 0)) {
			$col --;
			my $index = $self->indexColumnRow($col, $row);
			my $name = $self->getIndex($index)->name;
			$flag = $self->anchorSet($name);
			$self->see($name) if $flag;
		}
	}
}

sub KeyPress {
	my ($self, $key) = @_;
	my @pool = $self->getAll;
	my $h = $self->_handler;
	return unless @pool;

	if ($key eq 'Return') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $name = $i->name;
		$self->selectionSet($name);
		$self->Callback('-command', $name);
		return
	}
	if ($key eq 'Escape') {
		my $e = $self->Subwidget('FilterEntry');
		if ((defined $e) and ($e->ismapped)) {
			$self->filterFlip
		} else {
			$self->selectionClear;
			$self->anchorClear;
		}
		return
	}

	#keyboard navigation
	if ($key eq 'Down') {
		$self->KeyArrowNavig(0, 1);
		return
	}
	if ($key eq 'End') {
		$self->KeyLastColumn;
		return
	}
	if ($key eq 'Control-End') {
		my $name = $self->infoLastVisible;
		$self->see($name);
#		$self->after(50, sub { $self->anchorSet($name) });
		return
	}
	if ($key eq 'Home') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $row = $i->row;
		my $index = $self->indexColumnRow(0, $row);
		my $name = $pool[$index]->name;
		$self->anchorSet($name);
		$self->see($name);
		return
	}
	if ($key eq 'Control-Home') {
		my $name = $self->infoFirstVisible;
		$self->anchorSet($name);
		$self->see($name);
		return
	}
	if ($key eq 'Left') {
		$self->KeyArrowNavig(-1, 0);
		return
	}
	if ($key eq 'Right') {
		$self->KeyArrowNavig(1, 0);
		return
	}
	if ($key eq 'Up') {
		$self->KeyArrowNavig(0, -1);
		return
	}

	#manipulating selections
	if ($key eq 'space') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $name = $i->name;
		$self->selectionFlip($name);
		$self->Callback('-browsecmd', $name) if $i->selected;
		return
	}
	if ($key eq 'Shift-Down') {
		return $self->KeyArrowSelect(0, 1)
	}
	if ($key eq 'Shift-End') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $column = $i->column;
		my $row = $i->row;
		my @items = $self->getRow($row);
		if ($self->KeyLastColumn) {
			for (@items) {
				if ($self->cget('-selectmode') eq 'multiple') {
					$self->selectionFlip($_->name)
				}
			}
		}
	}
	if ($key eq 'Control-Shift-End') {
		return if $self->anchorInitialize;
		my $begin = $self->anchorGet;
		my $name = $self->infoLastVisible;
		if ($self->anchorSet($name)) {
			my $end = $self->anchorGet;
			if ($begin->selected) {
				$self->selectionClear if $self->cget('-selectmode') eq 'single';
				$self->selectionSet($begin->name, $end->name);
			} else {
				$self->selectionClear if $self->cget('-selectmode') eq 'single';
				$self->selectionUnSet($begin->name, $end->name);
			}
			$self->see($name);
		}
	}
	if ($key eq 'Shift-Home') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $column = $i->column;
		my $row = $i->row;
		my @items = $self->getRow($row);
		if ($self->anchorSetColumnRow(0, $row)) {
			for (@items) {
				$self->selectionFlip($_->name)
			}
		}
		return
	}
	if ($key eq 'Control-Shift-Home') {
		return if $self->anchorInitialize;
		my $begin = $self->anchorGet;
		if ($self->anchorSet($self->infoFirstVisible)) {
			my $end = $self->anchorGet;
			if ($begin->selected) {
				$self->selectionSet($begin->name, $end->name);
			} else {
				$self->selectionUnSet($begin->name, $end->name);
			}
		}
		return
	}
	if ($key eq 'Shift-Left') {
		return $self->KeyArrowSelect(-1, 0)
	}
	if ($key eq 'Shift-Right') {
		return $self->KeyArrowSelect(1, 0)
	}
	if ($key eq 'Shift-Up') {
		return $self->KeyArrowSelect(0, -1)
	}
}

=item B<lastColumnInRow>I<($row)>

Returns the number of the last column in I<$row>.

=cut

sub lastColumnInRow {
	my ($self, $row) = @_;
	my @row = $self->getRow($row);
	return $row[@row - 1]->column;
}

=item B<lastRowInColumn>I<($column)>

Returns the number of the last row in I<$column>.

=cut

sub lastRowInColumn {
	my ($self, $column) = @_;
	my @column = $self->getColumn($column);
	return $column[@column - 1]->row;
}

sub listMode {
	my $self = shift;
	my $arr = $self->cget('-arrange');
	return (($arr ne 'column') and ($arr ne 'row') and ($arr ne 'bar'));
}

sub listWidth {
	my $self = shift;
	$self->{LISTWIDTH} = shift if @_;
	my $fw = $self->forceWidth;
	return $fw if defined $fw;
	return $self->{LISTWIDTH}
}

sub Motion {
	my ($self, $x, $y) = @_;
	return unless $self->cget('-selectmode') eq 'single';
	return unless $self->cget('-motionselect');
	my $item = $self->initem($x, $y);
	if (defined $item) {
		$self->selectionSet($item->name);
	}
}

sub moveColumn {
	my ($self, $delta) = @_;
	my $i = $self->anchorGet;
	my $column = $i->column;
	my $row = $i->row;
	my @c = $self->getColumn($column);
	my $lastrow = @c - 1;
	$row = $row + $delta;
	if ($row >= $lastrow) {
		$column ++;
		$row = 0;
	} elsif ($column <= 0) {
		$column --;
		my @nc = $self->getColumn($column);
		$row = @nc - 1;
	}
	my $target;
	my $index = $self->indexColumnRow($column, $row);
	$target = $self->getIndex($index) if defined $index;
	return $target;
}

sub moveRow {
	my ($self, $delta) = @_;
	my $i = $self->anchorGet;
	my $column = $i->column;
	my $row = $i->row;
	my @r = $self->getRow($row);
	my $lastcolumn = @r - 1;
	$column = $column + $delta;
	if ($column >= $lastcolumn) {
		$column = 0;
		$row ++;
	} elsif ($column <= 0) {
		$row --;
		my @nr = $self->getRow($row);
		$column = @nr - 1;
	}
	my $target;
	my $index = $self->indexColumnRow($column, $row);
	$target = $self->getIndex($index) if defined $index;
	return $target;
}

sub OnConfigure {
	my ($self, $timer) = @_;

	#redraw headers, anchor and selection in list mode
	if ($self->listMode) {
		$self->headerPlace;
		$self->anchorRefresh;
		$self->selectionRefresh;
	}

	if (my $id = $self->{'timer_id'}) {
		$self->afterCancel($id);
		my $nid = $self->after(50, ['OnConfigureTimer', $self]);
		$self->{'timer_id'} = $nid;
	}

	unless (defined $timer) {
		$self->update;
		my $id = $self->after(50, ['OnConfigureTimer', $self]);
		$self->{'timer_id'} = $id;
		return
	}

	#need to refresh if arrange is column or row
	my $arrange = $self->cget('-arrange');
	my %a = (qw/column 1 row 1/);
	$self->refresh if exists $a{$arrange};

}

sub OnConfigureTimer {
	my $self = shift;
	delete $self->{'timer_id'};
	$self->OnConfigure(1);
}

=item B<open>I<($name)>

Shows all children of I<$name>. Call I<refresh> or I<refreshPurge> to see your changes.

=cut

sub open {
	my ($self, $entry) = @_;
	my $i = $self->get($entry);
	unless (defined $i) {
		croak "Entry $entry not found";
		return
	}
	$i->opened(1);
}

=item B<openAll>

Opens all entries.

=cut

sub openAll {
	my $self = shift;
	my @list = $self->infoList;
	for (@list) {
		$self->open($_) if $self->infoChildren($_);
	}
}

sub pool {
	my $self = shift;
	$self->{POOL} = shift if @_;
	return $self->{POOL}
}

sub priorityMax {
	my $self = shift;
	$self->{PRIORITYMAX} = shift if @_;
	return $self->{PRIORITYMAX}
}

sub prioritySet {
	my ($self, $priority) = @_;
	my $max = $self->priorityMax;
	$self->priorityMax($priority) if $max < $priority;
}

=item B<refresh>

Clears the canvas and rebuilds it. Call this method after you are done making changes.

=cut

sub refresh {
	my $self = shift;

	my @sel = $self->selectionGet;
	my $anch = $self->anchorGet;
	$self->refreshSaveView;

	$self->_handler->refresh;

	$self->refreshRestoreView;
	for (@sel) {
		$self->selectionSet($_)
	}
	$self->anchorSet($anch) if defined $anch;
}

sub refreshLoop {
	my $self = shift;
	my $handler = $self->_handler;
	my $epc = $self->cget('-refreshentriespercycle');
	for (1 .. $epc) {
		my $pos = $self->refreshPos;
		if ($pos <= $self->indexLast) {
			$self->refreshLoopActive(1);
			my $entry = $self->getIndex($pos);
			unless (($entry->hidden) or (not $entry->openedparent)) {
				my @params = $self->refreshParams;
				my $entry = $self->getIndex($pos);
				$handler->draw($entry, @params);
				@params = $handler->nextPosition(@params);
				$self->refreshParams(@params);
			}
			$pos ++;
			$self->refreshPos($pos);
		} else {
			my ($mx, $my) = $handler->maxXY;
			my $last = $self->infoLastVisible;
			if (defined $last) {
				my @region = $self->get($last)->region;
				$my = $region[3] + $self->cget('-marginbottom') + 1;
			}
			$self->configure(-scrollregion => [0, 0, $mx, $my]);
			$self->refreshLoopActive(0);
			$self->refreshRestoreView;
		}
		last unless $self->refreshLoopActive;
	}
	$self->after($self->cget('-refreshinterval'), ['refreshLoop', $self]) if $self->refreshLoopActive;
}

sub refreshLoopActive {
	my $self = shift;
	$self->{REFRESHLOOPACTIVE} = shift if @_;
	return $self->{REFRESHLOOPACTIVE}
}

sub refreshParams {
	my $self = shift;
	$self->{REFRESHPAR} = [@_] if @_;
	my $p = $self->{REFRESHPAR};
	return @$p
}

sub refreshPos {
	my $self = shift;
	$self->{REFRESHPOS} = shift if @_;
	return $self->{REFRESHPOS}
}

=item B<refreshPurge>I<(?$index?, ?$nosave?)>

Same as refresh, but does not calculate cell sizes. Can be used after
an initializing call to I<refresh> has been made. If you specify I<$index>
the refresh is done from the entry at the index, going downward. It is
operated in a background job cycle, so it is non blocking.

if the I<$nosave> flag is set, the xview and yview of the canvas are not saved
before the refresh starts.

=cut

sub refreshPurge {
	my ($self, $index, $nosave) = @_;
	$index = 0 unless defined $index;
	$nosave = 0 unless defined $nosave;
	if ($nosave) {
		$self->refreshView(undef, undef);
	} else {
		$self->refreshSaveView;
	}

	#clear from index
	for ($index .. $self->indexLast) {
		my $entry = $self->getIndex($_);
		$entry->clear;
	}

	my $handler = $self->_handler;
	my $entry = $self->getIndex($index);
	my ($x, $y) = $handler->startXY;
	my @params = ($x, $y, 0 , 0);
	my $prev = $self->infoPrevVisible($entry->name);
	if (defined $prev) {
		my $p = $self->get($prev);
		@params = ($p->rectX, $p->rectY, $p->column, $p->row);
		@params = $handler->nextPosition(@params);
		$params[0] = $x if $self->listMode;
	}
	$self->refreshParams(@params);
	$self->refreshPos($index);
	$self->after($self->cget('-refreshinterval'), ['refreshLoop', $self]) unless $self->refreshLoopActive;
}

sub refreshRestoreView {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	my ($xview, $yview) = $self->refreshView;
	$c->xview(moveto => $xview) if defined $xview;
	$c->yview(moveto => $yview) if defined $yview;
}

sub refreshSaveView {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	my ($xview) = $c->xview;
	my ($yview) = $c->yview;
	$self->refreshView($xview, $yview);
}

sub refreshView {
	my $self = shift;
	$self->{REFRESHVIEW} = [@_] if @_;
	my $v = $self->{REFRESHVIEW};
	return @$v
}


=item B<see>I<($name)>

Scrolls the canvas to make I<$name> visible if it is not, or not completely, visible.

=cut

sub see {
	my ($self, $name) = @_;

	my $scrollregion = $self->cget('-scrollregion');
	return unless @$scrollregion;

	my ($cx1, $cy1, $cx2, $cy2) = @$scrollregion; #the canvas
	my $i = $self->get($name);
	my ($cwidth, $cheight) = $self->canvasSize;
	my ($ix1, $iy1, $ix2, $iy2) = $i->region;

	my $h = $self->_handler;
	#horizontal
	if ($h->scroll eq 'horizontal') {
		my ($vl, $vr) = $self->xview;
		my $div = $cx2 - $cx1;
		if (($div > 0) and ($ix1/$div < $vl)) { #going to the left
			$self->xview(moveto => $ix1/$div);
		} elsif (($div > 0) and ($ix2/$div > $vr)) {	#going to the right.
			my $mr = ($ix2 - $cwidth + 2)/$div;
			$self->xview(moveto => $mr);
		}
	}
	
	#vertical
	if ($h->scroll eq 'vertical') {
		my ($vt, $vb) = $self->yview;
		my $div = $cy2 - $cy1;
		if ($self->headerAvailable) {
			$iy1 = $iy1 - $self->cget('-headerheight')
		}
		if (($div > 0) and ($iy1/$div < $vt)) { #going up
			$self->yview(moveto => $iy1/$div);
		} elsif (($div > 0) and ($iy2/$div > $vb)){	#going down.
			my $mr = ($iy2 - $cheight + 2)/$div;
			$self->yview(moveto => $mr);
		}
	}
}

=item B<selectAll>

Selects all entries.

=cut

sub selectAll {
	my $self = shift;
	return if $self->cget('-selectmode') eq 'single';
	my @pool = $self->getAll;
	grep { $_->select } @pool;
}

=item B<selectionClear>

Clears the entire selection.

=cut

sub selectionClear {
	my $self = shift;
	my @pool = $self->getAll;
	grep { $_->select(0) } @pool;
}

sub selectionFlip {
	my ($self, $begin, $end) = @_;
	($begin, $end) = $self->selectionIndex($begin, $end);
	for ($begin .. $end) {
		my $i = $self->getIndex($_);
		if ($i->selected) {
			$self->selectionClear if $self->cget('-selectmode') eq 'single';
			$i->select(0);
		} else {
			$self->selectionClear if $self->cget('-selectmode') eq 'single';
			$i->select;
		}
	}
}

=item B<selectionGet>

Returns a list of entry names contained in the selection.

=cut

sub selectionGet {
	my $self = shift;
	my @list;
	my @pool = $self->getAll;
	for (@pool) { push @list, $_->name  if $_->selected }
	return @list;
}

sub selectionIndex {
	my ($self, $begin, $end) = @_;
	$end = $begin unless defined $end;
	$begin = $self->index($begin);
	$end = $self->index($end);
	if ($begin > $end) {
		my $t = $begin;
		$begin = $end;
		$end = $t;
	}
	return ($begin, $end)
}

sub selectionRefresh {
	my $self = shift;
	my @sel = $self->selectionGet;
	for (@sel) {
		my $i = $self->get($_);
		$i->drawSelect;
	}
}

=item B<selectionSet>I<($begin, ?$end?)>

Selects entry I<$begin>. If you specify I<$end> the
range from I<$begin> to I<$end> will be selected.

=cut

sub selectionSet {
	my ($self, $begin, $end) = @_;
	if ($self->cget('-selectmode') eq 'single') {
		$self->selectionSingle($begin);
	} else {
		($begin, $end) = $self->selectionIndex($begin, $end);
		my @pool = $self->getAll;
		for ($begin .. $end) {
			my $i = $pool[$_];
			$i->select(1) unless $i->hidden or (not $i->openedparent);
		}
	}
}

sub selectionSingle {
	my ($self, $name) = @_;
	my $index = $self->index($name);
	$self->selectionClear;
	$self->getIndex($index)->select(1);
}

=item B<selectionUnSet>I<($begin, $end)>

Clears the selection of entry I<$begin>. If you specify I<$end> the
range from I<$begin> to I<$end> will be cleared from the selection.

=cut

sub selectionUnSet {
	my ($self, $begin, $end) = @_;
	$end = $begin unless defined $end;
	($begin, $end) = $self->selectionIndex($begin, $end);
	my @pool = $self->getAll;
	for ($begin .. $end) {
		my $i = $pool[$_];
		$i->select(0) unless $i->hidden;
	}
}

sub separator {	return $_[0]->cget('-separator') }

=item B<show>I<($name)>

Shows entry I<$name>. Call I<refresh> to see changes.

=cut

sub show {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	return unless defined $a;
	$a->hidden(0);
}

sub sortActive {
	my $self = shift;
	$self->{SORTACTIVE} = shift if @_;
	return $self->{SORTACTIVE}
}

sub sortArray {
	my $self = shift;
	my @pool = @_;
	$self->sortActive(1);
	my $on = $self->cget('-sorton');
	my $order = $self->cget('-sortorder');;
	my $col;
	if ($on eq '') {
		$col = $self
	} else {
		$col = $self->columnGet($on);
	}
	my ($numsort, $sortcase, $sortfield);
	$numsort = $col->cget('-sortnumerical');
	$sortcase = $col->cget('-sortcase');
	$sortfield = $col->cget('-sortfield');
	
	my @sorted;
	if ($on eq '') {
		if ($numsort) {
				if ($order eq 'ascending') {
					@sorted = sort { $self->entryCget($a->name, $sortfield) <=> $self->entryCget($b->name, $sortfield) } @pool
				} else {
					@sorted = sort { $self->entryCget($b->name, $on, $sortfield) <=> $self->entryCget($a->name, $sortfield) } @pool
				}
		} else {
			if ($sortcase) {
				if ($order eq 'ascending') {
					@sorted = sort { lc($self->entryCget($a->name, $sortfield)) cmp lc($self->entryCget($b->name, $sortfield)) } @pool
				} else {
					@sorted = sort { lc($self->entryCget($b->name, $sortfield)) cmp lc($self->entryCget($a->name, $sortfield)) } @pool
				}
			} else {
				if ($order eq 'ascending') {
					@sorted = sort { $self->entryCget($a->name, $sortfield) cmp $self->entryCget($b->name, $sortfield) } @pool
				} else {
					@sorted = sort { $self->entryCget($b->name, $on, $sortfield) cmp $self->entryCget($a->name, $sortfield) } @pool
				}
			}
		}
	} else {
		if ($numsort) {
			if ($order eq 'ascending') {
				@sorted = sort { $self->itemCget($a->name, $on, $sortfield) <=> $self->itemCget($b->name, $on, $sortfield) } @pool
			} else {
				@sorted = sort { $self->itemCget($b->name, $on, $sortfield) <=> $self->itemCget($a->name, $on, $sortfield) } @pool
			}
		} else {
			if ($sortcase) {
				if ($order eq 'ascending') {
					@sorted = sort { lc($self->itemCget($a->name, $on, $sortfield)) cmp lc($self->itemCget($b->name, $on, $sortfield)) } @pool
				} else {
					@sorted = sort { lc($self->itemCget($b->name, $on, $sortfield)) cmp lc($self->itemCget($a->name, $on, $sortfield)) } @pool
				}
			} else {
				if ($order eq 'ascending') {
					@sorted = sort { $self->itemCget($a->name, $on, $sortfield) cmp $self->itemCget($b->name, $on, $sortfield) } @pool
				} else {
					@sorted = sort { $self->itemCget($b->name, $on, $sortfield) cmp $self->itemCget($a->name, $on, $sortfield) } @pool
				}
			}
		}
	}
	$self->sortActive('');
	return @sorted
}

=item B<sortList>

Sorts the list and refreshes the display. Make a call to I<sortMode> first
to specify how to sort or configure the options I<-sorton> and I<sortorder>.

=cut

sub sortList {
	my $self = shift;
	my $sorted = new Tk::ListBrowser::HashList;
	$self->clear;
 	if ($self->hierarchy) {
		my @root = $self->getRoot;
		for (reverse 0 .. $self->priorityMax) {
			my $pr = $_;
			my @p = grep { $_->priority eq $pr} @root;
			@p = $self->sortArray(@p);
			for (@p) { $self->sortRecursive($_, $sorted) }
		}
	} else {
		my @all = $self->getAll;
		for (reverse 0 .. $self->priorityMax) {
			my $pr = $_;
			my @p = grep { $_->priority eq $pr} @all;
			@p = $self->sortArray(@p);
			for (@p) { $sorted->add($_) }
		}
	}
	$self->pool($sorted);
	$self->refresh;
}

=item B<sortMode>I<($column, $order)>

Specify on which column to sort with I<$column>.
I<$order> can be 'ascending' or 'descending'.
This method changes the options I<-sorton> and I<-sortorder>.
It is called after a mouse click on a sortable header.

Specify $column as an empty string for the main list. Otherwise specify a column name.

=cut

sub sortMode {
	my ($self, $column, $order) = @_;
	$self->configure(-sorton => $column);
	$self->configure(-sortorder => $order);
	for ('', $self->columnList) {
		my $name = $_;
		my $widget = $self->headerGet($name);
		if ($name eq $column) {
			$widget->configure('-sortorder', $order);
		} else {
			$widget->configure('-sortorder', 'none');
		}
	}
}

sub sortRecursive {
	my ($self, $item, $sorted) = @_;
	$sorted->add($item);
	my @children = $self->getChildren($item->name);
	for (reverse 0 .. $self->priorityMax) {
		my $pr = $_;
		my @p = grep { $_->priority eq $pr} @children;
		@p = $self->sortArray(@p);
		for (@p) {
			$self->sortRecursive($_, $sorted)
		}
	}
	return $sorted
}

sub wraplength {
	my $self = shift;
	if (@_) {
		my $l = shift;
		if ($l > 0) {
			$l = 40 if $l < 40;
		}
		$self->{WRAPLENGTH} = $l;
	}
	return $self->{WRAPLENGTH}
}

=back

=head1 USING THE KEYBOARD

Before you can manipulate the list using the keyboard, the anchor must be initialized first. You do
that by pressing any of the navigation keys. After that you can start navigating and manipulate selections.

The spacebar selects or deselects the entry that is currently held by the anchor. The I<-browsecmd>
callback is called if the entry is selected.

The return key selects the entry and invokes the I<-command> callback.

You can navigate the list using the arrow keys and the the Home, Control-Home, End and Control-End keys.
Holding shift while pressing these keys manipulates the selection.

The escape key clears the selection and anchor or hides the filter entry if it is visible.

CTRL+F pops a filter entry. Clicking CTRL+F again hides it. Filtering is done instantly upon entering
text. This is influenced by the I<-filterforce> and I<-nofilter> options.

=head1 USING THE MOUSE

Clicking an entry with the left button selects it and assigns the anchor to it. Shift-click manipulates
the selection of the range from the entry that holds the anchor to the one you click. Control-click
selects or deselects the entry.

You can drag-scroll the list by moving you mouse while holding the middle button pressed.

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

Not having to call I<refresh> all the time would be nice.

=head1 BUGS AND CAVEATS

Setting a custom font greatly decreases the speed of refresh.

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=item L<Tk::ListBrowser::Entry>

=item L<Tk::ListBrowser::Item>

=item L<Tk::ListBrowser::SideColumn>

=back

=cut

1;