package Tk::ListBrowser;

=head1 NAME

Tk::ListBrowser - Tk::IconList like mega widget.

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'ListBrowser';

use Math::Round;
use Tie::Watch;
use Tk;
require Tk::ListBrowser::Item;

#used in formatText
my $dlmreg = qr/\.|\(|\)|\:|\!|\+|\,|\-|\<|\=|\>|\%|\&|\*|\"|\'|\/|\;|\?|\[|\]|\^|\{|\||\}|\~|\\|\$|\@|\#|\`|\s/;

#available refresh handlers
my %handlers = (
	bar => 'Bar',
	column => 'Column',
	list => 'List',
	row => 'Row',
);

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options)->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

B<Tk::ListBrowser> is inspired on L<Tk::IconList> but with added features
like row as well as column, list and bar oriented display. There are plenty
of options to set the presentation of text items.

Scrollbars are automatically shown when needed.

Screenshots: L<https://github.com/haje61/Tk-ListBrowser/tree/main/screenshots>

=head1 OPTIONS

Tk::ListBrowser uses the following standardoptions: B<-background>, B<-font>,
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

=item B<list>

Presents a one column vertical list.

=item B<row>

Presents a row centered two dimensional list.

=back

=item Switch B<-browsecmd>

Callback, called when an is selected. Gets the selection list as parameters.

=item Switch B<-command>

Callback, called when an entry is double clicked or return was pressed. Gets the selection list as parameters.

=item Name B<filterDelay>

=item Class B<FilterDelay>

=item Switch B<-filterdelay>

Default value 300 miliseconds. When the filter bar is active this is the wait time
between a keystroke and a corresponding filter action. If a key is pressed before
time out, the timer is reset.

=item Switch B<-filteron>

Default value I<false>. If set the filter entry will allways be visible.

=item Switch B<-itemtype>

Default value I<imagetext>. Can be I<image>, I<imagetext> or I<text>.

=item Switch B<-motionselect>

Default value I<false>. Only works when I<-selectmode> is set to single.
Automatically selects an entry when the pointer is hovering over it.

=item Switch B<-nofilter>

Default value I<false>. If set the filter entry is not available.
This option supercedes the I<-filteron> option.

Only available at create time.

=item Switch B<-selectmode>

Default value I<single>. Can either be I<single> or I<multiple>.
In single mode only one entry in the list can be selected at all times.
In multiple mode more than one entry can be selected.

=item Switch B<-textanchor>

Default value empty string. This value centers the text in it's cativy.
Besides an empty string the possible values are I<n>, I<ne>, I<nw>, I<s>, I<se>, I<sw>, I<e> and I<w>.
The letters stand for the first letter of the wind directions. They tell where to position the text in
it's cavity.

=item Switch B<-textjustify>

Default value I<center>. Can be I<center>, I<left> or I<right>. Specifies
how multiline or wrapped text is justified.

=item Switch B<-textside>

Default value I<bottom>. Possible values are I<bottom>, I<top>, I<left>, I<right>,
or I<none>. It sets at which side the text should appear next to the icon.
If you change this option on the fly you have to call I<refresh>
to see the changes. This option only has meaning when I<-itemtype> is set to 'imagetext'.

=item Switch B<-wraplength>

Default value 0. You can set it to a positive integer of at least 40 to invoke word or character wrapping.
The value determines the maximum width in pixels of a text block. It will attempt a word
wrap and will do a character wrap if that fails.

If you change this option on the fly you have to call I<refresh> to see the changes. 

