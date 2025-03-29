package Tk::YANoteBook;

=head1 NAME

Tk::YANoteBook - Yet another NoteBook widget

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION = '0.10';

use Tk;
require Tk::YANoteBook::NameTab;

use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'YANoteBook';

=head1 SYNOPSIS

 require Tk::YANoteBook;
 my $nb = $window->YANoteBook(@options)->pack;

=head1 DESCRIPTION

A more flexible notebook widget. It does well in a multi document environment.

You can select any side where the tabs will be placed.

You can drag tabs with your mouse.

It has an overload if tabs won't fit any more.

You can specify a close button for a tab. Besides that every
tab contains an indicator that is hidden by default. You can
set it to alert the end user for pending actions on the tab.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-autoupdate>

Default value 1. The widget automatically updates the tab bar after
a change is made. You can switch this off, make some massive changes,
then change it back on to have only one update call.

Corresponds with the B<autoupdate> method below.

=item Name: B<-backPageColor>

=item Class: B<-BackPageColor>

=item Switch: B<-backpagecolor>

Background color for the tab frame.

=item Switch: B<-closeimage>

Image for the close button on each tab.
Default value is the I<close_icon.xpm> in this distribution.

=item Switch: B<-closetabcall>

Calback, called when you press the close button on a tab. By default it calls B<deletePage>.
If you replace it, you should call B<deletePage> in your callback for the page to actually be removed.

=item Switch: B<-indicatorimage>

Image for the indicator. Not defined by default.

=item Switch: B<-indicatortext>

Text for the indicator. Not defined by default.

=item Switch: B<-closetabcall>

=item Switch: B<-moreimage>

Image to be used for the more button.
Default value none.

=item Switch: B<-onlyselect>

Defaut value is 1. If cleared it will unselect a selected page when 
clicked, leaving no pages selected.

=item Switch: B<-selectoptions>

Configuring the selected tab.
Default value [ -relief => 'raised' ].

=item Switch: B<-selecttabcall>

Calback, called when a tab is selected.

=item Switch: B<-rigid>

Default is 1. When cleared the widget will resize to minium when no page is selected.

=item Switch: B<-tabside>

Default value 'top'. Only available at create time.
Can be I<top>, I<left>, I<bottom> or I<right>.

=item Switch: B<-tabpadx>

=item Switch: B<-tabpady>

Internal padding for the name tabs. Default value 2 for both x and y.

=item Switch: B<-text>

Text for the more button.
Default value 'More'.

=item Switch: B<-unselectoptions>

Configuring the unselected tab.
Default value [ -relief => 'flat'].

=item Switch: B<-unselecttabcall>

Calback, called when a tab is unselected.

