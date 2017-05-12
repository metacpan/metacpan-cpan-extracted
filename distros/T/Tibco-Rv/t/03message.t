$^W = 0;

use Tibco::Rv;

print "1..36\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },                 transport => $rv->transport );

my ( $msg ) = $rv->createMsg;
( $msg->sendSubject( 'SEND' ) && $msg->sendSubject eq 'SEND' ) ? &ok : &nok;
( $msg->replySubject( 'REPLY' ) && $msg->replySubject eq 'REPLY' ) ? &ok : &nok;
$msg->addBool( bool => Tibco::Rv::TRUE, 1024 );
( $msg->addF32( f32 => 1.5 ) && $msg->getF32( 'f32' ) == 1.5 ) ? &ok : &nok;
( $msg->addF64( f64 => 1.5 ) && $msg->getF64( 'f64' ) == 1.5 ) ? &ok : &nok;
( $msg->addI8( i8 => -20 ) && $msg->getI8( 'i8' ) == -20 ) ? &ok : &nok;
( $msg->addI16( i16 => -20 ) && $msg->getI16( 'i16' ) == -20 ) ? &ok : &nok;
( $msg->addI32( i32 => -20 ) && $msg->getI32( 'i32' ) == -20 ) ? &ok : &nok;
( $msg->addI64( i64 => -20 ) && $msg->getI64( 'i64' ) == -20 ) ? &ok : &nok;
( $msg->addU8( u8 => 20 ) && $msg->getU8( 'u8' ) == 20 ) ? &ok : &nok;
( $msg->addU16( u16 => 20 ) && $msg->getU16( 'u16' ) == 20 ) ? &ok : &nok;
( $msg->addU32( u32 => 20 ) && $msg->getU32( 'u32' ) == 20 ) ? &ok : &nok;
( $msg->addU64( u64 => 20 ) && $msg->getU64( 'u64' ) == 20 ) ? &ok : &nok;
{
   my ( $copy ) = $msg->copy;
   my ( $bytes ) = $copy->bytes;
   undef $msg;
   $msg = Tibco::Rv::Msg->createFromBytes( $bytes );
   $msg->expand( 100 );
}
( $msg->numFields == 11 ) ? &ok : &nok;
$msg->reset;
$msg->markReferences;
( $msg->numFields == 0 ) ? &ok : &nok;
( $msg->sendSubject eq '' ) ? &ok : &nok;
$msg->clearReferences;
$msg->addIPAddr32( ipaddr32 => '66.33.193.143' );
$msg->addIPPort16( ipport16 => 1024 );
( "$msg" =~ /66\.33\.193\.143/ && "$msg" =~ /1024/ ) ? &ok : &nok;
( $msg->getField( 'ipaddr32' )->ipaddr32 eq '66.33.193.143' ) ? &ok : &nok;
( $msg->getField( 'ipport16' )->ipport16 == 1024 ) ? &ok : &nok;
$msg->addString( string => 'abc' );
$msg->addXml( xml => '<data>' . $msg->getString( 'string' ) . '</data>' );
$msg->addOpaque( opaque => $msg->getXml( 'xml' ) );
my ( $op ) = $msg->getOpaque( 'opaque' );
( $msg->getOpaque( 'opaque' ) eq '<data>abc</data>' ) ? &ok : &nok;

$msg->reset;
my ( $field ) = $msg->createField( name => 'myArray' );
$field->i8array( [ 1, 2, 3 ] );
$msg->updateField( $field );
$msg->addField( $field );
( $msg->getFieldByIndex( 0 )->i8array->[ 2 ] == 3 ) ? &ok : &nok;
( $msg->getFieldInstance( 'myArray', 2 )->i8array->[ 2 ] == 3 ) ? &ok : &nok;
$msg->updateMsg( myMsg => Tibco::Rv::Msg->createFromBytes( $msg->bytesCopy ) );
$msg->updateF32( myF32 =>
   $msg->getMsg( 'myMsg' )->getU8Array( 'myArray' )->[ 1 ] );
( $msg->getF32( 'myF32' ) == 2 ) ? &ok : &nok;
$msg->removeField( 'myMsg' );
$msg->updateI8Array( myArray => [ 2, 4, 6, 8 ] );
$msg->removeFieldInstance( 'myArray', 2 );
( $msg->getI16Array( 'myArray' )->[ 3 ] == 8 ) ? &ok : &nok;
( $msg->numFields == 2 ) ? &ok : &nok;
my ( $now ) = time;
$msg->updateDateTime( myTime => Tibco::Rv::Msg::DateTime->now );
( abs( $msg->getDateTime( 'myTime' )->sec - $now ) < 10 ) ? &ok : &nok;
$msg->updateIPAddr32( myaddr => '66.33.193.143' );
$msg->updateIPPort16( myport => 80 );
( join( ':', $msg->getIPAddr32( 'myaddr' ), $msg->getIPPort16( 'myport' ) )
   eq '66.33.193.143:80' ) ? &ok : &nok;

( $msg->updateBool( bool => Tibco::Rv::TRUE )
   && $msg->getBool( 'bool' ) == Tibco::Rv::TRUE ) ? &ok : &nok;
( $msg->updateF64( f64 => 1.5 ) && $msg->getF64( 'f64' ) == 1.5 ) ? &ok : &nok;
( $msg->updateI8( i8 => -20 ) && $msg->getI8( 'i8' ) == -20 ) ? &ok : &nok;
( $msg->updateI16( i16 => -20 ) && $msg->getI16( 'i16' ) == -20 ) ? &ok : &nok;
( $msg->updateI32( i32 => -20 ) && $msg->getI32( 'i32' ) == -20 ) ? &ok : &nok;
( $msg->updateI64( i64 => -20 ) && $msg->getI64( 'i64' ) == -20 ) ? &ok : &nok;
( $msg->updateU8( u8 => 20 ) && $msg->getU8( 'u8' ) == 20 ) ? &ok : &nok;
( $msg->updateU16( u16 => 20 ) && $msg->getU16( 'u16' ) == 20 ) ? &ok : &nok;
( $msg->updateU32( u32 => 20 ) && $msg->getU32( 'u32' ) == 20 ) ? &ok : &nok;
( $msg->updateU64( u64 => 20 ) && $msg->getU64( 'u64' ) == 20 ) ? &ok : &nok;
