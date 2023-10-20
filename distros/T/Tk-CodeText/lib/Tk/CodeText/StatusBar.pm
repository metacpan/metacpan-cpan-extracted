package Tk::CodeText::StatusBar;

package PopTabs;

use strict;
use warnings;

use base qw(Tk::Derived Tk::Poplevel);

Construct Tk::Widget 'PopTabs';

sub Populate {
	my ($self,$args) = @_;
	
	my $var = delete $args->{'-variable'};
	unless (defined $var) {
		my $val = '';
		$var = \$val;
	}
	$self->SUPER::Populate($args);
	$self->{VAR} = $var;
	$self->CreateWidgets;

	$self->ConfigSpecs(
		-setcall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => [ $self ],
	);
}

sub CreateWidgets {
	my $self = shift;
	$self->Label(
		-anchor => 'w',
		-text => 'Unit:'
	)->pack(-fill => 'x');
	my $var = $self->{VAR};
	$self->Radiobutton(
		-anchor => 'w',
		-text => 'pixels',
		-value => 'p',
		-variable => $var,
	)->pack(-fill => 'x');
	$self->Radiobutton(
		-anchor => 'w',
		-text => 'cm',
		-value => 'c',
		-variable => $var,
	)->pack(-fill => 'x');
	$self->Radiobutton(
		-anchor => 'w',
		-text => 'mm',
		-value => 'm',
		-variable => $var,
	)->pack(-fill => 'x');
	$self->Radiobutton(
		-anchor => 'w',
		-text => 'inch',
		-value => 'i',
		-variable => $var,
	)->pack(-fill => 'x');
	my $f = $self->Frame->pack(-fill => 'x');
	$f->Label(
		-anchor => 'w',
		-text => 'Size:'
	)->pack(-side => 'left');
	my $e = $f->Entry->pack(-side => 'left', -padx => 2, -fill => 'x');
	$self->Advertise(Entry => $e);
	$e->bind('<Escape>', [$self, 'popDown']);
	$self->Button(
		-text => 'Ok',
		-command => ['Select', $self],
	)->pack(-fill, 'x');
}

sub popDown {
	my $self = shift;
	my $f = $self->{'_focus'};
	$f->focus if defined $f;;
	$self->SUPER::popDown;
}

sub popUp {
	my $self = shift;
	my $e = $self->Subwidget('Entry');
	$self->{'_focus'} = $e->focusCurrent;
	$e->focus;
	$self->SUPER::popUp;
}

sub Put {
	my ($self, $value) = @_;
	return unless defined $value;
	if ($value =~ /^(.*)([c,m,i,p])/) {
		my $size = $1;
		my $unit = $2;
		my $e = $self->Subwidget('Entry');
		$e->delete('0', 'end');
		$e->insert('end', $size);
		my $var = $self->Var;
		$$var = $unit;
	}
}

sub Select {
	my $self = shift;
	my $var = $self->Var;
	my $e = $self->Subwidget('Entry');
	my $val = $e->get . $$var;
	$self->Callback('-setcall', $val);
	$self->popDown;
}

sub Var {
	return $_[0]->{VAR};
}

package PopIndent;

use strict;
use warnings;

use base qw(Tk::Derived PopTabs);

Construct Tk::Widget 'PopIndent';

sub AlterSizeState {
	my ($self, $value) = @_;
	my $f = $self->Subwidget('Entry');
	if ($value) {
		$f->configure(-state => 'disabled');
	} else {
		$f->configure(-state => 'normal');
	}
}

sub CreateWidgets {
	my $self = shift;
	$self->Checkbutton(
		-command => sub {
			my $var = $self->Var;
			$self->AlterSizeState($$var)
		},
		-anchor => 'w',
		-text => 'Use tabs',
		-variable => $self->Var,
	)->pack(-fill => 'x');
	my $f = $self->Frame->pack(-fill => 'x');
	$f->Label(
		-anchor => 'w',
		-text => 'Size:'
	)->pack(-side => 'left');
	my $e = $f->Entry->pack(-side => 'left', -padx => 2, -fill => 'x');
	$self->Advertise(Entry => $e);
	$e->bind('<Escape>', [$self, 'popDown']);
	$self->Button(
		-text => 'Ok',
		-command => ['Select', $self],
	)->pack(-fill, 'x');
}