=back

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $tabside = delete $args->{-'tabside'};
	$tabside = 'top' unless defined $tabside;


	$self->SUPER::Populate($args);

	#configuring the tab bar
	my @barpack = ();
	my @tabpack = ();
	my $buttonside;
	if (($tabside eq 'top') or ($tabside eq 'bottom')) {
		push @barpack, -side => $tabside, -fill => 'both';
		@tabpack = (-side => 'left', -fill => 'y');
		$buttonside = 'right';
	} elsif (($tabside eq 'left') or ($tabside eq 'right')) {
		push @barpack, -side => $tabside, -fill, 'both';
		@tabpack = (-side => 'top', -fill => 'x');
		$buttonside = 'bottom';
	} else {
		carp "illegal value '$tabside' for -tabside. Must be top, bottom, left or right'"
	}

	$self->{TABSIDE} = $tabside;
	$self->{TABPACK} = \@tabpack;

	
	my $barframe = $self->Frame(
		-relief => 'sunken',
		-borderwidth => 1,
	)->pack(@barpack);
	$self->Advertise('BarFrame' => $barframe);
	

	my @side = ();
	@side = (-side => 'left') if (($tabside eq 'top') or ($tabside eq 'bottom'));
	my $tabframe = $barframe->Frame(
	)->pack(@side, -expand => 1, -fill =>'both');
	$self->Advertise('TabFrame' => $tabframe);

	my $morebutton = $barframe->Button(
		-highlightthickness => 0,
		-relief => 'flat',
		-command => ['ListPop', $self],
	);
	$self->Advertise('MoreButton' => $morebutton);
	$self->{MOREBUTTONPACK} = [
		-side => $buttonside,
#		-padx => 2,
#		-pady => 2,
	];
	$self->{MOREBUTTONISPACKED} = 0;

	my $tp = $self->Toplevel(
		-borderwidth => 0,
	);
	$tp->overrideredirect(1);
	$tp->withdraw;
	$self->Advertise('ListWindow', $tp);
	$tp->bind('<Escape>', [$self, 'ListPopDown']);
	
	my @values = ();
	my $listbox = $tp->Scrolled('Listbox',
		-borderwidth => 1,
		-relief => 'sunken',
		-listvariable => \@values,
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select', Ev('x'), Ev('y')]);
	$self->bind('<Button-1>', [$self, 'ListPopDown']);

	my @pfpack = (-side => $tabside, -expand => 1, -fill => 'both');
	my $pageframe = $self->Frame(
	)->pack(@pfpack);
	$self->Advertise('PageFrame' => $pageframe);

	$self->bind('<Configure>', [$self, 'ConfigureCall']);
	$self->{ACTIVE} = 0;
	$self->{AUTOUPDATE} = 1;
	$self->{COVERFRAME} = undef;
	$self->{DISPLAYED} = [];
	$self->{INMAINLOOP} = 0;
	$self->{PAGES} = {};
	$self->{PFPACK} = \@pfpack;
	$self->{SELECTED} = undef;
	$self->{UNDISPLAYED} = \@values;
	$self->{POPPED} = 0;

	$self->ConfigSpecs(
		-autoupdate => ['METHOD', undef, undef, 1],
		-backpagecolor => [{-background => $tabframe}, 'backPageColor', 'BackPageColor', '#8f8f8f'],
		-closeimage => ['PASSIVE', undef, undef, $self->Pixmap(-file => Tk->findINC('close_icon.xpm'))],
		-closetabcall => ['CALLBACK', undef, undef, ['deletePage', $self]],
		-image => [$morebutton],
		-indicatorimage => ['PASSIVE'],
		-indicatortext	=> ['PASSIVE'],
		-onlyselect => ['PASSIVE', undef, undef, 1], 
		-rigid => ['PASSIVE', undef, undef, 1], 
		-selectoptions => ['PASSIVE', undef, undef, [
			-relief => 'raised',
		]],
		-selecttabcall => ['CALLBACK', undef, undef, sub {}],
		-text => [$morebutton, undef, undef, 'More'],
		-tabpack => ['PASSIVE', undef, undef, \@tabpack], 
		-tabpadx => ['PASSIVE', undef, undef, 2], 
		-tabpady => ['PASSIVE', undef, undef, 2], 
		-unselecttabcall => ['CALLBACK', undef, undef, sub {}],
		-unselectoptions => ['PASSIVE', undef, undef, [
			-relief => 'flat',
		]],
		DEFAULT => [$self],
	);
	$self->after(1, ['PostInit', $self]);
}

=head1 METHODS

=over 4

=item B<addPage>I<($name, @options)>

Adds a tab. You can specify following options:

=over 4

B<-closebutton>

Default is 0. If set a close button will be added to the tab.

B<-title>

Text on the tab. If not set, it will be equal to $name.

B<-titleimg>

Display an image instead of a text.

=back

=cut

sub addPage {
	my $self = shift;
	my $name  = shift;
	my %opt = (@_);

	my $tabside = $self->{TABSIDE};
	if ($tabside eq 'left') {
		$opt{'-anchor'} = 'e'
	} elsif ($tabside eq 'right') {
		$opt{'-anchor'} = 'w'
	}
	
	my $title = delete $opt{'-title'};
	$title = $name unless defined $title;
	
	my $uo = $self->cget('-unselectoptions');
	
# 	$self->update;
	my $tab = $self->Subwidget('TabFrame')->NameTab(%opt, @$uo,
		-name => $name,
		-title => $title,
		-background => $self->cget('-backpagecolor'),
		-clickcall => ['ClickCall', $self],
		-closecall => $self->cget('-closetabcall'),
		-indicatorimage => $self->cget('-indicatorimage'),
		-indicatortext => $self->cget('-indicatortext'),
		-motioncall => ['MotionCall', $self],
		-releasecall => ['ReleaseCall', $self],
		-tpadx => $self->cget('-tabpadx'),
		-tpady => $self->cget('-tabpady'),
#		-borderwidth => 4,
	);
	my $ud = $self->{UNDISPLAYED};
	push @$ud, $name;
	my $page = $self->Subwidget('PageFrame')->Frame(-width => 10, -height => 10);

	my $pages = $self->{PAGES};
	$self->{PAGES}->{$name} = [$tab, $page];
	$self->UpdateTabs if $self->{INMAINLOOP} and $self->autoupdate;

	return $page
}

