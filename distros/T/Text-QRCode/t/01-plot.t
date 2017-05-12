#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Text::QRCode' );
}

sub match_test {
    my $arrayref = Text::QRCode->new->plot( $_[0]->[0] );
    my $got = join( "\n", map { join '', @$_ } @$arrayref ) . "\n";
    my $expect = $_[0]->[1];
    is( $got, $expect, 'match test');
}

my @Tests = (
    [ 'Some text here.', <<'TEXT' ],
******* *  ** *******
*     *   * * *     *
* *** *       * *** *
* *** *   **  * *** *
* *** *  * *  * *** *
*     *  **** *     *
******* * * * *******
        *  **        
** ** *   *** *     *
*   **  ***    * *   
 * ****     * *    **
*    * * * * * ** ***
  **  *   ***   ** **
        * **  * **  *
*******  *****  ***  
*     *  * ** * **** 
* *** * *   *    * * 
* *** * * **   *  *  
* *** *     *** * ***
*     * **  * *   ***
******* * *  ****    
TEXT
);

match_test( $Tests[0] );