If you try to set it to a lower value than 40, you will be overruled.
This is to prevent the wrap length to become smaller that the with of one character, which
would freeze you application. This also means watching out for using very big fonts.

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $nofilter = delete $args->{'-nofilter'};
	$nofilter = '' unless defined $nofilter;
	
	$self->SUPER::Populate($args);
	
	my $canv = $self->Scrolled('Canvas',
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	my $c = $canv->Subwidget('scrolled');
	$c->configure(-takefocus => 1);
	$self->Advertise('Canvas', $c);
	$self->bind('<Configure>', [ $self, 'refresh' ]);

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

	$c->bindtags([$c, $c->toplevel, 'all']);
	#keyboard bindings
	for (qw/Down End Escape Home Left Return Right space Up/) {
		my $bnd = $_;
		$c->Tk::bind("<$bnd>", [$self, 'KeyPress', $bnd]);
		$c->Tk::bind("<Shift-$bnd>", [$self, 'KeyPress', "Shift-$bnd"]);
		$c->Tk::bind("<Control-$bnd>", [$self, 'KeyPress', "Control-$bnd"]);
		$c->Tk::bind("<Control-Shift-$bnd>", [$self, 'KeyPress', "Control-Shift-$bnd"]);
	};

	#setting up the filter
	unless ($nofilter) {
		my $filter = '';
		$self->Advertise('Filter', \$filter);
		my $fframe = $self->Frame;
		$self->Advertise('FilterFrame', $fframe);
		my $fentry = $fframe->Entry(
			-textvariable => \$filter,
		)->pack(-side => 'left', -pady => 2, -expand => 1, -fill => 'x');
		$self->Advertise('FilterEntry', $fentry);
		$fentry->bind('<Control-f>', [$self, 'filterFlip']);
		$fentry->bind('<Escape>', [$self, 'filterFlip']);
		$fentry->bind('<Button-1>', [$self, 'filterClick']);
		$fentry->bind('<KeyRelease>', [$self, 'filterActivate']);
	}


	$self->{ANCHOR} = undef;
	$self->{ARRANGE} = undef;
	$self->{HANDLER} = undef;
	$self->{POOL} = [];
	$self->{ROWS} = 0;
	$self->{WRAPLENGTH} = 0;

	$self->ConfigSpecs(
		-arrange => ['METHOD', undef, undef, 'row'],
		-background => [$c, 'background', 'Background', '#E8E8E8'],
		-browsecmd => ['CALLBACK'],
		-command => ['CALLBACK'],
		-filterdelay => ['PASSIVE', 'filterDelay', 'FilterDelay', 300],
		-filteron => ['PASSIVE', undef, undef, ''],
		-font => ['PASSIVE', 'font', 'Font', 'Monotype 10'],
		-foreground => ['PASSIVE', 'foreground', 'foreground', '#3C3C3C'],
		-itemtype => ['PASSIVE', undef, undef, 'imagetext'],
		-motionselect => ['PASSIVE', undef, undef, ''],
		-selectbackground => ['PASSIVE', 'selectBackground', 'SelectBackground', '#A0A0FF'],
		-selectforeground => ['PASSIVE', 'selectForeground', 'SelectForeground', '#FAF9EA'],
		-selectmode => ['PASSIVE', undef, undef, 'single'],
		-textanchor => ['PASSIVE', undef, undef, ''],
		-textjustify => ['PASSIVE', undef, undef, 'center'],
		-textside => ['PASSIVE', undef, undef, 'bottom'],
		-wraplength => ['METHOD', undef, undef, 0],
		DEFAULT => [ $c ],
	);
	$self->Delegates(
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
	$self->after(10, sub { $self->filterFlip if $self->cget('-filteron') });
	$c->CanvasFocus
}

sub _handler { return $_[0]->{HANDLER} }

=item B<add>I<(?$name?, %options)>

Adds I<$name> to the list with I<%options>. I<$name> must not yet exist.
Possible options are:

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
	my $after = delete $options{'-after'};
	my $before = delete $options{'-before'};
	my $item = new Tk::ListBrowser::Item(
		%options,
		-canvas => $self,
		-name => $name,
	);
	my $pool = $self->pool;
	if (defined $after) {
		my $index = $self->index($after);
		splice(@$pool, $index + 1, 0, $item) if defined $index;
		croak "Entry for -after '$after' not found" unless defined $index;
	} elsif (defined $before) {
		my $index = $self->index($before);
		splice(@$pool, $index, 0, $item) if defined $index;
		croak "Entry for -before '$before' not found" unless defined $index;
	} else {
		push @$pool, $item
	}
	return $item
}