=item B<autoupdate>I<(?$boolean?)>

Sets and returns the B<autoupdate> flag.
See the B<-autoupdate> option.

=cut

sub autoupdate {
	my ($self, $flag) = @_;
	if (defined $flag) {
		$self->{AUTOUPDATE} = $flag;
		$self->UpdateTabs if $flag and $self->{INMAINLOOP};
	}
	return $self->{AUTOUPDATE};
}

sub ClickCall {
	my ($self, $name) = @_;
	$self->{ACTIVE} = 1;
	my $sel = $self->Selected;
	if ((defined $sel) and ($sel eq $name)) {
		$self->unselectPage unless $self->cget('-onlyselect');
	} else {
		$self->selectPage($name);
	}
}

sub ConfigureCall {
	my $self = shift;
	$self->UpdateTabs;
}

sub CoverClear {
	my $self = shift;
	my $cover = $self->{COVERFRAME};
	return unless defined $cover;
	$cover->placeForget;
}

sub CoverUp {
	my $self = shift;
	$self->CoverClear;
	my $cover = $self->{COVERFRAME};
	$cover = $self->Subwidget('BarFrame')->Frame unless defined $cover;
	
	my $page = $self->Selected;
	return unless defined $page;
	my $tab = $self->getTab($page);
	my $tabside = $self->{TABSIDE};
	my $bf = $self->Subwidget('BarFrame');
	my $tbw = $tab->cget(-borderwidth);
	my $borderoffset = $tbw + $bf->cget(-borderwidth);
	my ($cheight, $cwidth, $cx, $cy);
	if ($tabside eq 'top') {
		$cwidth = $tab->width - (2 * $tbw);
		$cheight = $borderoffset;
		$cx = $tab->x + $tbw;
		$cy = $tab->height - $tbw;
	} elsif ($tabside eq 'bottom') {
		$cwidth = $tab->width - (2 * $tbw);
		$cheight = $borderoffset;
		$cx = $tab->x + $tbw;
		$cy = - $tbw;
	} elsif ($tabside eq 'left') {
		$cwidth = $borderoffset;
		$cheight = $tab->height - (2 * $tbw);
		$cx = $tab->width - $tbw;
		$cy =  $tab->y + $tbw;
	} elsif ($tabside eq 'right') {
		$cwidth = $borderoffset;
		$cheight = $tab->height - (2 * $tbw);
		$cx = - $tbw;
		$cy =  $tab->y + $tbw;
	}
	$cover->configure(
#		-background => 'red',
		-height => $cheight,
		-width => $cwidth,
	);
	$cover->place(
		-x => $cx,
		-y => $cy,
	);
	$cover->raise;
	$self->{COVERFRAME} = $cover;
}

=item B<deletePage>I<($name)>

Deletes $name. I<-closetabcall> will be called
in advance. That call should return 1 for the tab
to be closed.

=cut

sub deletePage {
	my ($self, $name) = @_;
	unless ($self->pageExists($name)) {
		croak "Page '$name' does not exist\n";
		return 0
	}
	my $newselect;
	my $selected = $self->Selected;
	if ((defined $selected) and ($self->Selected eq $name)) {
		if ($self->pageCount > 1) {
			my $pos = $self->tabPosition($name);
			if (defined $pos) {
				my $dp = $self->{DISPLAYED};
				$newselect = $dp->[$pos + 1];
				$newselect = $dp->[$pos - 1] unless ((defined $newselect) and ($pos > 1));
			}
		}
		$self->unselectPage;
	}
	if ($self->isDisplayed($name)) {
		my $dp = $self->{DISPLAYED};
		my ($pos) = grep { $dp->[$_] eq $name } 0 .. @$dp - 1;
		splice(@$dp, $pos, 1);
	} else {
		my $ud = $self->{UNDISPLAYED};
		my ($pos) = grep { $ud->[$_] eq $name } 0 .. @$ud - 1;
		splice(@$ud, $pos, 1);
	}
	my $pg = delete $self->{PAGES}->{$name};
	$pg->[0]->destroy;
	$pg->[1]->destroy;
	if ($self->autoupdate) {
		$self->UpdateTabs;
		$self->selectPage($newselect) if ((defined $newselect) and ($self->cget('-onlyselect')));
	}
	return 1
}

