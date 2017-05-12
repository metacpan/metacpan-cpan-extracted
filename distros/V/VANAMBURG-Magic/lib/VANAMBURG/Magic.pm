package VANAMBURG::Magic;

use warnings;
use strict;

=head1 NAME

VANAMBURG::Magic - A resource for the discriminating card magician.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This package is meant for use by magicians.  Specifically, it intends to make working with rosary stacks and memorized decks easier to learn.  
Scripts, such as those included, make it easier to drill memory of stacks.  It is easier to practice tricks that use complicated stacks, 
or mathematical principles, in a virtual environment.  By writing simple scripts, such as thouse include in this distribution, 
a lot of time can be saved during the initial period of learning. Restacking a complex stack with real cards is very time consuming.

The modules contained in this package are object oriented and very easy to include in simple scripts or web applications.If you are not familiar with Perl 
programming but would like to write simple scripts, I recommend a good starting point is "Learn Perl in about 2 hours 30 minutes"
By Sam Hughes at his site: http://qntm.org/files/perl/perl.html

=head2 CREATE DECKS, PACKETS OR STACKS

=head3 Built in Stacks
		
	# Create stack in Aronson order
	my $aronson_dec = VANAMBURG::PacketFactory->create_stack_aronson;

	$my $joyal_chased_deck = VANAMBURG::PacketFactory->create_stack_joyal_chased;
	
	my $joyal_shocked_deck = VANAMBURG::PacketFactory->create_stack_joyal_shocked;
	
	my $tamariz_deck = VANAMBURG::PacketFactory->create_stack_mnemonical;
	
	my $bcs = VANAMBURG::PacketFactory->create_stack_breakthrough_card_system;
	
	my $si_stebbins = VANAMBURG::PacketFactory->create_si_stebbins_chased_3step; 

	my $si_stebbins_4 = VANAMBURG::PacketFactory->create_si_stebbins_chased_4step; 
	
	my $si_stebbins_shocked = VANAMBURG::PacketFactory->create_si_stebbins_shocked_3step;
	
	my $si_stebbins_shocked_4 = VANAMBURG::PacketFactory->create_si_stebbins_shocked_4step;


=head3 Create arbitrary stacks or packets

	# Create any arbitrary packet, or deck of cards.
	my $forcing_deck = VANAMBURG::PacketFactory->create_packet("5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D,5D");
	
	# Create a stack, where each card has, and retains, a stack number, even when shuffled.
	my $stack = VANAMBURG::PacketFactory->create_stack("AD,2D,3D,4D,5D,6D,7D,8D,9D,10D,JD,QD,KD");
	
	
=head2 DO STUFF WITH PACKETS
	
See docuentation for L<VANAMBURG::Packet> for all the operations available for the stacks shown above.
	
=head1 A FEW OF THE IMPORTANT MODULES INCLUDED 

=over

=item L<VANAMBURG::Packet>

=item L<VANAMBURG::PacketFactory>

=item L<VANAMBURG::Card>

=item L<VANAMBURG::StackCard>

=item L<VANAMBURG::Suit>

=item L<VANAMBURG::FaceValue>

=back

and more ...


=head1 INCLUDED SCRIPTS

Three training scripts are installed on your system when this module is installed.

=head2 memdeckrandom

The memdeckrandom script helps train in memory work by offering 10 random cards.  The user can choose
from 9 stacks and can be trained by either entering the stack number for a card, or entering the
card for a given stack number.

