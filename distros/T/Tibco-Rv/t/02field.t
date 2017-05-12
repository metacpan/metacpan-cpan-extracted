$^W = 0;

use Tibco::Rv;

print "1..33\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },                 transport => $rv->transport );

my ( $msg ) = $rv->createMsg;
my ( $field ) = $msg->createField;

( $field->name( 'myField' ) && $field->name eq 'myField' ) ? &ok : &nok;
( $field->id( 23 ) && $field->id eq 23 ) ? &ok : &nok;
( $field->bool( Tibco::Rv::TRUE ) && $field->bool == Tibco::Rv::TRUE )
   ? &ok : &nok;
eval { $field->i8 };
( $@ == Tibco::Rv::ARG_CONFLICT ) ? &ok : &nok;

my ( $date ) = Tibco::Rv::Msg::DateTime->now;
my ( $now ) = time;
( abs( $date - $now ) < 10 ) ? &ok : &nok;

( $field->str( 'abcabc' ) && $field->str eq 'abcabc' ) ? &ok : &nok;
( $field->xml( '<abcabc/>' ) && $field->xml eq '<abcabc/>' ) ? &ok : &nok;
( $field->opaque( "a\0bcabc" ) && $field->opaque eq "a\0bcabc" ) ? &ok : &nok;
( $field->str( "a\0bcabc" ) && $field->str eq "a" ) ? &ok : &nok;
( $field->ipaddr32( '66.33.193.143' ) && $field->ipaddr32 eq '66.33.193.143' )
   ? &ok : &nok;
( $field->ipport16( 10 ) && $field->ipport16 == 10 ) ? &ok : &nok;
( $field->i8( -10 ) && $field->i8 == -10 ) ? &ok : &nok;
( $field->i16( -10 ) && $field->i16 == -10 ) ? &ok : &nok;
( $field->i32( -10 ) && $field->i32 == -10 ) ? &ok : &nok;
( $field->i64( -10 ) && $field->i64 == -10 ) ? &ok : &nok;
( $field->u8( 10 ) && $field->u8 == 10 ) ? &ok : &nok;
( $field->u16( 10 ) && $field->u16 == 10 ) ? &ok : &nok;
( $field->u32( 10 ) && $field->u32 == 10 ) ? &ok : &nok;
( $field->u64( 10 ) && $field->u64 == 10 ) ? &ok : &nok;

$msg->addField( $field );
$field->msg( $msg );
( $field->msg->getU64( 'myField', 23 ) == 10 ) ? &ok : &nok;

&test_array( $field, 'f32array', 6, [ 1.5, 2.5, -1, 3 ] );
&test_array( $field, 'f64array', 16, [ 1.5, 12.5, -1, 3 ] );
&test_array( $field, 'i8array', 6, [ 1, 2, 3 ] );
&test_array( $field, 'i16array', 6, [ 1, 2, 3 ] );
&test_array( $field, 'i32array', -6, [ -1, -2, -3 ] );
&test_array( $field, 'i64array', 6, [ 1, 2, 3 ] );
&test_array( $field, 'u8array', 16, [ 6, 2, 3, 5 ] );
&test_array( $field, 'u16array', 6, [ 1, 2, 3 ] );
&test_array( $field, 'u32array', 6, [ 1, 2, 3 ] );
&test_array( $field, 'u64array', 30003, [ 1, 2, 30000 ] );
( $field->count == 3 ) ? &ok : &nok;
( $field->size == 8 ) ? &ok : &nok;
( $field->type == Tibco::Rv::Msg::U64ARRAY ) ? &ok : &nok;


sub test_array
{
   my ( $field, $type, $expect, $ary ) = @_;
   $field->$type( $ary );
   my ( $sum );
   map { $sum += $_ } @{ $field->$type( ) };
   ( $sum == $expect ) ? &ok : &nok;
}