=item B<getPage>I<($name)>

Returns the page frame object for $name.

=cut

sub getPage {
	my ($self, $name) = @_;
	return $self->{PAGES}->{$name}->[1] if defined $name;
	return undef;
}

=item B<getTab>I<($name)>

Returns the tab object for $name.

=cut

sub getTab {
	my ($self, $name) = @_;
	return $self->{PAGES}->{$name}->[0] if defined $name;
	return undef;
}

=item B<indicator>I<($name, ?$flag?)>

Sets and clears the indicator in the tab of I<$name>.
Returns it's status. The indicator can be used to
alert the end user to some pending action in this
tab.

=cut

sub indicator {
	my ($self, $name, $flag) = @_;
	my $tab = $self->getTab($name);
	if (defined $flag) {
		$tab->Indicator($flag);
		$self->UpdateTabs;
	}
	return $tab->Indicator
}

=item B<isDisplayed>I<($name)>

Returns true if $name is currently on display

=cut

sub isDisplayed {
	my ($self, $name) = @_;
	my $dp = $self->{DISPLAYED};
	if (my ($match) = grep $_ eq $name, @$dp) {
		return 1
	}
	return 0
}

sub IsFull {
	my ($self, $newtab) = @_;
	my $last = $self->lastDisplayed;
	if (defined $last) {
		my $baroffset = 6;
		my $tab = $self->getTab($last);
		if (($self->{TABSIDE} eq 'top') or ($self->{TABSIDE} eq 'bottom')) {
			my $tabwidth = $tab->reqwidth;
			$tabwidth = $tab->width unless defined $tabwidth;
			my $pos = $tab->x + $tabwidth + $baroffset;
			$pos = $pos + $newtab->reqwidth if defined $newtab;
			my $tabbarwidth = $self->Subwidget('TabFrame')->width;
			return $pos >= $tabbarwidth
		} else {
			my $tabheight = $tab->reqheight;
			$tabheight = $tab->height unless defined $tabheight;
			my $pos = $tab->y + $tabheight + $baroffset;
			$pos = $pos + $newtab->reqheight if defined $newtab;
			my $bar = $self->Subwidget('TabFrame');
			my $tabbarheight = $self->Subwidget('TabFrame')->height;
			return $pos >= $tabbarheight
		}
	}
	return 0;
}

=item B<lastDisplayed>

Returns the name of the last displayed tab.

=cut

sub lastDisplayed {
	my $self = shift;
	my $dp = $self->{DISPLAYED};
	return $dp->[@$dp - 1] if (@$dp);
	return undef
}

sub ListPop {
	my $self = shift;
	if ($self->{POPPED}) {
		$self->ListPopDown;
	} else {
		my $entry = $self->Subwidget('MoreButton');
		my $lb = $self->Subwidget('Listbox');
		my $w = $self->Subwidget('ListWindow');
		my $pgs = $self->{PAGES};
		my @pages = sort keys %$pgs;
		my $values = $self->{LISTVALUES};
		$values = [];
		for (@pages) {
			push @$values, $_ unless $self->isDisplayed($_);
		}
		if (@$values) {
			my $pf = $self->Subwidget('PageFrame');
			my $width = $pf->width;
			my $height = $pf->height;
			my $x = $pf->rootx;
			my $y = $pf->rooty;
			$w->geometry(sprintf('%dx%d+%d+%d', $width, $height, $x, $y));
			$lb->selectionClear(0, 'end');
			my $curval = '';
			$w->deiconify;
			$w->raise;
			$w->focus;
			$self->{'_BE_grabinfo'} = $w->grabSave;
			$self->grabGlobal;
		}
		$self->{POPPED} = 1;
	}
}

