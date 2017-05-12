package Tickit::Widget::Decoration;
# ABSTRACT: basic decorative features
use strict;
use warnings;
use parent qw(Tickit::Widget);

our $VERSION = '0.004';

=head1 NAME

Tickit::Widget::Decoration - do nothing, in a visually-appealing way

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Decoration;
 Tickit->new(root => Tickit::Widget::Decoration->new)->run;

=head1 DESCRIPTION

Renders a pattern.

=begin HTML

<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/tickit-widget-decoration1.png" alt="Decoration widget example" width="272" height="21"></p>

=end HTML

=head1 STYLE

Future versions are likely to offer more customisation features,
for now you get the following:

=over 4

=item * start_fg - foreground colour to use as the starting point

=item * start_bg - background colour to use as the starting point

=item * end_fg - foreground colour to use as the ending point

=item * end_bg - background colour to use as the ending point

=item * gradient_direction - horizontal or vertical, determines which way
the gradient runs, default horizontal

=back

Only numeric values supported. Terms and conditions may apply.

=cut

use Tickit::Style;
use List::Util qw(max);

BEGIN {
	style_definition base =>
		start_fg           => 232,
		end_fg             => 255,
		start_bg           => 0,
		end_bg             => 0,
		gradient_direction => 'horizontal';
}

=head1 METHODS

No user-serviceable parts inside.

=cut

=head2 lines

Number of lines. Defaults to 1.

=cut

sub lines { 1 }

=head2 cols

Number of cols. Defaults to 1.

=cut

sub cols { 1 }

=head2 render_to_rb

Render to the given renderbuffer.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window;

	$rb->clear;
	my @pens;
	# Range is 'number of points'
	my $bg_range = abs($self->get_style_values('end_bg') - $self->get_style_values('start_bg'));
	my $fg_range = abs($self->get_style_values('end_fg') - $self->get_style_values('start_fg'));
	# We want the highest-resolution range to be used for interpolating pen values
	my $range = max $fg_range, $bg_range;

	my $fg_start = $self->get_style_values('start_fg');
	my $fg_end = $self->get_style_values('end_fg');
	my $bg_start = $self->get_style_values('start_bg');
	my $bg_end = $self->get_style_values('end_bg');
	for my $idx (0..$range) {
		my $fg = int(($fg_start * ($range - $idx) + $fg_end * $idx) / $range);
		my $bg = int(($bg_start * ($range - $idx) + $bg_end * $idx) / $range);
		push @pens, Tickit::Pen->new(
			fg => $fg,
			bg => $bg,
		);
	}
	my @chars = ("\x{2580}", "\x{2584}");
	my $w = $win->cols;
	my $h = $win->lines;
	my $pen;
	for my $y ($rect->linerange) {
		$pen = $pens[@pens * $y / $h] if $self->get_style_values('gradient_direction') eq 'vertical';
		my $char_idx = 0;
		for my $x ($rect->left..$rect->right) {
			$pen = $pens[@pens * $x / $w] if $self->get_style_values('gradient_direction') eq 'horizontal';
			$rb->text_at($y, $x, $chars[$char_idx % @chars], $pen);
			$char_idx++;
		}
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2013. Licensed under the same terms as Perl itself.