Example session 1:

	$ memdeckrandom 
	
	Deck Menu
	======================
	Enter 1 for Breakthrough Card System
	Enter 2 for Aronson Stack
	Enter 3 for Tamariz Mnemonica
	Enter 4 for Joyal SHoCked
	Enter 5 for Joyal CHaSeD
	Enter 6 for Si Stebbins CHaSed  (step = 3)
	Enter 7 for Si Stebbins CHaSed  (step = 4)
	Enter 8 for Si Stebbins SHoCkeD (step = 3)
	Enter 9 for Si Stebbins SHoCkeD (step = 4)
	
	
	Enter choice: 1                                                                                                                                              
	
	 Menu
	======================
	Enter 1 for Card to Number 
	Enter 2 for Number to Card
	Enter q to quit
	
	Enter choice: 1                                                                                                                                              
	
	When presented with a card, enter the stack number and press enter.
	
	10 random cards will be presented.
	
	
	Eight of Diamonds: 19                                                                                                                                        
	Correct
	Two of Clubs: 46                                                                                                                                             
	Correct
	Two of Hearts: 15                                                                                                                                            
	Correct
	Two of Diamonds: 11                                                                                                                                          
	Correct
	Queen of Clubs: 5                                                                                                                                            
	Correct
	Seven of Diamonds: 4                                                                                                                                         
	Wrong - stack number = 3
	Four of Spades: 21                                                                                                                                           
	Correct
	Ten of Diamonds: 41                                                                                                                                          
	Correct
	Seven of Hearts: 47                                                                                                                                          
	Correct
	Nine of Hearts: 34                                                                                                                                           
	Correct
	
	bye


Example session 2:

	$ memdeckrandom 
	
	Deck Menu
	======================
	Enter 1 for Breakthrough Card System
	Enter 2 for Aronson Stack
	Enter 3 for Tamariz Mnemonica
	Enter 4 for Joyal SHoCked
	Enter 5 for Joyal CHaSeD
	Enter 6 for Si Stebbins CHaSed  (step = 3)
	Enter 7 for Si Stebbins CHaSed  (step = 4)
	Enter 8 for Si Stebbins SHoCkeD (step = 3)
	Enter 9 for Si Stebbins SHoCkeD (step = 4)
	
	
	Enter choice: 1                                                                                                                                              
	
	 Menu
	======================
	Enter 1 for Card to Number 
	Enter 2 for Number to Card
	Enter q to quit
	
	Enter choice: 2                                                                                                                                              
	Enter the abbreviation for the card (AS,JD, 2H, etc)
	when prompted with a stack number.  
	
	10 random stack numbers will be used.
	
	Card at 1: as                                                                                                                                                
	Correct
	Card at 42: js                                                                                                                                               
	Correct
	Card at 27: 6h                                                                                                                                               
	Correct
	Card at 34: 9h                                                                                                                                               
	Correct
	Card at 26: ad                                                                                                                                               
	Correct
	Card at 28: ah                                                                                                                                               
	Correct
	Card at 43: 10h                                                                                                                                              
	Correct
	Card at 44: 9s                                                                                                                                               
	Correct
	Card at 49: 8s                                                                                                                                               
	Correct
	Card at 14: kh                                                                                                                                               
	Correct
	
	bye
	


Immediately below I show the source code for this script. If you have computer programming experience, you will easily be able to use it as a guide
to creating your own scripts.  Teaching Perl is beyond my scope, but if you are interested in learning and need help getting a new script working, please contact
me at the email address you will find on this page.

=head2 memdecksequence

The memdecksequence script is useful in training for either proficiency in using common rosary stacks, or 
in working sequentially through a mem deck.

Example session1:

	$ memdecksequence 
	
	Rosary Trainer Menu
	======================
	Enter 1 for Breakthrough Card System
	Enter 2 for Si Stebbins CHaSed  (step = 3)
	Enter 3 for Si Stebbins CHaSed  (step = 4)
	Enter 4 for Si Stebbins SHoCkeD (step = 3)
	Enter 5 for Si Stebbins SHoCkeD (step = 4)
	
	Enter q to quit
	
	Enter choice: 5
	Direction Menu
	======================
	Enter 1 for Top to Bottom 
	Enter 2 for Bottom to Top
	
	Enter choice: 1
	What comes after AS? 5H
	Correct
	What comes after 5H? 9C
	Correct
	What comes after 9C? KD
	Correct
	What comes after KD? 4S
	Correct
	What comes after 4S? 8H
	Correct
	What comes after 8H? 