=item B<anchorClear>

Clears the keyboard anchor.

=cut

sub anchorClear {
	my $self = shift;
	my $pool = $self->pool;
	for (@$pool) {
		$_->anchor(0)
	}
}

=item B<anchorGet>

Returns a reference to the L<Tk::ImageBrowser::Icon> object
that currently holds the anchor.

=cut

sub anchorGet {
	my $self = shift;
	my $pool = $self->pool;
	for (0 .. @$pool - 1) {
		my $obj = $pool->[$_];
		return $obj if $obj->anchored
	}
	return undef
}

sub anchorInitialize {
	my $self = shift;
	my $i = $self->anchorGet;
	unless (defined $i) {
		my $name = $self->pool->[0]->name;
		$self->anchorSet($name) unless defined $self->anchorGet;
		$self->see($name);
		return 1
	}
	return ''
}

sub anchor {
	my $self = shift;
	$self->{ANCHOR} = shift if @_;
	return $self->{ANCHOR}
}

=item B<anchorSet>I<($name)>

Sets the keyboard anchor to I<$name>

=cut

sub anchorSet {
	my ($self, $name) = @_;
	my $item = $self->get($name);
	if (defined $item) {
		$self->anchorClear;
		$item->anchor(1);
		$self->anchor($item);
		return 1
	}
	return ''
}

=item B<anchorSetColumnRow>I<($column, $row)>

Sets the anchor in $column and $row

=cut

