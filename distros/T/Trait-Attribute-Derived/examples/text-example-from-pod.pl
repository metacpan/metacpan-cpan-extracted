use 5.010;
use strict;
use warnings;

{
	package Text;
	use Moose;
	 
	use Trait::Attribute::Derived FindReplace => {
		fields => {
			find    => 'RegexpRef',
			replace => 'Str',
		},
		processor => sub {
			my ($self, $value, $fields) = @_;
			$value =~ s/$fields->{find}/$fields->{replace}/g;
			return $value;
		},
	};
	 
	has plain => (
		is       => 'ro',
		isa      => 'Str',
	);
	has vowels_only => (
		traits   => [ FindReplace ],
		source   => 'plain',
		find     => qr{[^AEIOU]}i,
		replace  => '',
	);
	has no_vowels  => (
		traits   => [ FindReplace ],
		source   => 'plain',
		find     => qr{[AEIOU]}i,
		replace  => '',
	);
}

my $text = Text->new(plain => 'Hello World');

say $text->vowels_only;
say $text->no_vowels;
