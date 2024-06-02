package Tk::AppWindow::Ext::ToolBar;

=head1 NAME

Tk::AppWindow::Ext::ToolBar - add a tool bar

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.07";
use Tk;
require Tk::Compound;
require Tk::Poplevel;

my $down_arrow = '#define down_width 10
#define down_height 10
static unsigned char down_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0xff, 0x03, 0xfe, 0x01, 0xfc, 0x00, 0x78, 0x00,
   0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
';


use base qw( Tk::AppWindow::BaseClasses::PanelExtension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ToolBar'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Add a toolbar to your application.

=head1 CONFIG VARIABLES

=over 4

=item B<-autotool>

Default value 1.

Specifies if the toolbar items of all extensions should be loaded automatically.

=item B<-toolbarpanel>

Default value 'TOP'. Sets the name of the panel home to B<ToolBar>.

=item B<-toolbarvisible>

Default value 1. Show or hide tool bar.

=item B<-tooliconsize>

Default value 16

=item B<-toolitems>

Default value [].

Configure your tool bar here. Example:

 [    #type             #label    #command       #icon               #help
    [	'tool_button',   'New',     'doc_new',     'document-new',     'Create a new document' ],
 
    [	'tool_list' ],
    [	'tool_button',   'Save',    'doc_save',    'document-save',    'Save current document' ],
    [	'tool_button',   'Save as', 'doc_save_as', 'document-save-as', 'Rename and save current document' ],
    [	'tool_separator' ],
    [	'tool_button',   'Save all','doc_save_all','document-save-as', 'Save all modified documents' ],
    [	'tool_list_end' ],
 
    [	'tool_separator' ],
 
      #type             #label,   #class
    [	'tool_widget',    'Widget', 'MyWidget', @options ],
    [	'tool_widget',    '*Nolabel,'MyWidget', @options ],
 ]

'MyWidget', must be the class name of a packable Tk widget.

=item B<-tooltextposition>

Specifies where text should be displayed in tool buttons.
Default value I<right>. Can be I<top>, I<left>, I<bottom>, I<right> or I<none>.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require('Art');
	$self->configInit(
		-toolbarpanel => ['Panel', $self, 'TOP'],
		-toolbarvisible => ['PanelVisible', $self, 1],
	);

	$self->addPreConfig(
		-autotool => ['PASSIVE', undef, undef, 1],
		-tooliconsize => ['PASSIVE', 'ToolIconSize', 'toolIconSize', 16],
		-toolitems => ['PASSIVE', undef, undef, []],
		-tooltextposition => ['PASSIVE', undef, undef, 'right'],
	);
	$self->{BASE} = undef;
	$self->{MODE} = 0;
	$self->{POPLEVELS} = [];
	$self->{TYPESTABLE} = {};
	$self->{ITEMLIST} = [];
	$self->{WIDGETS} = {};
	$self->ConfigureTypes(
		tool_button			  => ['ConfButton', $self],
		tool_list			    => ['ConfList', $self],
		tool_list_end	  => ['ConfListEnd', $self],
		tool_separator		=> ['ConfSeparator', $self],
		tool_widget   		=> ['ConfWidget', $self],
	);

	$self->addPostConfig('DoPostConfig', $self);
	return $self;
}

=head1 METHODS

=over 4

=cut

sub _base {
	my $self = shift;
	$self->{BASE} = shift if @_;
	my $b = $self->{BASE};
	return $b if defined $b;
	return $self->Subwidget($self->Panel);
}

sub _mode {
	my $self = shift;
	$self->{MODE} = shift if @_;
	return $self->{MODE};
}

=item B<AddItem>I<$item, ?$position?);>

Adds an item to the toolbar. The item must be a valid tk widget.
Your addition will be lost after a call to B<ReConfigure>.

=cut

sub AddItem {
	my ($self, $item) = @_;
	my $mode = $self->_mode;
	$self->_mode(0);
	my $base = $self->_base;
	my @pack = ();
	if (ref $base eq 'Tk::Poplevel') {
		push @pack, -fill => 'x';
	} else {
		push @pack, -side => 'left', -fill => 'y';
	}
	push @pack, -padx => 2, -pady => 2 unless $mode;
	$item->pack(@pack);
	my $list = $self->{ITEMLIST};
	push @$list, $item;
	if ($mode) {
		my $p;
		$base->Button(
			-highlightthickness => 0,
			-relief => 'flat',
			-image => $self->Bitmap(
				-data => $down_arrow,
				-foreground => $self->configGet('-foreground'),
			),
			-command => sub { $p->popFlip },
		)->pack(-side => 'left', -fill => 'y');
		$p = $base->Poplevel(-widget => $base);
		my $pl = $self->{POPLEVELS};
		push @$pl, $p;
		$self->_base($p);
	}
}

sub ClearTools {
	my $self = shift;
	my $list = $self->{ITEMLIST};
	my @removed = @$list;
	while (@$list) {
		my $t = shift @$list;
		$t->packForget;
	}
	return @removed;
}

sub Configure {
	my $self = shift;
	my $uitypes = $self->{TYPESTABLE};
	while (@_) {
		my $i = shift;
		my @item = @$i;
		my $type = shift @item;
		if (defined $type) {
			if (my $p = $uitypes->{$type}) {
				$p->execute(@item);
			} else {
				warn "invalid type: $type"
			}
		} else {
			warn "undefined type"
		}
	}
}

