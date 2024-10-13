package Tk::AppWindow::Ext::StatusBar;

=head1 NAME

Tk::AppWindow::Ext::StatusBar - adding a status bar

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.15";
use Tk;
require Tk::Frame;
require Tk::Balloon;
require Tk::AppWindow::Ext::StatusBar::SImageItem;
require Tk::AppWindow::Ext::StatusBar::SMessageItem;
require Tk::AppWindow::Ext::StatusBar::SProgressItem;
require Tk::AppWindow::Ext::StatusBar::STextItem;

use base qw( Tk::AppWindow::BaseClasses::Extension );

my %types = (
	image => {
		class => 'SImageItem',
		pack => [],
	},
	message => {
		class => 'SMessageItem',
		pack => [-expand => 1, -fill => 'x'],
	},
	progress => {
		class => 'SProgressItem',
		pack => [],
	},
	text => {
		class => 'STextItem',
		pack => [],
	},
);

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['StatusBar'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Add a status bar to your application.

=head1 CONFIG VARIABLES

=over 4

=item B<-statusbarpanel>

Default value 'BOTTOM'. Sets the name of the panel home to B<StatusBar>.

=item B<-statusbarvisible>

Default value 1. Show or hide status bar.

=item B<-statusitemborderwidth>

Default value 2.

=item B<-statusitempadding>

Default value 2.

=item B<-statusitemrelief>

Default value 'groove'.

=item B<-statusmsgitemoninit>

Default value 1.

=item B<-statusupdatecycle>

Default value 500. Repeat time for updating the items on the status bar.

=back

=cut

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);

	$self->Require('Panels');

	my $args = $self->GetArgsRef;
	my $panel = delete $args->{'-statusbarpanel'};
	$panel = 'BOTTOM' unless defined $panel;
	my $pn = $self->extGet('Panels');
	$pn->panelAssign('status bar', $panel);

	$self->addPreConfig(
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#FF0000'],
		-warningcolor => ['PASSIVE', 'warningColor', 'WarningColor', '#0000FF'],
		-statusitemrelief => ['PASSIVE', undef, undef, 'groove'],
		-statusitemborderwidth => ['PASSIVE', undef, undef, 2],
		-statusitempadding => ['PASSIVE', undef, undef, 2],
		-statusupdatecycle =>['PASSIVE', undef, undef, 500],
		-statusmsgitemoninit =>['PASSIVE', undef, undef, 1],
	);

	$self->{BALLOON} = $self->Balloon;
	$self->{ITEMS} = {};

	
	$self->addPostConfig('InitMsgItem', $self);
	$self->addPostConfig('Cycle', $self);
	return $self;
}

=head1 METHODS

=over 4

=item B<Add>I<($type, $name, @options)>

Adds an item to the status bar.
$type can have the values I<image>, I<message>, I<progress>, I<text>

@options is a paired (switch => value) list.
General options are listed here. See type methods below for type specific options.

=over 4

=item B<-label>

Specify the text of the label.
If this option is set it will create a label next to the item on the statusbar.

=item B<-itempack>

Default value [-side=> 'left', -padx => 2, -pady => 2].

=item B<-position>

Specify the numerical position the item should be placed.

=item B<-updatecommand>

Specify a callback that returns the value for this item.

=back

=cut

sub Add {
	my $self = shift;
	my $type = shift;
	my $name = shift;
	unless (exists $types{$type}) {
		warn "undefined statusbar type: $type";
		return
	}
	my %params = (@_);
	my $pos = delete $params{'-position'};
	my $class = $types{$type}->{class};
	my $pack = $types{$type}->{pack};
	my $itempadding = $self->configGet('-statusitempadding');

	my $pn = $self->extGet('Panels');
	my $panel = $pn->panelAssign('status bar');
	if (defined $pos) {
		my @items = $self->Subwidget($panel)->children;
		my $b = $items[$pos];
		push @$pack, -before => $b if defined $b;
	}
	my $i = $self->Subwidget($panel)->$class(%params, 
		-relief => $self->configGet('-statusitemrelief'),
		-borderwidth => $self->configGet('-statusitemborderwidth'),
	)->pack(@$pack, -padx => $itempadding, -pady => $itempadding, -side => 'left');
	$self->{ITEMS}->{$name} = $i;
	return $i
}

