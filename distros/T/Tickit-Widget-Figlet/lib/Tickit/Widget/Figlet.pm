package Tickit::Widget::Figlet;
# ABSTRACT: render text using Text::FIGlet
use strict;
use warnings;

use parent qw(Tickit::Widget);

our $VERSION = '0.003';

=head1 NAME

Tickit::Widget::Figlet - trivial wrapper around L<Text::FIGlet> for banner rendering

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use Tickit;
 use Tickit::Widget::Figlet;
 
 Tickit->new(
 	root => Tickit::Widget::Figlet->new(
 		font => shift // 'block',
 		text => 'Tickit & FIGlet'
 	)
 )->run;

=head1 DESCRIPTION

Provides a minimal implementation for wrapping L<Text::FIGlet>. Essentially just creates
a L<Text::FIGlet> instance and calls C< figify > for rendering into a window.

=begin HTML

<p>Basic rendering:</p>
<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/tickit-widget-figlet-basic.png" alt="Simple FIGlet rendering with Tickit" width="508" height="78"></p>

=end HTML

=cut

use Text::FIGlet;
use Tickit::Utils qw(textwidth);
use List::UtilsBy qw(max_by);
use Tickit::Style;
use constant WIDGET_PEN_FROM_STYLE => 1;

BEGIN {
	style_definition base => ;
}

=head1 METHODS

=cut

=head2 new

Creates a new instance.

Named parameters:

=over 4

=item * text - the string to display

=item * font - which font to use

=item * path (optional) - path to load fonts from, will obey $ENV{FIGLIB} by default

=item * align (optional) - horizontal alignment to apply to text, can be a number from 0..1 or
the text 'left', 'right', 'centre' (or 'center')

=back

Returns the instance.

=cut

sub new {
	my ($class, %args) = @_;
	my $text = delete $args{text};
	my $font = delete $args{font};
	my $path = delete $args{path};
	my $align = delete $args{align};
	my $self = $class->SUPER::new(%args);
	$self->{figlet} = Text::FIGlet->new(
		-f => $font,
		(
			defined($path)
			? (-d => $path)
			: (),
		)
	);
	$align //= 0;
	$align = 0 if $align eq 'left';
	$align = 1 if $align eq 'right';
	$align = 0.5 if $align eq 'center';
	$align = 0.5 if $align eq 'centre';
	$self->{align} = $align;
	$self->{text} = $text;
	$self
}

=head2 render_to_rb

Handles rendering.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	$rb->clip($rect);
	$rb->clear;

	chomp(my @lines = $self->figlet->figify(
		-A => $self->text
	));
	{ # Strip any cruft from start/end so we can align properly
		my ($pre) = sort { $a <=> $b } map /^( *)/ ? length($1) : 0, @lines;
		if($pre) {
			substr $_, 0, $pre, '' for @lines
		}
		my ($post) = sort { $a <=> $b } map /( *)$/ ? length($1) : 0, @lines;
		if($post) {
			substr $_, -$post, $post, '' for @lines
		}
	}
	my ($max) = sort { $b <=> $a } map textwidth($_), @lines;
	my ($pre, $alloc, $post) = Tickit::Utils::align($max, $self->window->cols, $self->align);
	my $y = 0;
	$rb->text_at($y++, $pre, shift(@lines), $self->get_style_pen) while @lines;
}

sub align:method { shift->{align} }

=head2 text

Returns the current text to display. Pass a new string in to update the rendered text.

 $figlet->text('new text');
 is($figlet->text, 'new text');

=cut

sub text {
	my ($self) = shift;
	return $self->{text} unless @_;
	$self->{text} = shift;
	$self->window->expose if $self->window;
	$self
}

=head2 figlet

Returns the L<Text::FIGlet> instance. Probably a L<Text::FIGlet::Font> subclass.

=cut

sub figlet { shift->{figlet} }

sub lines { 1 }
sub cols { 1 }

1;

__END__

=head1 SEE ALSO

L<Text::FIGlet>, L<http://www.figlet.org/>, L<http://www.jave.de/figlet/fonts.html>

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2015. Licensed under the same terms as Perl itself.