sub Put {
	my ($self, $value) = @_;
	my $e = $self->Subwidget('Entry');
	$e->delete(0, 'end');
	my $var = $self->Var;
	if ($value eq 'tab') {
		$$var = 1;
		$self->AlterSizeState(1);
	} else {
		$$var = 0;
		$self->AlterSizeState(0);
		$e->insert('end', $value);
	}
}

sub Select {
	my $self = shift;
	my $var = $self->Var;
	my $e = $self->Subwidget('Entry');
	my $val;
	if ($$var) {
		$val = 'tab',
	} else {
		$val = $e->get;
	}
	$self->Callback('-setcall', $val);
	$self->popDown;
}


##########################################################################
##                 Main Module                                          ##
##########################################################################

package Tk::CodeText::StatusBar;

=head1 NAME

Tk:CodeText::StatusBar - Status bar for  L<Tk::CodeText>

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.42';

use base qw(Tk::Derived Tk::Frame);

use Tk;
require Tk::PopList;

Construct Tk::Widget 'StatusBar';

my $save_pixmap = '
/* XPM */
static char *save[]={
"16 16 4 1",
". c None",
"# c #000000",
"a c #808080",
"b c #ffff00",
"................",
"..############..",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aaaaaaaaaaaa#.",
".#aa########aa#.",
".#aa########aa#.",
".#aa########aa#.",
".#aa########aa#.",
".#aa#bbbbbb#aa#.",
".#aa#bbbbbb#aa#.",
"..############..",
"................"};
';

=head1 SYNOPSIS

 require Tk::CodeText::StatusBar;
 my $text= $window->StatusBar(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::Frame>.

Provides a status bar to L<Tk::CodeText>.

=head1 OPTIONS

=over 4

=item Switch: B<-statusinterval>

By default 200 ms. Update interval for the status bar.

=item Switch: B<-saveimage>

The icon image used to indicate the text is modified.
By default it is an internally defined xpm.

=item Switch: B<-widget>

Mandatory!

Reference to the L<Tk::CodeText> widget it is serving.

=back

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $widget = delete $args->{'-widget'};
	die "Widget option not set" unless defined $widget;

	$self->SUPER::Populate($args);

	my $indent = '';
	my $info = '';
	my $syntax = 'None';
	my $tabs = '';
	$self->{CYCLEACTIVE} = 1;
	$self->{INDENT} = \$indent;
	$self->{INFO} = \$info;
	$self->{SYNTAX} = \$syntax;
	$self->{TABS} = \$tabs;

	my @pack = (-side => 'left', -padx => 2, -pady => 2);

	#modified indicator
	my $modlab = $self->Label(
	);
	$self->Advertise(Modified => $modlab);

	#info
	my $l = $self->Label(
		-textvariable => \$info, 
	)->pack(@pack);
	$self->Advertise(Info => $l);

	#Syntax
	my $sl;
	my $sb = $self->Button(
		-command => sub {
			$self->hideAll;
			$sl->popUp
		},
		-textvariable => \$syntax,
		-relief => 'flat'
	)->pack(-side => 'right');
	$sl = $self->PopList(
		-relief => 'raised',
		-borderwidth => 2,
		-popdirection => 'up',
		-confine => 1,
		-filter => 1,
		-selectcall => sub { $widget->configure(-syntax => shift) },
		'-values' => [ 'None', $widget->Kamelon->AvailableSyntaxes ],
		-widget => $sb,
	);
	$self->Advertise('Syntax', $sl);

	#Indent
	my $i;
	my $ib = $self->Button(
		-command => sub {
			$self->hideAll;
			$i->Put($widget->cget('-indentstyle'));
			$i->popUp;
		},
		-textvariable => \$indent,
		-relief => 'flat'
	)->pack(-side => 'right');
	$i = $self->PopIndent(
		-relief => 'raised',
		-borderwidth => 2,
		-confine => 1,
		-popdirection => 'up',
		-setcall => sub { $widget->configure(-indentstyle => shift) },
		-widget => $ib,
	);
	$self->Advertise('Indent', $i);

	#Tabs
	my $t;
	my $tb = $self->Button(
		-command => sub {
			$self->hideAll;
			$t->Put($widget->cget('-tabs'));
			$t->popUp;
		},
		-textvariable => \$tabs,
		-relief => 'flat'
	)->pack(-side => 'right');
	$t = $self->PopTabs(
		-relief => 'raised',
		-borderwidth => 2,
		-confine => 1,
		-popdirection => 'up',
		-setcall => sub { $widget->configure(-tabs => shift) },
		-widget => $tb,
	);
	my $tab = $widget->cget('-tabs');
	$tab = '' unless defined $tab;
	$t->Put($tab);
	$self->Advertise('Tabs', $t);

	$self->after(200, ['updateStatus', $self]);

	$self->ConfigSpecs(
		-statusinterval => ['PASSIVE', undef, undef, 200],
		-saveimage => [{-image => $modlab}, undef, undef, $self->Pixmap(-data => $save_pixmap) ],
		-widget => ['PASSIVE', undef, undef, $widget],
		DEFAULT => [ $self ],
	);
}

