package WWW::Myki;

use warnings;
use strict;

use WWW::Myki::Transaction;
use WWW::Myki::Card;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Carp qw(croak);

our $VERSION = '0.04';

sub new {
	my( $class, %args ) = @_;
	my $self	= {};
	bless $self, $class;
	$args{username}	? $self->{username} = $args{username} : croak 'Constructor failed: must specify username';
	$args{password}	? $self->{password} = $args{password} : croak 'Constructor failed: must specify password';
	$self->{_mech}	= WWW::Mechanize->new( ssl_opts => { verify_hostname => 0 } );
	$self->{_url}	= {
			base	=> 'https://www.mymyki.com.au/NTSWebPortal/',
			account	=> 'Registered/MyMykiAccount.aspx?menu=My+myki+account',
			login	=> 'Login.aspx'
			};
	$self->_login;
	return $self
}

sub _login {
	my $self = shift;
	$self->{_mech}->get( $self->{_url}->{base} . $self->{_url}->{login} );
	$self->{_mech}->form_name( 'aspnetForm' );
	$self->{_mech}->field( 'ctl00$uxContentPlaceHolder$uxUsername', $self->{username} );
	$self->{_mech}->field( 'ctl00$uxContentPlaceHolder$uxPassword', $self->{password} );
	$self->{_mech}->click( 'ctl00$uxContentPlaceHolder$uxLogin' );
	my %form = (
			'__EVENTTARGET'		=> 'ctl00$uxContentPlaceHolder$uxTimer',
			'__EVENTVALIDATION'	=> $self->{_mech}->value('__EVENTVALIDATION'),
			'__VIEWSTATE'		=> $self->{_mech}->value('__VIEWSTATE'),
			'ctl00$ScriptManager1'	=> 'ctl00$uxContentPlaceHolder$Panel|ctl00$uxContentPlaceHolder$uxTimer'
		);
	my $r 	= $self->{_mech}->post( $self->{_url}->{base} . $self->{_url}->{account}, \%form );
	my $t 	= HTML::TreeBuilder->new_from_content( $r->content );
	$t	= $t->look_down( id => 'ctl00_uxContentPlaceHolder_uxMyCards' );
	my @cards = $t->look_down( _tag => 'td' );
	@cards or croak 'Unable to retrieve card information';
	
	for( my $i=0; $i<@cards; $i+=4 ) {
		$self->{_cards}->{$cards[$i]->as_text} = 
			WWW::Myki::Card->new(
				id	=> $cards[$i]->as_text,
				_mech	=> $self->{_mech},
				_link	=> $self->{_url}->{base} . 'Registered/' . $cards[$i]->look_down( _tag => 'a' )->attr( 'href' ),
				holder	=> $cards[$i+1]->as_text,
				money	=> $cards[$i+2]->as_text,
				pass	=> $cards[$i+2]->as_text
			)
	}
}

sub cards { 
	return values %{$_[0]->{_cards}} 
}

=head1 NAME

WWW::Myki - A simple Perl interface to Myki online account management portal

=head1 VERSION 0.01

=head1 SYNOPSIS

    use WWW::Myki;

    my $myki = WWW::Myki->new(
                                username => 'myusername',
                                password => 'mypassw0rd'
                             );

    # Print card number, card holder, Myki money and Myki pass balances
   
    foreach $card ( $myki->cards ) {
      print "Card number: ". $card->id ." - Holder: ". $card->holder "\n";
      print "Myki money balance : ". $card->money ." - Myki pass balance: ". $card->pass ."\n";
    }

    # Print the date, time, service, description and cost of our last 15 transactions

    foreach my $trip ( $card->transactions ) { 
      printf( "%10s %8s %-10s %-20s %-5s\n", 
              $trip->date, 
              $trip->time, 
              $trip->service, 
              $trip->desc, 
              $trip->debit )
    }
      
=head1 DESCRIPTION

L<WWW::Myki> provides a simple interface to the Myki online account management portal functionality
for registered Myki users.

=head1 METHODS

=head2 new ( %args )

Constructor.  Creates a new WWW::Myki object and  attempts a login using the provided credentials.
On successful login, returns a WWW::Myki object.

The constructor accepts an anonymous hash of two mandatory parameters:

=over

=item *

username

Your registered Myki account username.

=item *

password

Your registered Myki account password.

=back

=cut

=head2 cards

  my @cards = $myki->cards;

Returns an array of L<WWW::Myki::Card> objects.  Each object is representative of a Myki card
registered to the specified account.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-myki at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myki>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myki

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Myki>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Myki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Myki>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Myki/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<WWW::Myki::Card>, L<WWW::Myki::Transaction>

=cut

1;