=item B<AddImageItem>I<($name, @options)>

Almost the same as Add('image', $name, @options).
In the options B<-valueimages> you specify icon names.
Extension B<Art> must be loaded for this.
You can specify all the options for a Tk::Label and the following:

=over 4

=item B<-valueimages>

Specify a hash ref. Example;

    {
       0 => $w->Bitmap('error'),
       1 -> $w->Bitmap('transparent')
    }

=back

=cut

sub AddImageItem {
	my $self = shift;
	my $name = shift;
	my %options = (@_);
	my $imgo = delete $options{'-valueimages'};
	my %vi = ();
	if (defined $imgo) {
		for (keys %$imgo) {
			my $img = $imgo->{$_};
			$vi{$_} = $self->getArt($img);
		}
		$options{'-valueimages'} = \%vi;
	}
	return $self->Add('image', $name, %options);
}

=item B<AddMessageItem>I<($name, @options)>

Same as Add('message', $name, @options)
You can specify all the options for a Tk::Label.

=cut

sub AddMessageItem {
	my $self = shift;
	return $self->Add('message', @_);
}

=item B<AddProgressItem>I<($name, @options)>

Same as Add('progress', $name, @options)
You can specify all the options for a Tk::ProgressBar.

=cut

sub AddProgressItem {
	my $self = shift;
	return $self->Add('progress', @_);
}

=item B<AddTextItem>I<($name, @options)>

Same as Add('text', $name, @options)
You can specify all the options for a Tk::Label.

=cut

sub AddTextItem {
	my $self = shift;
	return $self->Add('text', @_);
}

sub Attach {
	my ($self, $widget, $text) = @_;
	$self->{BALLOON}->attach($widget, -statusmsg => $text)
}

sub Cycle {
	my $self = shift;
	my $time = $self->configGet('-statusupdatecycle');
	$self->after($time, ['Update', $self]) unless $time eq 0;
}

=item B<Delete>I<($name)>

Removes $name from the status bar and destroys the item object.

=cut

sub Delete {
	my ($self, $name) = @_;
	unless ($name eq 'msg') {
		if ($self->ItemExists($name)) {
			my $it = $self->Item($name);
			$it->Remove;
			$it->destroy;
			my $ih = $self->{ITEMS};
			delete $ih->{$name}
		}
	}
}

sub InitMsgItem {
	my $self = shift;

	#show the statusbar if it should be visible
	if ($self->configGet('-status barvisible')) {
		my $pn = $self->extGet('Panels');
		my $panel = $pn->panelAssign('status bar');
		$pn->panelShow($panel);
	}

	if ($self->configGet('-statusmsgitemoninit')) {
		unless (exists $self->{MI}) {
			my $mi = $self->AddMessageItem('msg', -position => 0);
			$self->{MI} = $mi;
			$self->{BALLOON}->configure(-statusbar => $mi);
			$self->configPut(-logcall => sub { $mi->Message(shift) });
			$self->configPut(-logerrorcall => sub { $mi->Message(shift, $self->configGet('-errorcolor')) });
			$self->configPut(-logwarningcall => sub { $mi->Message(shift, $self->configGet('-warningcolor')) });
			return $mi;
		}
	}
}

=item B<Item>I<($name)>

Returnes the item object for $name.

=cut

sub Item {
	my ($self, $name) = @_;
	return $self->{ITEMS}->{$name}
}

=item B<ItemExists>I<($name)>

Returnes true if $name exists.

=cut

sub ItemExists {
	my ($self, $name) = @_;
	return exists $self->{ITEMS}->{$name}
}

=item B<Message>I<($text)>

Display $text on the message item in the status bar if it exists.
The message will be deleted upon the first key stroke or mouse click.

=cut

sub Message {
	my $self = shift;
	my $msg = $self->{MI};
	$msg->Message(@_) if defined $msg;
}

sub Update {
	my $self = shift;
	my $items = $self->{ITEMS};
	for (keys %$items) {
		$self->Item($_)->Update 
	}
	$self->Cycle;
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::BaseClasses::PanelExtension>

=back

=cut

1;

