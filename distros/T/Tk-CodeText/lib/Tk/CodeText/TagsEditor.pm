package Tk::CodeText::TagsEditor;

package MyColorEntry;

use strict;
use warnings;

use base qw(Tk::Derived Tk::ColorEntry);

Construct Tk::Widget 'MyColorEntry';

sub OnEscape {
	my $self = shift;
	$self->SUPER::OnEscape;
	$self->Callback('-command', $self->get);
}

sub OnKey {
	my $self = shift;
	$self->SUPER::OnKey;
	my $val = $self->Subwidget('Entry')->get;
	$self->Callback('-command', $val) if $self->validate($val);
	$self->Callback('-command', '') if $self->Subwidget('Entry')->get eq '';
}

sub popDown {
	my $self = shift;
	$self->SUPER::popDown;
	$self->Callback('-command', '') if $self->get eq '';
}

###########################################################################

package Tk::CodeText::TagsEditor;

=head1 NAME

Tk:CodeText::TagsEditor - Edit highlighting tags for L<Tk::CodeText>

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.47';

use base qw(Tk::Derived Tk::Frame);

require Tk::ColorEntry;
require Tk::HList;
require Tk::Balloon;
use Tk::CodeText::Theme;

Construct Tk::Widget 'TagsEditor';

=head1 SYNOPSIS

 require Tk::CodeText::TagsEditor;
 my $text= $window->TagsEditor(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::Frame>.

Provides an editor module for the color and font tags used for
syntax highlighting in L<Tk::CodeText>.

=head1 OPTIONS

=over 4

=item Switch: B<-balloon>

If you already have it available you can supply a reference to a
balloon widget. If you do not, it will create it's own balloon
widget.

Only available at create time.

=item Switch: B<-defaultbackground>

Mandatory!

Give it the background color of your text widget as value.

=item Switch: B<-defaultforeground>

Mandatory!

Give it the foreground color of your text widget as value.

=item Switch: B<-defaultfont>

Mandatory!

Give it the font object of your text widget as value.

=item Switch: B<-historyfile>

The name of the file where all the L<Tk::ColorEntry> widgets
store their recently used colors. If you do not specify this,
the history of the ColorEntry widgets will not propagate between
them.

Only available at create time.

=item Switch: B<-theme>

You can supply a reference to a L<Tk::CodeText::Theme> object. 
If you do not, it will create it's own.

Only available at create time.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $historyfile = delete $args->{'-historyfile'};

	my $balloon = delete $args->{'-balloon'};
	$balloon = $self->Balloon unless defined $balloon;

	my $theme = delete $args->{'-theme'};
	$theme = Tk::CodeText::Theme->new unless defined $theme;

	my $defaultbackground = delete $args->{'-defaultbackground'};
	die 'You must specify the -defaultbackground option' unless defined $defaultbackground;

	my $defaultforeground = delete $args->{'-defaultforeground'};
	die 'You must specify the -defaultforeground option' unless defined $defaultforeground;

	my $defaultfont = delete $args->{'-defaultfont'};
	die 'You must specify the -defaultfont option' unless defined $defaultfont;

	$self->SUPER::Populate($args);

	$self->{THEME} = $theme;

	my @columns = ('Tag', 'Foreground', 'Background', 'Bold', 'Italic');
	my $list;
	$list = $self->Scrolled('HList',
		-browsecmd => sub { $list->selectionClear; $list->anchorClear },
		-columns => 5,
		-header => 1,
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	my $count = 0;
	for (@columns) {
		my $header = $list->Label(-text => $_);
		$list->headerCreate($count, -itemtype => 'window', -widget => $header);
#		$list->headerCreate($count, -text => $_);
		$count ++;
	}

	for ($self->Theme->tagList) {
		my $tag = $_;

		$list->add($tag);
		my $label = $list->Label(
			-background => $defaultbackground,
			-font => $defaultfont,
			-anchor => 'e',
			-text => $tag,
		);
		$list->itemCreate($tag, 0, -itemtype => 'window', -widget => $label);

		my $fg = $list->MyColorEntry(
			-balloon => $balloon,
			-width => 8,
			-historyfile => $historyfile,
			-command => ['updateForeground', $self, $tag],
		);
		$list->itemCreate($tag, 1, -itemtype => 'window', -widget => $fg);

		my $bg = $list->MyColorEntry(
			-balloon => $balloon,
			-width => 8,
			-historyfile => $historyfile,
			-command => ['updateBackground', $self, $tag],
		);
		$list->itemCreate($tag, 2, -itemtype => 'window', -widget => $bg);

		my $b = '';
		Tie::Watch->new(
			-variable => \$b,
			-store => sub {
				my ($watch, $value) = @_;
				$watch->Store($value);
				$self->updateFont($tag, '-weight', $b);
			},
		);
		$self->Advertise($tag . "W", \$b);
		my $bold = $list->Checkbutton(
			-offvalue => '',
			-onvalue => 'bold',
			-variable => \$b,
		);
		$list->itemCreate($tag, 3, -itemtype => 'window', -widget => $bold);

		my $i = '';
		Tie::Watch->new(
			-variable => \$i,
			-store => sub {
				my ($watch, $value) = @_;
				$watch->Store($value);
				$self->updateFont($tag, '-slant', $i);
			},
		);
		$self->Advertise($tag . "S", \$i);
		my $italic = $list->Checkbutton(
			-offvalue => '',
			-onvalue => 'italic',
			-variable => \$i,
		);
		$list->itemCreate($tag, 4, -itemtype => 'window', -widget => $italic);
	}
	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-defaultbackground => ['PASSIVE', undef, undef, $defaultbackground],
		-defaultforeground => ['PASSIVE', undef, undef, $defaultforeground],
		-defaultfont => ['PASSIVE', undef, undef, $defaultfont],
		DEFAULT => [ $list ],
	);
	$self->Delegates(
		DEFAULT => $list
	);
}

