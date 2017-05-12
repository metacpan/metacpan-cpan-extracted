#!/usr/bin/perl

package WWW::Myki::Transaction;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(credit zone time date service debit balance desc type);

sub new {
	my ($class, %args) = @_;
	my $self = {};
	bless $self, $class;

	foreach my $attr ( @ATTR ) {
		$args{$attr} ? $self->{$attr} = $args{$attr} : croak "Mandatory attribute $attr not present";
	}
	
	return $self
}

foreach my $attr (@ATTR) {
	{	
		no strict 'refs';
		*{ __PACKAGE__ .'::'. $attr } = sub { return $_[0]->{$attr} }
	}
}

=head1 NAME

WWW::Myki::Transaction - Class for operations with a Myki transaction

=head1 VERSION 0.01

=head1 SYNOPSIS

  # Print the date, time, service, description and cost of our last 15 transactions

  foreach my $trip ( $card->transactions ) { 
    printf( "%10s %8s %-10s %-20s %-5s\n", 
            $trip->date,
            $trip->time, 
            $trip->service,
            $trip->desc,
            $trip->debit )
  }

  # Maybe do a rough calculation of the cost of public transport per day

  use List::Util qw( sum );
  my %sum;

  foreach my $t ( $card->transactions ) {
    ( my $cost = $t->debit ) =~ s/(-|\$|\s)//g;
    $sum{ $t->date } += $cost;
  }

  print "Average daily cost of travel on public transport: "
    . ( ( sum values %sum ) / ( keys %sum ) ) . "\n";

  # Still cheaper than the environmental cost of driving to work
    
=head1 DESCRIPTION

L<WWW::Myki::Transaction> is a class providing Myki transaction querying functionality for registered Myki users.
Each WWW::Myki::Transaction object is representative of a single Myki card transaction.

Please note that you're are not meant to call the constructor yourself, instead a WWW::Myki::Transaction
object will be created automatically for you by calls to methods in a L<WWW::Myki::Card> object like
B<transactions>.

=head1 METHODS

=head2 date

Return the date of the transaction using the format DD/MM/YYYY.

=head2 time

Print the time of the last transaction using the format HH:MM:SS AM/PM.

=head2 service

The type of service for the last transaction (e.g. busi or train)

=head2 zone

The transit zone for the last transaction.

=head2 desc

A description of the transaction usually including the start and destination localities and a service name.
This may be a hyphen (-) where no information is provided.

=head2 debit

The amount debited for the transaction using in decimal currency format (i.e. $D.DD) where present, or a hyphen
where no debit was made.

=head2 credit

The amount credited for the transaction using in decimal currency format (i.e. $D.DD) where present, or a hyphen
where no credit was made.

=head2 balance

The balance of the associated Myki card at the time this transaction was completed in decimal curreny format.

=head2 type

The type of transaction made (e.g. Touch-on or Touch-off).

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-myki-transaction at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myki-Transaction>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myki::Transaction

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Myki-Transaction>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Myki-Transaction>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Myki-Transaction>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Myki-Transaction/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<WWW::Myki>, L<WWW::Myki::Card>

=cut


1;
