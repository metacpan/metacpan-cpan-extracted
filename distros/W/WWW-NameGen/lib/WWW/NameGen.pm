# Revision $Revision$ ( $Date$ ) - $Source$

package WWW::NameGen;

use warnings;
use strict;

use LWP::UserAgent;

our $VERSION = '0.03';

my $max = 2_500;
my $chunk_size = 250;
my @chunks;

sub new {
	my ($class, %args) = @_;
	my $self = bless {%args}, $class;
	$self->{'ua'} = LWP::UserAgent->new;
	return $self;
}

sub get_chunks {
	my ($self, $count, @out) = @_;
	if ($count < $chunk_size) {
		push @out, $count;
	} else {
		my $chunks = $count / $chunk_size;
		my $remainder = $count % $chunk_size;
		map { push @out, $chunk_size } 1 .. $chunks;
		if ($remainder) { push @out, $remainder; }
	}
	return @out;
}

sub generate {
	my ($self, %args) = @_;

	my $min = $args{'min'} ? $args{'min'} : 10;
	my $obscurity = $args{'obscurity'} ? $args{'obscurity'} : 30;
	my $type = $args{'type'} ? $args{'type'} : 3;

	# return cached results if we can
	if (! $args{'nocache'} && $self->{'__cache'}) { return @{$self->{'__cache'}}; }

	my ($count, @names) = (0, qw//);
	my @chunks = $self->get_chunks($min);

	for my $tcount (@chunks) {
		if ($count >= $max) { last; }
		my $response = $self->{ua}->post(
			'http://www.kleimo.com/random/name.cfm',
			{
				'type' => $type,
				'number' => $tcount,
				'obscurity' => $obscurity,
				'Go' => 'Generate Random Name(s)',
			}
		);

		if (! $response->is_success) {
			die "Error getting data!\n";
		}

		my $html = $response->content;
		while ($html =~ m!target="_blank">([^<]*)</a><br>!gixm ) {
			push @names, $1;
		}
		$count += $tcount;
	}

	$self->{'__cache'} = \@names;

	return @names;
}

1;
__END__

=pod

=head1 NAME

WWW::NameGen - A website polling random name generator

=head1 SYNOPSIS

This module polls an online name generator for x many random names, caches
internally and returns the results.

  use WWW::NameGen;
  my $namegen = WWW::NameGen->new();
  my @names = $namegen->generate(min => 30);
  @morenames = $namegen->generate(min => 350);
  @evenmorenames = $namegen->generate(min => 350); # returns cached results as above

=head1 WHY

You are probably thinking to yourself right now something like this:

  Why did he decided to get the list from a website instead of doing internal
  an internal sort of thing?

There are a few reasons: 

=over

=item I'm lazy

I'm lazy and it was a quick hack for something more important than a random
name generator.

=item name lists are big

I could of included the US Census data and done an internal sort and what-not
but the data is over a meg and I don't want to deal with it.

=item someone else already did it

There are already a half dozen (more maybe?) modules that do all sorts of
random word stuff from dictionaries and lists. This website has also already
created a clean and simple random name generator. There is no point in me
rewriting stuff that has already been done. See point "I'm lazy" for more
information.

=back

=head1 SUBROUTINES/METHODS

=head2 new

Creates and returns a new WWW::NameGen object.

=head2 generate

Performs the post request to get a random name list.

This can take several arguments.

=over

=item min

The 'min' value is the minimum count of random names to fetch.

=item obscurity

The 'obscurity' value is the obscurity of the names to fetch.

=item type

The 'type' argument is either 1, 2 or 3. One for only males, Two for only
females, or Three for both males and females.

=item nocache

When the 'nocache' arg is set is will tell the generate function to ignore the
cache and create a new set of names.

=back

=head2 get_chunks

Takes a count breaks it into chunks of x.

=head1 AUTHOR

Nick Gerakines, C<< <nick at socklabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-namegen at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-NameGen>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::NameGen

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-NameGen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-NameGen>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-NameGen>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-NameGen>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to whoever runs and owns http://www.kleimo.com/random/name.cfm for
providing the service that this module calls.

And please, don't waste his bandwidth or be generally rude. Respect the site
so that it will stay up.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
