use v5.16;
use Data::Dumper;

package MyApp {
	use Zydeco;
	use Carp 'confess';
	
	role Struct ( @spec ) {
		my @attrs;
		confess 'Bad spec' if @spec % 2;
		for ( my $ix = 0; $ix < @spec; $ix +=2 ) {
			my ( $attr, $type ) = @spec[ $ix, $ix+1 ];
			push @attrs, $attr;
			has {$attr} ( type => $type );
		}
		
		method SPEC   () { @spec }
		method KEYS   () { @attrs }
		method VALUES () { map $self->$_, @attrs }
		
		method FROM_VALUES ( @values ) {
			confess sprintf('Expected %d values; got %d', scalar(@attrs), scalar(@values))
				unless @attrs == @values;
			$class->new( map { $attrs[$_] => $values[$_] } 0 .. $#attrs );
		}
		
		method CLONE () { $class->FROM_VALUES( $self->VALUES ) }
	}
	
	role StructEx ( $base, @spec ) {
		with Struct( $base->SPEC, @spec );
	}
	
	class Point {
		with Struct("x" => Num, "y" => Num);
		factory new_point via FROM_VALUES;
	}
	
	class Point3D {
		extends Point;
		with StructEx("MyApp::Point", "z" => Num);
		factory new_point3d via FROM_VALUES;
	}
}

use MyApp 'new_point3d';

print Dumper( new_point3d(3, 4, 3.1)->CLONE->CLONE );
