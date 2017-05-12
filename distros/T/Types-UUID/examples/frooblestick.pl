use 5.014;

package FroobleStick {
	
	use Moo 1.006000;
	use Types::UUID;
	
	has identifier => (
		is      => 'lazy',
		isa     => Uuid,
		coerce  => 1,
		builder => Uuid->generator,
	);
}

my $stick = FroobleStick->new;
say $stick->identifier;
