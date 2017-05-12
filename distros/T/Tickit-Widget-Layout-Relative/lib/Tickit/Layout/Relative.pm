package Tickit::Layout::Relative;
$Tickit::Layout::Relative::VERSION = '0.005';
use strict;
use warnings;

=head1 NAME

Tickit::Layout::Relative - apply sizing to a group of L<Tickit> widgets

=head1 VERSION

version 0.005

=head1 SYNOPSIS

# EXAMPLE examples/synopsis.pl

=head1 DESCRIPTION

Provides the underlying implementation for widget layout used
internally by L<Tickit::Widget::Layout::Relative>.

=cut

use POSIX qw(floor);
use List::Util qw(max min);

=head1 METHODS

=cut

use constant ALIGNMENTS => qw(
	above below left_of right_of
	top_align bottom_align left_align right_align
);

sub new {
	my $class = shift;
	bless { width => 80, height => 80, @_ }, $class
}

sub add {
	my $self = shift;
	my %args = @_;
	foreach my $direction (ALIGNMENTS) {
		next if ref($args{$direction});
		$args{$direction} = defined($args{$direction}) ? [ split ' ', $args{$direction} ] : [ ];
	}
	$self->{pending}{$args{id}} = \%args;
	$self;
}

sub render {
	my $self = shift;
	$self->{ready} = [];

	my @items;
	my @pending = map $self->{pending}{$_}, sort keys %{$self->{pending}};
	my @order;
	my %found;
	while(@pending) {
		my $next = shift @pending;
		my @deps = $self->find_deps($next);
		if(grep !exists $found{$_}, @deps) {
			push @pending, $next;
		} else {
			$found{$next->{id}} = $next;
			push @order, $next;
		}
	}

#	warn "Have items in this order:";
#	warn $_->{id} for @order;
	my $rw = $self->{width};
	my $rh = $self->{height};
	foreach my $item (@order) {
#		warn "Processing " . $item->{id};
		$item->{border} ||= '1px round single';

		# Assign top-left corner based on what location information we have already
		my $x = max 0, map $found{$_}{x} + $found{$_}{w}, @{$item->{right_of}};
		my $y = max 0, map $found{$_}{y} + $found{$_}{h}, @{$item->{below}};

		$x += $self->find_margin_left($item);
		$y += $self->find_margin_top($item);
		my $w = $self->find_width($item) - $x;
		$w -= $self->find_margin_right($item);
		my $h = $self->find_height($item) - $y;
		$h -= $self->find_margin_bottom($item);

		# If we're on the other side of any widgets, we can use that to work out
		# where to limit width and height
		$w = min $w, map $found{$_}{x} - $x, @{$item->{left_of}} if $item->{left_of};
		$h = min $h, map $found{$_}{y} - $y, @{$item->{above}} if $item->{above};

		if(my @bottom = @{$item->{bottom_align}}) {
			$h = -$y + min map $found{$_}{y} + $found{$_}{h}, @bottom;
		}
		if(my @top = @{$item->{top_align}}) {
			my $add = -$y + max map $found{$_}{y} + $found{$_}{h}, @top;
			$y += $add;
			$h += $add;
		}
		if($item->{border} eq 'none' && @{$item->{right_of}}) {
			++$x
		}
		if($item->{border} eq 'none' && @{$item->{below}}) {
			++$y
		}
#		warn "At ($x, $y) size ($w, $h)";
		$item->{x} = $x;
		$item->{y} = $y;
		$item->{w} = $w;
		$item->{h} = $h;
		push @{$self->{ready}}, $item if $item->{w} >= 1 && $item->{h} >= 1;
	}
}

sub find_margin_left {
	my $self = shift;
	my $item = shift;
	$self->extract_measurement($item->{margin_left} || 0, $self->{width});
}

sub find_margin_top {
	my $self = shift;
	my $item = shift;
	$self->extract_measurement($item->{margin_top} || 0, $self->{height});
}

sub find_margin_right {
	my $self = shift;
	my $item = shift;
	$self->extract_measurement($item->{margin_right} || 0, $self->{width});
}

sub find_margin_bottom {
	my $self = shift;
	my $item = shift;
	$self->extract_measurement($item->{margin_bottom} || 0, $self->{height});
}

sub find_width {
	my $self = shift;
	my $item = shift;
	$self->extract_measurement($item->{width} || '100%', $self->{width});
}

sub find_height {
	my $self = shift;
	my $item = shift;
	$self->extract_measurement($item->{height} || '100%', $self->{height});
}

sub extract_measurement {
	my $self = shift;
	my $v = shift;
	my $max = shift;
	$v =~ s/\s+//g;
	if($v =~ /^(\d+(?:\.\d*)?)%$/) {
		$v = $1 * $max / 100;
	} elsif($v =~ /^(\d+)em$/) {
		$v = $1;
	}
	floor $v
}

sub find_deps {
	my $self = shift;
	my $item = shift;
	return map @$_, map $item->{$_} || [], ALIGNMENTS;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
