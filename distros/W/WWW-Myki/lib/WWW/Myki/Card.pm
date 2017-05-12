package WWW::Myki::Card;

use strict;
use warnings;

use HTML::TreeBuilder;
use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION	= '0.02';
our @MATTR	= qw(id _link holder money pass);
our @ATTR	= qw(id _link holder money pass type expiry status money_top_up
		     money_total active_pass inactive_pass last_transaction);

foreach my $attr ( @ATTR ) {
	{    
		no strict 'refs';
		*{ __PACKAGE__ .'::'. $attr } = sub { 
			my( $self, $val ) = @_;
			$self->{$attr} = $val if defined $val;
			return $self->{$attr} 
		}
	}   
}

sub new {
        my( $class, %args ) = @_; 
        my $self = {}; 
        bless $self, $class;
	$args{_mech} ? weaken( $self->{_mech} = $args{_mech} ) : croak "Mandatory attribute _mech not supplied";

        foreach my $attr ( @MATTR ) { 
                $args{$attr} ? $self->{$attr} = $args{$attr} : croak "Mandatory attribute $attr not present";
        }   

	$self->_get_card_details;
        return $self
}

sub refresh {
	my $self = shift;
	$self->_get_card_details
}

sub _get_card_details {
        my $self = shift;
	my $r = $self->{_mech}->get( $self->{_link} );
	my $t = HTML::TreeBuilder->new_from_content( $r->content );
	$t = $t->look_down( id => 'ctl00_uxContentPlaceHolder_uxCardDetailsPnl' );
	my @r = $t->look_down ( _tag => 'td' );
        $self->type		( $r[3]->as_text  );
	$self->expiry		( $r[5]->as_text  );
        $self->status		( $r[7]->as_text  );
        $self->money_top_up	( $r[11]->as_text );
        $self->money_total	( $r[13]->as_text );
        $self->active_pass	( $r[15]->as_text );
        $self->inactive_pass	( $r[17]->as_text );
        $self->last_transaction	( $r[19]->as_text );
}

sub transactions {
        my( $self, $refresh ) = shift;
	return @{ $self->{transactions} } if ( $self->{transactions} and not $refresh );
	undef $self->{transactions};
	$self->{_mech}->get( $self->{_link} );
	$self->{_mech}->follow_link( text => 'My transactions' );
	$self->{_mech}->form_name( 'aspnetForm' );
	$self->{_mech}->select( 'ctl00$uxContentPlaceHolder$uxCardList', $self->id );
	my $r = $self->{_mech}->click_button( name => 'ctl00$uxContentPlaceHolder$uxSelectNewCard' );
	my $t = HTML::TreeBuilder->new_from_content( $r->content );
	( $self->{total_transactions} ) 
		= ( $t->look_down( id => 'ctl00_uxContentPlaceHolder_uxTotalRecords' )->as_text =~ /of\s(\d*)\s/ );
	$t = $t->look_down( id => 'ctl00_uxContentPlaceHolder_uxMykiTxnHistory' );

	for ( $t->look_down( _tag => 'tr' ) ) { 
		my @cols = map { $_->as_text } $_->look_down( _tag => 'td' ) or next;
		return () if ( $cols[0] =~ /.*no record found.*/i );

		push @{ $self->{transactions} },  
			WWW::Myki::Transaction->new(
					date    => $cols[0],
					time    => $cols[1],
					type    => $cols[2],
					service => $cols[3],
					zone    => $cols[4],
					desc    => $cols[5],
					credit  => $cols[6],
					debit   => $cols[7],
					balance => $cols[8]
				)   
	}   

        return @{ $self->{transactions} }
}

=head1 NAME

WWW::Myki::Card - Class for operations with a Myki card

=head1 VERSION 0.01

=head1 SYNOPSIS

    # Print my Myki card money balance
    my $balance = $card->money;

    # What time did I stumble home last night?
    print $card->last_transaction;

    # Yeesh, really?  How?
    print $card->service;

    # Ooooohh, now I remember.
    
=head1 DESCRIPTION

L<WWW::Myki::Card> is a class providing account and card management and querying functionality
for registered Myki users.

Please note that you're are not meant to call the constructor yourself, instead a WWW::Myki::Card
object will be created automatically for you by calls to methods in a L<WWW::Myki> object like
B<cards>.

=head1 METHODS

=head2 id

Returns the card ID number.

=head2 holder

Returns the name of the registered card holder.

=head2 money

Returns the balance of Myki money on the card.

=head2 pass

Returns the balance of the active Myki pass (if any) on the card.

=head2 type

Returns the card type.

=head2 expiry

Returns the card expiry date in the format DD Mon YYYY, where Mon is the abbreviated month name.

=head2 status

Returns the card status.

=head2 money_top_up

Returns the value of any Myki money top up in progress - this is money that has been added by a top up, 
but may not yet have been credited to the card.

=head2 money_total

Returns the total of the balance of Myki money and the balance of Myki money top in progress on the card.

=head2 active_pass

Returns the balance of the current active Myki pass (if any) on the card.

=head2 inactive_pass

Returns the balance of the current inactive Myki pass (if any) on the card.

=head2 last_transaction

Returns the last transaction time and date for the card in the format; DD Mon YYYY HH:MM:SS AM/PM, 
where Mon is the abbreviated month name.

=head2 transactions

  foreach my $trip ( $card->transactions ) {
    printf( "%10s %8s %-10s %-20s\n", $trip->date, $trip->time, $trip->service, $trip->desc )
  }

  # Prints a formatted list of the last 15 transactions for this card - e.g.
  # 
  # 29/05/2012 17:28:38 Bus        Surburbia,Route SUB16out_new
  # 29/05/2012 08:08:12 Bus        Metro,Route MET16in_new

Returns an array of L<WWW::Myki::Transaction> objects representing the last 15 transactions for the card, or
an empty array if there are no recorded transactions.

See L<WWW::Myki::Transaction> for more information on transactions.  Transaction data is cached on the initial
invocation to increase the performance of subsequent calls and reduce unnecessary communication with the Myki
portal.  This is probably what you want, but if you really do want to force transaction data to be refreshed
then you can call the method with the argument B<refresh> set to a true value. e.g.

  $card->transactions( refresh => 1 );

Please note that this will incur a performance penalty.

=head2 refresh

When a WWW::Myki::Card object is created, the card data is cached to improve the performance of subsequent
method calls and reduce unessecary network communication.  This is probably what you want, however if you
do want to force the object to update its cached data for any reason, then you can call B<refresh>. Note 
that doing so will incur a performance penalty.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-myki-card at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myki-Card>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myki::Card

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Myki-Card>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Myki-Card>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Myki-Card>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Myki-Card/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<WWW::Myki>, L<WWW::Myki::Transaction>

=cut

1;
