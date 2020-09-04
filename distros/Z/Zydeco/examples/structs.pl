use v5.16;
use Data::Dumper;

package MyApp {
	use Zydeco;
	
	role Struct ( @spec ) {		
		confess 'Bad spec'
			if @spec % 2;
		
		my @attrs;
		for ( my $ix = 0; $ix < @spec; $ix +=2 ) {
			my ( $attr, $type ) = @spec[ $ix, $ix+1 ];
			if ( $attr eq -base ) {
				push @attrs, $type->KEYS;
			}
			else {
				push @attrs, $attr;
				has {$attr} ( type => $type, required => true );
			}
		}
		
		method KEYS   () { @attrs }
		method VALUES () { map $self->$_, @attrs }
		
		method FROM_VALUES ( @values ) {
			confess 'Expected %d values; got %d', scalar(@attrs), scalar(@values)
				unless @attrs == @values;
			$class->new( map { $attrs[$_] => $values[$_] } 0 .. $#attrs );
		}
		
		multi method FROM_REF ( ArrayRef $arr ) {
			$class->FROM_VALUES( @$arr );
		}
		multi method FROM_REF ( HashRef $h ) {
			$class->new( %$h );
		}
		
		method CLONE () { $class->FROM_VALUES( $self->VALUES ) }

		after_apply {
			return if $kind eq 'role';
			
			( my $shortname = lc substr($package, length($package->FACTORY)+2) ) =~ s/::/_/g;
			
			# Role generators can't have factories and coercions, but this
			# hook is getting run in the class the role gets applied to!
			factory {"new_$shortname"} via FROM_VALUES;
			coerce from ArrayRef|HashRef via FROM_REF;
		}
	}
	
	class Point {
		with Struct( "x" => Num, "y" => Num );
	}
	
	class Point3D {
		extends Point;
		with Struct( -base => "MyApp::Point", "z" => Num );
	}
}

use MyApp 'new_point3d';
use MyApp::Types 'to_Point3D';

print Dumper           to_Point3D [ 1, 2, 3.1 ];
print Dumper           to_Point3D { x => 1, y => 2, z => 3.1 };
print Dumper          new_point3d ( 1, 2, 3.1 );
print Dumper 'MyApp'->new_point3d ( 1, 2, 3.1 );
print Dumper 'MyApp::Point3D'->new( x => 1, y => 2, z => 3.1 );