sub anchorSetColumnRow {
	my ($self, $column, $row) = @_;
	my $pool = $self->pool;
	my $index = $self->indexColumnRow($column, $row);
	if (defined $index) {
		return $self->anchorSet($pool->[$index]->name);
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
	my $item = $self->initem($x, $y);
	if (defined $item) {
		$self->selectionClear;
		$item->select(1);
		$self->anchorSet($item->name);
		$self->Callback('-browsecmd', $item->name);
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
		my $pool = $self->pool;
		my @sel = $self->selectionGet;
		unless (@sel) {
			my $start = $pool->[0]->name;
			$self->selectionSet($pool->[0]->name, $item->name);
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

=item B<canvasSize>

Returns the available width and height of the Danvas widget.

=cut

sub canvasSize {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	my $offset = $c->cget('-highlightthickness') + $c->cget('-borderwidth');
	return ($c->width - $offset, $c->height - $offset);
}

=item B<clear>

Clears the canvas.

=cut

sub clear {
	my $self = shift;

	$self->anchorClear;
	$self->selectionClear;

	my $pool = $self->pool;
	grep { $_->clear } @$pool;

	my $c = $self->Subwidget('Canvas');
	$c->xview(moveto => 0);
	$c->yview(moveto => 0);
	$c->configure(-scrollregion => [0, 0, 0, 0]);
}

=item B<delete>I<(?$name?)>

Deletes entry I<$name>. You must call I<refresh> to see your changes.

=cut

sub delete {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $index = $self->index($name);
	if (defined $index) {
		my ($del) = splice(@$pool, $index, 1);
		$del->clear;
		return
	}
	croak "Entry '$name' not found"
}

=item B<deleteAll>

Deletes all entries. You must call refresh to see your changes.

=cut

sub deleteAll {
	my $self = shift;
	my $pool = $self->pool;
	grep { $self->delete($_->name) } @$pool;
	$self->clear;
}

my %validconfigs = (
	-data => 1,
	-hidden => 1,
	-image => 1,
	-text => 1
);

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
	unless (exists $validconfigs{$option}) {
		croak "Invalid option '$option'";
		return
	}
	$option =~ s/^\-//;
	return $i->$option
}

=item B<entryConfigure>I<($name, %options)>

Sets the value of I<%options> held by $name. Valid
options are I<-data>, I<-hidden>, I<-image> and I<-text>.
You can specify multiple options.

=cut

sub entryConfigure {
	my $self = shift;
	my $name = shift;
	my $i = $self->get($name);
	unless (defined $i) {
		croak "Entry '$name' not found";
		return
	}
	while (@_) {
		my $option = shift;
		my $value = shift;
		unless (exists $validconfigs{$option}) {
			croak "Invalid option '$option'";
			return
		}
		$option =~ s/^\-//;
		$i->$option($value)
	}
}

sub filter {
	my ($self, $filter, $value) = @_;
	return 1 if $filter eq '';
	$filter = quotemeta($filter);
	return 1 if $value eq '';
	return $value =~ /$filter/i;
}

sub filterClick {
	my $self = shift;
	my $e = $self->Subwidget('FilterEntry');
	my $text = $e->get;
	$e->delete(0, 'end') if $text eq 'Filter';
}

sub filterActivate {
	my $self = shift;
	my $filter_id = $self->{'filter_id'};
	if (defined $filter_id) {
		$self->afterCancel($filter_id);
	}
	$filter_id = $self->after($self->cget('-filterdelay'), ['filterRefresh', $self]);
	$self->{'filter_id'} = $filter_id;
}

=item B<filterFlip>

Hides the filter bar if it is shown. Shows it if it is hidden.

=cut

sub filterFlip {
	my $self = shift;
	my $f = $self->Subwidget('FilterFrame');
	if (defined $f) {
		my $e = $self->Subwidget('FilterEntry');
		if ($f->ismapped) {
			unless ($self->cget('-filteron')) {
				$f->packForget;
				$e->delete(0, 'end');
				$self->CanvasFocus;
			}
		} else {
			$e->insert('end', 'Filter');
			$f->pack(-fill => 'x');
		}
	}
}

sub filterRefresh {
	my $self = shift;
	my $pool = $self->pool;
	my $filter = $self->Subwidget('FilterEntry')->get;
	for (@$pool) {
		if ($self->filter($filter, $_->text)) {
			$_->hidden('')
		} else {
			$_->hidden(1)
		}
	}
	delete $self->{'filter_id'};
	$self->refresh;
}

sub focus { $_[0]->CanvasFocus }

=item B<get>I<(?$name?)>

Returns a reference to the L<Tk::FileBrowser::Icon> object of I<$name>.

=cut

sub get {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my @hit = grep { $_->name eq $name } @$pool;
	return $hit[0]
}

=item B<get>I<(?$name?)>

Returns a list of all L<Tk::FileBrowser::Icon> objects.

=cut

sub getAll {
	my $self = shift;
	my $pool = $self->pool;
	return @$pool
}

=item B<getColumn>I<($column)>

Returns a list of referencec to all L<Tk::FileBrowser::Icon> objects in column I<$column>.

=cut

sub getColumn {
	my ($self, $col) = @_;
	my $pool = $self->pool;
	my @hits = grep { $_->column eq $col } @$pool;
	return @hits
}

=item B<getIndex>I<($index)>

Returns a reference to the L<Tk::FileBrowser::Icon> object at index I<$index>

=cut

sub getIndex {
	my ($self, $index) = @_;
	return undef unless defined $index;
	my $pool = $self->pool;
	if (($index < 0) or ($index > @$pool - 1)) {
		croak "Index '$index' out of range";
		return undef ;
	}
	return $pool->[$index];
}

=item B<getRow>I<($row)>

Returns a list of referencec to all L<Tk::FileBrowser::Icon> objects in row I<$row>.

=cut

sub getRow {
	my ($self, $row) = @_;
	my $pool = $self->pool;
	my @hits = grep { $_->row eq $row } @$pool;
	return @hits
}

=item B<hide>I<($name)>

Hides entry I<$name>. Call I<refresh> to see changes.

=cut

sub hide {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	$a->hidden(1) if defined $a
}

=item B<index>

Returns the numerical index of entry I<$name>.

=cut

sub index {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my ($index) = grep { $pool->[$_]->name eq $name } 0 .. @$pool - 1;
	return $index
}

=item B<indexColumnRow>I<($column, $row)>

Returns the numerical index of the entry at I<$column>, I<$row>.

=cut

sub indexColumnRow {
	my ($self, $column, $row) = @_;
	my $pool = $self->pool;
	my ($index) = grep { ($pool->[$_]->column eq $column) and  ($pool->[$_]->row eq $row) } 0 .. @$pool - 1;
	return $index
}

=item B<indexLast>

Returns the numerical index of the last entry in the list.

=cut

sub indexLast {
	my $self = shift;
	my $pool = $self->pool;
	my $last = @$pool - 1;
	return $last
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
	my $a = $self->get($name);
	return defined $a;
}

=item B<infoFirst>

Returns the name of the first entry in the list.

=cut

sub infoFirst {
	my $self = shift;
	my $pool = $self->pool;
	return undef unless @$pool;
	return $pool->[0]->name
}

=item B<infoHidden>I<($name)>

Returns the boolean hidden state of entry I<$name>.

=cut

sub infoHidden {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	if (defined $a) {
		my $flag = $a->hidden;
		$flag = '' if $flag eq 0;
		return $flag
	}
	croak "Entry '$name' not found";
	return undef
}

=item B<infoLast>

Returns the name of the last entry in the list.

=cut

sub infoLast {
	my $self = shift;
	my $pool = $self->pool;
	return undef unless @$pool;
	return $pool->[@$pool - 1]->name
}

=item B<infoList>

Returns a list of all entry names in the list.

=cut

sub infoList {
	my $self = shift;
	my $pool = $self->pool;
	my @list;
	for (@$pool) { push @list, $_->name }
	return @list
}

=item B<infoNext>I<($name)>

Returns the name of the next entry of I<$name>.
Returns undef if I<$name> is the last entry in the list.

=cut

sub infoNext {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	return undef if $a eq @$pool - 1;
	return $pool->[$a + 1]->name;
}

=item B<infoPev>I<($name)>

Returns the name of the previous entry of I<$name>.
Returns undef if I<$name> is the first entry in the list.

=cut

sub infoPrev {
	my ($self, $name) = @_;
	my $pool = $self->pool;
	my $a = $self->index($name);
	unless (defined $a) {
		croak "Entry '$name' not found";
		return
	}
	return undef if $a eq 0;
	return $pool->[$a - 1]->name;
}

=item B<infoSelection>

Same as I<selectionGet>.

=cut

sub infoSelection {	return $_[0]->selectionGet }

sub initem {
	my ($self, $x, $y) = @_;
	$self->CanvasFocus;
	$x = int($self->canvasx($x));
	$y = int($self->canvasy($y));
	my $pool = $self->pool;
	for (@$pool) {
		if ($_->inregion($x, $y)) {
			return $_;
		}
	}
	return undef
}

sub KeyArrowNavig {
	my ($self, $dcol, $drow) = @_;
	my $h = $self->_handler;
	my $i = $h->KeyArrowNavig($dcol, $drow);
	if (defined $i) {
		my $name = $i->name;
		$self->see($name);
		$self->anchorSet($name);
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
			my $name = $self->pool->[$index]->name;
			$flag = $self->anchorSet($name);
			$self->see($name) if $flag;
		}
	}
}

sub KeyPress {
	my ($self, $key) = @_;
	my $pool = $self->pool;
	my $h = $self->_handler;
	return unless @$pool;
	my @sel = $self->selectionGet;

	if ($key eq 'Return') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $name = $i->name;
		$self->selectionSet($name);
		$self->Callback('-command', $name);
		return
	}
	if ($key eq 'Escape') {
		if ($self->Subwidget('FilterEntry')->ismapped) {
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
		my $name = $pool->[@$pool - 1]->name;
		$self->see($name);
		$self->after(50, sub { $self->anchorSet($name) });
		return
	}
	if ($key eq 'Home') {
		return if $self->anchorInitialize;
		my $i = $self->anchorGet;
		my $row = $i->row;
		my $index = $self->indexColumnRow(0, $row);
		my $name = $pool->[$index]->name;
		$self->anchorSet($name);
		$self->see($name);
		return
	}
	if ($key eq 'Control-Home') {
		my $name = $pool->[0]->name;
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
		my $name = $pool->[@$pool - 1]->name;
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
		if ($self->anchorSet($pool->[0]->name)) {
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
	my $pool = $self->pool;
	my @row = $self->getRow($row);
	return $row[@row - 1]->column;
}

=item B<lastRowInColumn>I<($column)>

Returns the number of the last row in I<$column>.

=cut

sub lastRowInColumn {
	my ($self, $column) = @_;
	my $pool = $self->pool;
	my @column = $self->getColumn($column);
	return $column[@column - 1]->row;
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

sub pool { return $_[0]->{POOL} }

sub refreshTimer {
	my $self = shift;
	delete $self->{'timer_id'};
	$self->refresh(1);
}

=item B<refresh>

Clears the canvas and rebuilds it. Call this method after you are done making changes.

=cut

sub refresh {
	my ($self, $timer) = @_;
	if (my $id = $self->{'timer_id'}) {
		$self->afterCancel($id);
		my $nid = $self->after(50, ['refreshTimer', $self]);
		$self->{'timer_id'} = $nid;
	}
	unless (defined $timer) {
		my $id = $self->after(50, ['refreshTimer', $self]);
		$self->{'timer_id'} = $id;
		return
	}
	$self->_handler->refresh;
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

	#horizontal
	my ($vl, $vr) = $self->xview;
	my $div = $cx2 - $cx1;
	if (($div > 0) and ($ix1/$div < $vl)) { #going to the left
		$self->xview(moveto => $ix1/$div);
	} elsif (($div > 0) and ($ix2/$div > $vr)) {	#going to the right.
		my $mr = ($ix2 - $cwidth + 2)/$div;
		$self->xview(moveto => $mr);
	}
	
	#vertical
	my ($vt, $vb) = $self->yview;
	$div = $cy2 - $cy1;
	if (($div > 0) and ($iy1/$div < $vt)) { #going up
		$self->yview(moveto => $iy1/$div);
	} elsif (($div > 0) and ($iy2/$div > $vb)){	#going down.
		my $mr = ($iy2 - $cheight + 2)/$div;
		$self->yview(moveto => $mr);
	}
}

=item B<selectAll>

Selects all entries.

=cut

sub selectAll {
	my $self = shift;
	return if $self->cget('-selectmode') eq 'single';
	my $pool = $self->pool;
	grep { $_->select } @$pool;
}

=item B<selectionClear>

Clears the entire selection.

=cut

sub selectionClear {
	my $self = shift;
	my $pool = $self->pool;
	grep { $_->select(0) } @$pool;
}

sub selectionFlip {
	my ($self, $begin, $end) = @_;
	($begin, $end) = $self->selectionIndex($begin, $end);
	my $pool = $self->pool;
	for ($begin .. $end) {
		my $i = $pool->[$_];
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
	my $pool = $self->pool;
	for (@$pool) { push @list, $_->name  if $_->selected }
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

=item B<selectionSet>I<($begin, ?$end?)>

Selects entry I<$begin>. If you specify I<$end> the
range from I<$begin> to I<$end> will be selected.

=cut

sub selectionSet {
	my ($self, $begin, $end) = @_;
	($begin, $end) = $self->selectionIndex($begin, $end);
	my $pool = $self->pool;
	for ($begin .. $end) {
		my $i = $pool->[$_];
		$self->selectionClear if $self->cget('-selectmode') eq 'single';
		$i->select #unless $i->selected;
	}
}

=item B<selectionUnSet>I<($begin, $end)>

Clears the selection of entry I<$begin>. If you specify I<$end> the
range from I<$begin> to I<$end> will be cleared from the selection.

=cut

sub selectionUnSet {
	my ($self, $begin, $end) = @_;
	$end = $begin unless defined $end;
	($begin, $end) = $self->selectionIndex($begin, $end);
	my $pool = $self->pool;
	for ($begin .. $end) {
		my $i = $pool->[$_];
		$i->select(0) #if $i->selected;
	}
}

=item B<show>I<($name)>

Shows entry I<$name>. Call I<refresh> to see changes.

=cut

sub show {
	my ($self, $name) = @_;
	my $a = $self->get($name);
	$a->hidden(0) if defined $a
}

=item B<textFormat>I<($text)>

Formats, basically wraps, I<$text> taking the option I<-wraplength> into account.
I<$text> can be a multi line string.

=cut

sub textFormat {
	my ($self, $text) = @_;
	my $wraplength = $self->cget('-wraplength');
	my $font = $self->cget('-font');
	return $text if $wraplength <= 0;
	my @lines = split (/\n/, $text);
	my @out;
	for (@lines) {
		my $line = $_;
		my $length = $self->fontMeasure($font, $line);
		if ($length > $wraplength) {
			my $res = $length / length($line);
			my $oklength = int($wraplength/$res);
			while (length($line) > $oklength) {
				my $t = substr($line, 0, $oklength, '');
				if ($t =~ s/([$dlmreg])([^$dlmreg]+$)//) {
					$line = "$2$line";
					$t = "$t$1";
				}
				push @out, $t;
			}
			push @out, $line;
		} else {
			push @out, $line;
		}
	}
	my $result = '';
	while (@out) {
		$result = $result . shift @out;
		$result = "$result\n" if @out
	}
	return $result
}

=item B<textHeight>I<($text)>

Returns the display height of I<$text> in pixels.
I<$text> can be a multi line string.

=cut

sub textHeight {
	my ($self, $text) = @_;
	return 0 if $text eq '';
	my $height = 1;
	while ($text =~ /\n/g) { $height ++ }
	my $font = $self->cget('-font');
	return ($height * $self->fontMetrics($font, '-linespace')) #+ $self->fontMetrics($font, '-descent');;
}

=item B<textWidth>I<($text)>

Returns the display width of I<$text> in pixels.
I<$text> can be a multi line string.

=cut

sub textWidth {
	my ($self, $text) = @_;
	return $self->fontMeasure($self->cget('-font'), $text) unless $text =~ /\n/;
	my $width = 0;
	while ($text =~ s/^([^\n]*)\n//) {
		my $w = $self->fontMeasure($self->cget('-font'), $1);
		$width = $w if $w > $width;
	}
	if ($text ne '') {
		my $w = $self->fontMeasure($self->cget('-font'), $text);
		$width = $w if $w > $width;
	}
	return $width
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
that by pressing any of the keys below. After that you can start navigating and manipulate selections.

The spacebar selects or deselects the entry that is currently held by the anchor. The I<-browsecmd>
callback is called if the entry is selected.

The return key selects the entry and invokes the I<-command> callback.

You can navigate the list using the arrow keys and the the Home, Control-Home, End and Control-End keys.
Holding shift while pressing these keys manipulates the selection.

The escape key clears the selection and anchor or hides the filter entry if it is visible.

Control-f pops a filter entry. Clicking Control-f again hides it. Filtering is done instantly upon entering
text in. This is influenced by the I<-filteron> and I<-nofilter> options.

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

Work out Tk::ListBrowser::Hlist and Tk::ListBrowser::Tree addons. Add side columns.
Add headers.

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=item L<Tk::ListBrowser::Bar>

=item L<Tk::ListBrowser::Column>

=item L<Tk::ListBrowser::Item>

=item L<Tk::ListBrowser::List>

=item L<Tk::ListBrowser::Row>

=back

=cut

1;