package VANAMBURG::RandomNumbers;
use List::Util qw/shuffle/;


=head1 VANAMBURG::RandomNumbers

Random number generators specifically useful for card magic
simulations.

=cut

=head2 random_stacknumbers

   my @ten_selections = $random_stacknumbers(10);

Returns an array of numbers having the value of 1 through 52.

=cut

sub random_stacknumbers {
	my ( $class, $number_of_numbers ) = @_;

	my %stack_nums;
	while ( keys %stack_nums < $number_of_numbers) {
		my $stack_num;
		while (1) {
			$stack_num = int( rand(53) );
			if ( $stack_num > 0 && !exists $stack_nums{$stack_num} ) {
				$stack_nums{$stack_num} = 1;
				last;
			}# end if
		}# end while
	}# end while
	my @results = keys %stack_nums;
	return shuffle @results;
}


=head2 number_between

	my $number = number_between(1,10);
	
=cut

sub number_between {
    my ( $low, $high ) = @_;
    while (1) {
        my $deck_num = int( rand( $high + 1 ) );
        return $deck_num if ( $deck_num >= $low );
    }
}

1;