Example session2:

	$ memdecksequence 
	
	Rosary Trainer Menu
	======================
	Enter 1 for Breakthrough Card System
	Enter 2 for Si Stebbins CHaSed  (step = 3)
	Enter 3 for Si Stebbins CHaSed  (step = 4)
	Enter 4 for Si Stebbins SHoCkeD (step = 3)
	Enter 5 for Si Stebbins SHoCkeD (step = 4)
	
	Enter q to quit
	
	Enter choice: 2
	
	Direction Menu
	======================
	Enter 1 for Top to Bottom 
	Enter 2 for Bottom to Top
	
	Enter choice: 2
	What comes before JD? 8S
	Correct
	What comes before 8S? 5H
	Correct
	What comes before 5H? 2C
	Correct
	What comes before 2C? KD
	Wrong - correct answer is QD
	What comes before QD? 

=head2 PRACTICING TRICKS WITH SCRIPTS 

Mem deck magic can be very difficult, especially when math with cards is involved.  Also resetting the deck
can be time consuming.  Using scripts can accelerate improving capability with these skills.

=head3 Simon Aronson's "Everybody's Lazy"

Get a copy of "Simply Simon" by Simon Aronson, study "Everybody's Lazy" and this will make sense.  For now,
let it suffice as an example of how you can make practicing math with cards a lot easier and save
time resetting.

Example sessions:

	gordon@gordon-LX6810-01$ eblazytrainer 
	
	
	Card C: Ten of Hearts
	
	
	Enter location for card a: 10
	
	
	Card A: Eight of Clubs
	
	
	Enter location for card b: 12
	
	
	Card B: Six of Hearts
	
	
	Enter low for range: 15
	Enter High for range: 31
	What is card for spectator guess of 27: 4h
	
	
	Nice job! How did you do that?!


  

=head1 SOURCE CODE EXAMPLES

While the source is included with this module, it might be helpful to see some example code here.

=head2 rosarytrainer source

	#!/usr/bin/perl 
	use v5.10;
	use strict;
	use warnings;
	use FindBin;
	use Term::ReadLine;
	use English;
	use lib "$FindBin::Bin/../lib";
	use VANAMBURG::BCS;
	use VANAMBURG::SiStebbins;
	
	my $menu = <<END;
	
	Rosary Trainer Menu
	======================
	Enter 1 for Breakthrough Card System
	Enter 2 for Si Stebbins CHaSed  (step = 3)
	Enter 3 for Si Stebbins CHaSed  (step = 4)
	Enter 4 for Si Stebbins SHoCkeD (step = 3)
	Enter 5 for Si Stebbins SHoCkeD (step = 4)
	
	Enter q to quit
	END
	say $menu;
	my $term = Term::ReadLine->new("BCS Test");
	my $test = $term->readline("Enter choice: ");
	exit if ( $test =~ /q/i );
	exit if !( $test ~~ [ 1, 2, 3, 4, 5 ] );
	
	my $deck;
	given ($test) {
		when (/1/) { $deck = VANAMBURG::BCS->new; }
		when (/2/) { $deck = VANAMBURG::SiStebbins->new; }
		when (/3/) { $deck = VANAMBURG::SiStebbins->new( step => 4 ); }
		when (/4/) {
			$deck = VANAMBURG::SiStebbins->new( suit_order => 'SHoCkeD' );
		}
		when (/5/) {
			$deck =
			  VANAMBURG::SiStebbins->new( suit_order => 'SHoCkeD', step => 4 );
		}
		default { say "unknown option $test. quitting"; exit; }
	}
	
	my $sub_menu = <<END;
	
	Direction Menu
	======================
	Enter 1 for Top to Bottom 
	Enter 2 for Bottom to Top
	END
	say $sub_menu;
	my $direction = $term->readline("Enter choice: ");
	if ( !( $direction ~~ [ 1, 2 ] ) ) {
		say "invalid option";
		exit;
	}
	
	my @locations = ( 1 .. 52 );
	@locations = reverse @locations if ( $direction == 2 );
	my $first_location = shift @locations;
	
	my $current_card   = $deck->card_at_location($first_location);
	my $before_after = $direction == 2? 'before':'after';
	for my $location (@locations) {
		my $next_card = $deck->card_at_location($location);
		my $answer    = uc $term->readline(
			"What comes $before_after " . $current_card->abbreviation . '? ' );
		if ( $answer eq $next_card->abbreviation ) {
			say "Correct";
		}
		else {
			say "Wrong - correct answer is " . $next_card->abbreviation;
		}
		$current_card = $next_card;
	}



