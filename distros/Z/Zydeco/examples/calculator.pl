use v5.16;

package MyApp {
	use Zydeco;
	
	class Calc {
		multi method plus   ( Num $x, Num $y ) = $x + $y;
		multi method minus  ( Num $x, Num $y ) = $x - $y;
		multi method minus  ( Num $x )         = -$x;
		multi method times  ( Num $x, Num $y ) = $x * $y;
		multi method divide ( Num $x, Num $y ) = $x / $y;
		multi method modulo ( Num $x, Num $y ) = $x % $y;
	}
}

say MyApp->new_calc->plus(40, 2);
