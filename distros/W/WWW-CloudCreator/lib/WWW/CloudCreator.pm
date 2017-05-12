# $Id: $ $Revision: $ $Source: $ $Date: $

package WWW::CloudCreator;

use strict;
use warnings;

use POSIX qw(ceil floor);

our $VERSION = '1.1';

sub new {
	my ($class, %args) = @_;
	my $self = bless{
		'counts'   => {},
		'smallest' => 8,
		'largest'  => 16,
		'cold'     => '000',
		'hot'      => 'E00',
		%args,
	}, $class;
	return $self;
}

sub add {
	my ( $self, $tag, $count ) = @_;
	if (! $tag || ! $count) { return 0; }
	$self->{counts}->{$tag} = $count;
	return 1;
}

sub gencloud {
	my ($self) = @_;
	my $smallest = $self->{'smallest'} || 8;
	my $largest = $self->{'largest'} || 16;
	my $cold = $self->{'cold'} || '000';
	my $hot = $self->{'hot'} || '000';
	my $counts = $self->{'counts'};
	my @tags = sort { $counts->{$b} <=> $counts->{$a} } keys %{$counts};
	my $ntags = scalar @tags;
	if ($ntags == 0) {
		return q{};
	} elsif ($ntags == 1) {
		my $tag = $tags[0];
		return [ $tag, 1, 'font-size:' . $smallest . q{;} ];
	}
	my $min = $counts->{$tags[-1]};
	my $max = $counts->{$tags[0]};
	my $spread = $max - $min;
	my ($fontspread, $fontstep);
	if ($largest != $smallest) {
		$fontspread = $largest - $smallest;
		if ($spread > 0) {
			$fontstep = $fontspread / $spread;
		} else {
			$fontstep = 0;
		}
	}
	my (@hotarray, @coldarray, @coldval, @hotval, @colorspread, @colorstep);
	if ($hot ne $cold) {
		@hotarray = map { hex $_ } (split //xm, $hot);
		@coldarray = map { hex $_ } (split //xm, $cold);
		for my $i (0 .. 2) {
			push @coldval, hexdec($coldarray[$i]);
			push @hotval, hexdec($hotarray[$i]);
			push @colorspread, ( hexdec($hotarray[$i]) - hexdec($coldarray[$i]) );
			if ($spread > 0) {
				push @colorstep, ( hexdec($hotarray[$i]) - hexdec($coldarray[$i]) ) / $spread;
			} else {
				push @colorstep, '0';
			}
		}
	}
	my (@out);
	foreach my $tag ( sort @tags ) {
		my $fraction = $counts->{$tag} - $min;
		my $fontsize = $smallest + ( $fontstep * $fraction);
		my (@style, $color);
		if ($hot ne $cold) {
			for my $i ( 0 .. 2 ) {
				my $ihex = $coldarray[$i] + ($colorstep[$i] * $fraction);
				my $decihex = dechex( $ihex );
				$color .= $decihex;
			}
		} else { $color = $cold; }
		push @style, 'color: #' . $color . q{;};
		if ($largest != $smallest) {
			push @style, 'font-size: ' . round($fontsize) . 'pt;';
		}
		push @out, [ $tag, $counts->{$tag}, join q{}, @style];
	}
	return @out;
}

sub round { return int $_[0] + .5 * ($_[0] <=> 0); }

sub dechex { return sprintf '%x', $_[0]; }

sub hexdec { return hex $_[0]; }

1;
__END__

=pod

=head1 NAME

WWW::CloudCreator - A weighted cloud creator

=head1 SYNOPSIS

  use WWW::CloudCreator;
  my $cloud = WWW::CloudCreator->new(
    smallest => 8,
    largest => 16,
    cold => '000',
    hot => '000',
  );
  $cloud->add('friends', 40);
  $cloud->add('famiy', 12);
  $cloud->add('tech', 103);
  my @weights = $cloud->gencloud;
  foreach my $item (@weights) {
    print 'tag: '.$item->[0].' - weight: '.$item->[1]."\n";
  } 

=head1 DESCRIPTION

This module will assist with creating complex weighted clouds. They are
usually refered to as tag or heat clouds.

Some could argue that this module does exactly what L<HTML::TagCloud> does but
I argue that on several points. This module will create a sorted and weighed
cloud but will also create a gradiant color pattern for the cloud as well.

Another difference is that this module will not return real html, but raw
data that you can then manipulate into html as you see fit.

=head1 EXPORT

This module does not export any functions.

=head1 SUBROUTINES/METHODS

=head2 new

This is the object creator. It does have a set of default arguments that can
be modified and adjusted.

=head3 Arguments

=over

=item smallest

This value represents the smallest possible font size of an item in the cloud.

=item largest

This value represents the largest possible font size of an item in the cloud.

=item cold

The cold argument represents a color value associated with items that have
a smaller weight.

=item hot

The hot argument represents a color value associated with items that have
a larger weight.

=back

=head2 add

This method adds a item and value to the cloud. The first argument must be a
real label and the second argument must be a score or count of some sort.

=head2 gencloud

The gencloud methods will prepare the final calculations for font sizes and
color gradiants to produce the final cloud.

It accepts no arguments.

It returns an array of arrays containing a label, weight and set of style
rules.

=head2 round

This is an internal function to assist with generating font sizes that don't
break.

=head2 dechex

This is an internal function to assist with dec to hex conversions.

=head2 hexdec

This is an internal function to assist with hex to dec conversions.

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 CAVEATS

The color gradiant code is buggy. I'm aware and looking into other ways of
doing it.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-cloudcreator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-CloudCreator>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc WWW::CloudCreator

You can also look for information at:

  http://blog.socklabs.com/CloudNine

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-CloudCreator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-CloudCreator>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-CloudCreator>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-CloudCreator>

=back

=head1 ACKNOWLEDGEMENTS

I would like to acknowledge the developers and contributors to
L<HTML::TagCloud> and L<HTML::TagCloud::Extended>. This module was heavily
inspired by both of those.

I would also like to mention that this module was also inspired by this piece
of code:

  http://www.engadgeted.net/projects/wordpress-heat-map-plugin/

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