=head2 eblazytrainer

	#!/usr/bin/perl
	use v5.10;
	use strict;
	use warnings;
	use Term::ReadLine;
	use FindBin;
	use lib "$FindBin::Bin/../lib";
	use VANAMBURG::BCS;
	use VANAMBURG::RandomNumbers;
	
	my $bcs  = VANAMBURG::BCS->new;
	my $term = Term::ReadLine->new("Everybody's Lazy");
	
	my $location_a = VANAMBURG::RandomNumbers->number_between( 10, 17 );
	my $carda = $bcs->cut_take_bury($location_a);
	
	my $location_b = VANAMBURG::RandomNumbers->number_between( 10, 17 );
	my $cardb = $bcs->cut_take_bury($location_b);
	
	my $location_c = VANAMBURG::RandomNumbers->number_between( 13, 18 );
	my $cardc = $bcs->cut_take_bury($location_c);
	
	say( "\nCard C: " . $cardc->display_name . "\n" );
	
	#
	# -------- CARD A
	#
	
	my $resp       = -1;
	my $card_a_loc = 53 - $cardc->stack_number;
	while ( $resp != $card_a_loc ) {
	    $resp = $term->readline("Enter location for card a: ");
	    say $card_a_loc if ($resp eq 'help');
	}
	say "\nCard A: " . $carda->display_name . "\n";
	$bcs->cut_and_take($card_a_loc);
	
	#
	# --------  CARD B
	#
	
	$resp = -1;
	while ( $resp != $carda->stack_number ) {
	    $resp = $term->readline("Enter location for card b: ");
	    say $carda->stack_number if ($resp eq 'help');
	}
	say "\nCard B: " . $cardb->display_name . "\n";
	$bcs->cut_and_take( $carda->stack_number );
	 
	#
	# -------- LOW RANGE
	#
	
	$resp = -1;
	my $low_range = $cardb->stack_number - $carda->stack_number;
	while ( $resp != $low_range ) {
	    $resp = $term->readline("Enter low for range: ");
	    say $low_range if ($resp eq 'help');
	}
	
	#
	# -------- HIGH RANGE
	#
	
	$resp = -1;
	my $high_range = $cardc->stack_number - $carda->stack_number;
	while ( $resp != $high_range ) {
	    $resp = $term->readline("Enter High for range: ");
	    say $high_range if ($resp eq 'help');
	}
	
	
	#
	# -------- MAGICIAN CARD
	#
	
	$resp = -1;
	my $spectator_guess = generate_card_between( $low_range, $high_range );
	my $magician_card = $bcs->card_at_location($spectator_guess);
	while ( uc $resp ne uc $magician_card->abbreviation ) {
	    $resp =
	      $term->readline("What is card for spectator guess of $spectator_guess: ");
	    say $magician_card->abbreviation if ($resp eq 'help');
	}
	say "\nNice job! How did you do that?!\n";
	
	sub generate_card_between {
	    my ( $low, $high ) = @_;
	    while (1) {
	        my $deck_num = int( rand( $high + 1 ) );
	        return $deck_num if ( $deck_num >= $low );
	    }
	}

=cut




=head1 AUTHOR

"Gordon Van Amburg", C<< <"vanamburg at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vanamburg-magic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VANAMBURG-Magic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VANAMBURG::Magic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VANAMBURG-Magic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VANAMBURG-Magic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VANAMBURG-Magic>

=item * Search CPAN

L<http://search.cpan.org/dist/VANAMBURG-Magic/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Gordon Van Amburg".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of VANAMBURG::Magic