sub fontCompose {
	my ($self, $font, %options) = @_;
	my $family = $self->fontActual($font, '-family');
	my $size = $self->fontActual($font, '-size');
	my $weight = '';
	my $slant = '';
	$slant = $options{'-slant'} if exists $options{'-slant'};
	$weight = $options{'-weight'} if exists $options{'-weight'};
	$slant = 'roman' if $slant eq '';
	$weight = 'normal' if $weight eq '';
	return $self->Font(
		-family => $family,
		-size => $size,
		-slant => $slant,
		-weight => $weight,
	);
}

=item b<get>

Returns a list of tag/options pairs.

=cut

sub get {
	my $self = shift;
	return $self->Theme->get;
}

=item b<load>

Loads a CodeText theme definition file.

=cut

sub load {
	my $self = shift;
	$self->Theme->load(@_);
	$self->updateAll;
}

=item b<put>

Assigns a @list of tag/option pairs.

=cut

sub put {
	my $self = shift;
	my $theme = $self->Theme;
	$theme->put(@_);
	for ($theme->tagList) {
		my $tag = $_;
		my $b = $self->itemCget($tag, 1, '-widget');
		$b->put($theme->getItem($tag, '-foreground'));
		my $f = $self->itemCget($tag, 2, '-widget');
		$f->put($theme->getItem($tag, '-background'));
		my $slant = $self->Subwidget($tag . 'S');
		$$slant = $theme->getItem($tag, '-slant');
		my $weight = $self->Subwidget($tag . 'W');
		$$weight = $theme->getItem($tag, '-weight');
	}
	$self->updateAll;
}

=item B<save>I<($file)>

Saves a CodeText theme definition file.

=cut

sub save {
	my $self = shift;
	$self->Theme->save(@_);
}

sub updateAll {
	my $self = shift;
	my $theme = $self->Theme;
	for ($theme->tagList) {
		my $tag = $_;
		my $bg = $theme->getItem($tag, '-background');
		$self->updateBackground($tag, $bg);
		my $fg = $theme->getItem($tag, '-foreground');
		$self->updateForeground($tag, $fg);
		my %font = (
			-slant => $theme->getItem($tag, '-slant'),
			-weight => $theme->getItem($tag, '-weight'),
		);
		$self->updateFont($tag, %font);
	}
}

sub updateBackground {
	my ($self, $tag, $color) = @_;
	my $bg = $color;
	$bg = $self->cget('-defaultbackground') if $color eq '';
	my $w = $self->itemCget($tag, 0, '-widget');
	$w->configure(-background => $bg);
	$self->Theme->setItem($tag, '-background', $color);
}

sub updateFont {
	my ($self, $tag, %values) = @_;

	my $font = $self->cget('-defaultfont');
	my $weight = $self->fontActual($font, '-weight');
	my $slant = $self->fontActual($font, '-slant');
	my %options = (
		-slant => $self->fontActual($font, '-slant'),
		-weight => $self->fontActual($font, '-weight'),
	);
	for (keys %values) {
		$options{$_} = $values{$_};
		$self->Theme->setItem($tag, $_, $values{$_});
	}
	$font = $self->fontCompose($font, %options);
	my $w = $self->itemCget($tag, 0, '-widget');
	$w->configure(-font => $font);
}

sub updateForeground {
	my ($self, $tag, $color) = @_;
	my $fg = $color;
	$fg = $self->cget('-defaultforeground') if $color eq '';
	my $w = $self->itemCget($tag, 0, '-widget');
	$w->configure(-foreground =>$fg);
	$self->Theme->setItem($tag, '-foreground',$color);
}

sub Theme {
	return $_[0]->{THEME};
}

=back

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