sub hideAll {
	my $self = shift;
	$self->Subwidget('Indent')->popDown;
	$self->Subwidget('Syntax')->popDown;
	$self->Subwidget('Tabs')->popDown;
}

sub Indent {
	my $self = shift;
	my $l = $self->{INDENT};
	$$l = shift if @_;
	return $$l
}

sub Info {
	my $self = shift;
	my $i = $self->{INFO};
	$$i = shift if @_;
}

sub Syntax {
	my $self = shift;
	my $l = $self->{SYNTAX};
	$$l = shift if @_;
	return $$l
}

sub Tabs {
	my $self = shift;
	my $l = $self->{TABS};
	$$l = shift if @_;
	return $$l
}

sub updateActive {
	return $_[0]->{CYCLEACTIVE}
}

sub updatePause {
	$_[0]->{CYCLEACTIVE} = 0;
}

sub updateResume {
	my $self = shift;
	$self->{CYCLEACTIVE} = 1;
	$self->updateStatus;
}

sub updateStatus {
	my $self = shift;
	return unless $self->updateActive;
	my $text = $self->cget('-widget');

	my $pos = $text->index('insert');
	$pos =~ /^(\d+)\.(\d+)/;
	my $line = $1;
	my $column = $2;
	my $lines = $text->linenumber('end - 1c');
	my $size = length($text->get('1.0', 'end - 1c'));
	my $ovr;
	if ($text->OverstrikeMode) {
		$ovr = 'OVERWRITE'
	} else {
		$ovr = 'INSERT'
	}
	$self->Info("Line $line of $lines, Column $column, Size $size.   $ovr");
	$self->Indent('Indent: ' . $text->cget('-indentstyle'));
	$self->Syntax('Syntax: ' . $text->syntax);
	my $tabs = $text->cget('-tabs');
	$tabs = '' unless defined $tabs;
	$self->Tabs("Tabs: $tabs");


	my $modlab = $self->Subwidget('Modified');
	if ($text->editModified) {
		$modlab->pack(
			-before => $self->Subwidget('Info'),
			-side => 'left',
			-padx => 2,
		);
	} else {
		$modlab->packForget
	}

	$self->after($self->cget('-statusinterval'), ['updateStatus', $self]);
}

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::CodeText>

=item L<Tk::CodeText::Theme>

=back

=cut

1;

__END__

