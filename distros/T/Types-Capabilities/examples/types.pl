use strict;
use warnings;
use Types::Capabilities -types;

my $types = ( Sortable & Mappable )
	->coerce( [ Types::Capabilities->type_names ] )
	->sort
	->map( sub { Types::Capabilities->get_type($_) } );

Eachable->coerce( $types )->each( sub {
	my $type = shift;
	
	my $coercion_iterator = do {
		my @tmp = @{ $type->coercion->type_coercion_map };
		sub {
			return if !@tmp;
			my ( $from, $via ) = splice @tmp, 0, 2;
			return $from;
		};
	};

	print "$type coerces from:\n";
	Eachable->coerce( $coercion_iterator )->each( sub {
		my $from = shift;
		print "  - $from\n";
	} );
	print "\n";
} );

__END__
Countable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - FileHandle
  - File

Dequeueable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - CodeRef

Eachable coerces from:
  - ArrayRef
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - FileHandle
  - File
  - CodeRef

Enqueueable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - CodeRef

Greppable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["map"]
  - ArrayLike
  - FileHandle
  - File
  - CodeRef

Joinable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - FileHandle
  - File

Mappable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - ArrayLike
  - FileHandle
  - File
  - CodeRef

Peekable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike

Poppable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - CodeRef

Pushable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - CodeRef

Reversible coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - FileHandle
  - File

Sortable coerces from:
  - ArrayRef
  - HasMethods["each"]
  - HasMethods["grep"]
  - HasMethods["map"]
  - ArrayLike
  - FileHandle
  - File

