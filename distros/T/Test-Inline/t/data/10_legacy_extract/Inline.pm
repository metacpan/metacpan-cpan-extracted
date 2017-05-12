package My::Pirate;

# The various tutorial examples

=pod

=item B<is_pirate>

    @pirates = is_pirate(@arrrgs);

Go through @arrrgs and return a list of pirates.

=begin testing

my @p = is_pirate('Blargbeard', 'Alfonse', 'Capt. Hampton', 'Wesley');
is(@p,  2,   "Found two pirates.  ARRR!");

=end testing

=cut

sub is_pirate {
	1;
}

=pod

=for example begin

use LWP::Simple;
getprint "http://www.goats.com";

=for example end

=cut