=item B<ConfigureTypes>I<($type => $call, ...);

Call this method before MainLoop runs.
Configure additional types for your toolbar.
Already defined types are i<tool_button> and I<-tool_separator>.
I<$call> can be any valid Tk callback. Just make sure the callback
returns a valid Tk widget.

=cut

sub ConfigureTypes {
	my $self = shift;
	my $tab = $self->{TYPESTABLE};
	while (@_) {
		my $type = shift;
		my $call = shift;
		$tab->{$type} = $self->CreateCallback(@$call);
	}
}

sub ConfButton {
	my ($self, $label, $cmd, $icon, $help, $padding) = @_;
	my $tb = $self->_base;

	my $bmp;
	if (defined $icon) {
		$bmp = $self->getArt($icon, $self->configGet('-tooliconsize'));
	}

	my @balloon = ();
	push @balloon, -statusmsg => $help if defined $help;
	my $textpos = $self->configGet('-tooltextposition');
	my $but;
	my @bo = (-highlightthickness => 0, -relief => 'flat');

	if (defined $bmp) {
		my $art = $self->extGet('Art');
		my $compound = $art->createCompound(
			-text => $label,
			-image => $bmp,
			-textside => $textpos,
		);
		push @bo, -image => $compound;
	} else {
		push @bo,  -text => $label;
	}

	my $call;
	if ($cmd =~ /^<.+>/) { #matching an event
		$call = sub {
			$self->PopDown;
			$self->eventGenerate($cmd);
		}
	} else {
		$call = sub {
			$self->PopDown;
			$self->cmdExecute($cmd);
		}
	}
	push @bo, -command => $call;

	$but = $tb->Button(@bo);
	$self->BalloonAttach($but, $label) if $textpos eq 'none';
	if ($self->extExists('StatusBar')) {
		$self->StatusAttach($but, $help) if defined $help;
	} else {
		$self->BalloonAttach($but, $help) if defined $help;
	}
	$self->{WIDGETS}->{$label} = $but;
	$self->AddItem($but, $padding);
}

sub ConfList {
	my $self = shift;
	my $base = $self->_base;
	my $f = $base->Frame;
	$self->AddItem($f);
	$self->_base($f);
	$self->_mode(1);
}

sub ConfListEnd {
	my $self = shift;
	$self->_base(undef);
}

sub ConfSeparator {
	my $self = shift;
	my $tb = $self->_base;
	my $s;
	if (ref $tb eq 'Tk::Poplevel') {
		$s = $tb->Frame(-relief => 'sunken', -borderwidth => 1, -height => 2, @_)
	} else {
		$s = $tb->Frame(-relief => 'sunken', -borderwidth => 1, -width => 2, @_)
	}
	$self->AddItem($s);
}

sub ConfWidget {
	my ($self, $label, $class, @options) = @_;
	my $tb = $self->_base;
	my $f = $tb->Frame;
	unless ($label =~ s/^\*//) {
		my $l = "$label:";
		$f->Label(-text => $l)->pack(-side => 'left');
	}
	my $w = $f->$class(@options)->pack(-side => 'left');
	$self->{WIDGETS}->{$label} = $w;
	$self->AddItem($f);

}

sub CreateItems {
	my $self = shift;
	my @u = ();
	my @plugins = ();
	my $w = $self->GetAppWindow;
	if ($self->configGet('-autotool')) {
		my @p = $self->extList;
		my @l = ($w);
		for (@p) { push @l, $w->extGet($_) }
		for (@l) {
			#we want toolbar items from plugins loaded last
			push @u, $_->ToolItems if $_->Name ne 'Plugins';
			push @plugins, $_->ToolItems if $_->Name eq 'Plugins';
		}
	}
	my $m = $self->configGet('-toolitems');
	push @u, @$m, @plugins;
	$self->Configure(@u);
}

sub DeleteAll {
	my $self = shift;
	my @removed = $self->ClearTools;
	for (@removed) {
		$_->destroy if Exists($_);
	};
	$self->{POPLEVELS} = [];
	$self->{WIDGETS} = {};
}

sub DoPostConfig {
	my $self = shift;

	#fixing possible mismatch of iconsize at launch
	my $art = $self->extGet('Art');
	my $size = $self->configGet('-tooliconsize');
	$size = $art->getAlternateSize($size) if defined $art;
	$self->configPut(-tooliconsize => $size);

	$self->CreateItems;
}

sub GetItem {
	my ($self, $item) = @_;
	return $self->{WIDGETS}->{$item}
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label					Icon		config variable	   off  on
		[	'menu_check',		'View::',		"Show ~toolbar",	undef,	'-toolbarvisible', undef,	0,   1], 
	)
}

sub PopDown {
	my $self = shift;
	my $pl = $self->{POPLEVELS};
	for (@$pl) {	$_->popDown	}
}

sub ReConfigure {
	my $self = shift;
	$self->DeleteAll;
	$self->CreateItems;
}

=item B<RemoveItem>I<$position);>

Removes the item at $position from the tool bar.
The item will re-appear after a call to B<ReConfigure> if the item is included in the B<-toolitems> option.
Returns the removed item.

=cut

sub RemoveItem {
	my ($self, $position) = @_;
	my $list = $self->{ITEMLIST};
	if (defined $position) {
		$position = @$list if $position > @$list;
		my $item = $list->[$position];
		$item->packForget if defined $item;
		return $item;
	}
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