sub ListPopDown {
	my $self = shift;
	my $w = $self->Subwidget('ListWindow');
	$w->withdraw;
	$self->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
	$self->{POPPED} = 0;
}

sub _MoveNext {
	my ($self, $name) = @_;
	my $tab = $self->getTab($name);
	my $pos = $self->tabPosition($name);
	my $dp = $self->{DISPLAYED};
	if ($pos < @$dp - 1) {
		my $next = $self->getTab($dp->[$pos + 1]);
		$self->PackTab($name, -after => $next);
		splice(@$dp, $pos, 1);
		splice(@$dp, $pos + 1, 0, $name);
	}
}

sub _MovePrevious {
	my ($self, $name) = @_;
	my $tab = $self->getTab($name);
	my $pos = $self->tabPosition($name);
	my $dp = $self->{DISPLAYED};
	if ($pos > 0) {
		my $prev = $self->getTab($dp->[$pos - 1]);
		$self->PackTab($name, -before => $prev);
		splice(@$dp, $pos, 1);
		splice(@$dp, $pos - 1, 0, $name);
	}
}

sub MotionCall {
	my ($self, $name, $x, $y) = @_;
	if ($self->{ACTIVE}) {
		my $tab = $self->getTab($name);
		unless (exists $self->{CURSORSAVE}) {
			$self->{CURSORSAVE} = $tab->cget('-cursor');
			$tab->configure(-cursor => 'hand1');
		}
		my $nmult = 1.5;
		my $pmult = -0.5;
		if (($self->{TABSIDE} eq 'top') or ($self->{TABSIDE} eq 'bottom')) {
			my $width = $tab->width;
			if ($x > ($width * $nmult)) {
				$self->_MoveNext($name);
			} elsif ($x < ($width * $pmult)) {
				$self->_MovePrevious($name);
			}
		} else {
			my $height = $tab->height;
			if ($y > ($height * $nmult)) {
				$self->_MoveNext($name);
			} elsif ($y < ($height * $pmult)) {
				$self->_MovePrevious($name);
			}
		}
	}
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	my $list = $self->Subwidget('Listbox');
	$list->selectionClear(0, 'end');
	$list->selectionSet('@' . "$x,$y");
}

sub PackTab {
	my $self = shift;
	my $name = shift;
	my $o = $self->{TABPACK};
	my $tabframe = $self->Subwidget('TabFrame');
	my $tab = $self->getTab($name);
	$tab->pack(@_, @$o,
# 		-side => $self->{TABPACK},
	);
}

=item B<pageCount>

Returns the number of pages

=cut

sub pageCount {
	my $self = shift;
	my $pg = $self->{PAGES};
	my @keys = keys %$pg;
	my $size = @keys;
	return $size;
}

=item B<pageExists>I<($name)>

Returns true if $name exists

=cut

sub pageExists {
	my ($self, $name) = @_;
	return exists $self->{PAGES}->{$name};
}

sub PostInit {
	my $self = shift;
	$self->{INMAINLOOP} = 1;
	$self->UpdateTabs;
	my $dp = $self->{DISPLAYED};
	$self->selectPage($dp->[0]) if ((@$dp) and ($self->cget('-onlyselect')));
}

sub ReleaseCall {
	my ($self, $name) = @_;
	my $tab = $self->getTab($name);
	$self->{ACTIVE} = 0;
	if (exists $self->{CURSORSAVE}) {
		$tab->configure(-cursor => $self->{CURSORSAVE});
		delete $self->{CURSORSAVE};
	}
	delete $self->{MOTION};
}

=item B<renamePage>I<($old, $new)>

Rename a page.

=cut

sub renamePage {
	my ($self, $old, $new) = @_;
	my $page = $self->{PAGES}->{$old};
	$self->{PAGES}->{$new} = $page;
	delete $self->{PAGES}->{$old};
	$self->{SELECTED} = $new if ($self->Selected eq $old);
	if ($self->isDisplayed($old)) {
		my $pos = $self->tabPosition($old);
		$self->{DISPLAYED}->[$pos] = $new
	} else {
		my $ud = $self->{UNDISPLAYED};
		my ($index) = grep { $ud->[$_] eq $old } 0 .. @$ud;
		$self->{UNDISPLAYED}->[$index] = $new
	}
}

sub Select {
	my $self = shift;
	my $list = $self->Subwidget('Listbox');
	my $item = $list->get($list->curselection);
	$self->selectPage($item);
	$self->ListPopDown;
}

sub Selected {	return $_[0]->{SELECTED} }

=item B<selectPage>I<($name)>

Select page $name.

If $name is not displayed it is moved to the
front of the displayed items.

=cut

sub selectPage {
	my ($self, $name) = @_;
	return unless defined $name;
	my $sel = $self->Selected;
	return if (defined $sel) and ($name eq $sel);
	my $page = $self->{PAGES}->{$name};
	if (defined $page) {
		$self->unselectPage;
		my $pfpack = $self->{PFPACK};
		$self->Subwidget('PageFrame')->pack(@$pfpack) unless $self->cget('-rigid');

		#make sure the tab is displayed
		unless ($self->isDisplayed($name)) {
			my $ud = $self->{UNDISPLAYED};
			my @undisp = @$ud;
			my ($index) = grep { $undisp[$_] eq $name } 0 .. $#undisp;
			splice(@$ud, $index, 1);
			my $dp = $self->{DISPLAYED};
			my @options = ();
			push @options, -before => $self->getTab($dp->[0]) if @$dp;
			$self->PackTab($name, @options);
			unshift @$dp, $name;
			$self->UpdateTabs;
		}
		my ($tab, $frame) = @$page;

		#configure the tab
		my $o = $self->cget('-selectoptions');
		$tab->configure(@$o,
			-background => $self->cget('-background'),
		);
		$frame->pack(-expand => 1, -fill => 'both');
		
		$self->{SELECTED} = $name;
		$self->CoverUp;
		$self->Callback('-selecttabcall', $name);
	} else {
		croak "Page $name does not exist"
	}
}

=item B<tabList>

Returns a sorted list of all page names.

=cut

sub tabList {
	my $self = shift;
	my $p = $self->{PAGES};
	return sort keys %$p
}

=item B<tabPosition>I<($name)>

Returns the position on the tab frame of $name.
Returns undef for undisplayed pages.

=cut

sub tabPosition {
	my ($self, $name) = @_;
	my $dp = $self->{DISPLAYED};
	my $size = @$dp - 1;
	my ($index) = grep { $dp->[$_] eq $name } 0 .. $size;
	return $index
}

sub unselectPage {
	my $self = shift;
	my $name = $self->{SELECTED};
	if (defined $name) {
		my $page = $self->{PAGES}->{$name};
		my ($tab, $frame) = @$page;
		my $o = $self->cget('-unselectoptions');
		$tab->configure(@$o,
			-background => $self->cget('-backpagecolor'),
		);
		$frame->packForget;
		$self->{SELECTED} = undef;
		$self->Subwidget('PageFrame')->packForget unless $self->cget('-rigid');
		$self->CoverClear;
		$self->Callback('-unselecttabcall', $name);
	}
}

sub UpdateTabs {
	my $self = shift;
	my $ud = $self->{UNDISPLAYED};
	my $dp = $self->{DISPLAYED};
	my $notempty = @$dp;
	# TODO find out why 'if Exists $self' is necessary
	$self->update if Exists $self;
	while ($self->IsFull) {
		my $last = pop @$dp;
		my $tab = $self->getTab($last);
		$tab->packForget;
		$self->update;
		unshift @$ud, $last;
	}
	return unless @$ud;
	my $name = $ud->[0];
	while ((@$ud) and (not $self->IsFull($self->getTab($name)))) {
		$self->PackTab($name);
		push @$dp, $name;
		shift @$ud;
		$name = $ud->[0];
		$self->update;
	}
	my $b = $self->Subwidget('MoreButton');
	if (@$ud) {
		unless ($self->{MOREBUTTONISPACKED}) {
			my $o = $self->{MOREBUTTONPACK};
			$b->pack(@$o);
			$self->after(50, ['CoverUp', $self]);
			$self->{MOREBUTTONISPACKED} = 1;
		}
	} else {
		if ($self->{MOREBUTTONISPACKED}) {
			$b->packForget;
			$self->after(50, ['CoverUp', $self]);
			$self->{MOREBUTTONISPACKED} = 0;
		}
	}
	delete $self->{'ccafterid'}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;









