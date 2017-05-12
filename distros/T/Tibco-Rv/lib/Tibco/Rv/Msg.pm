package Tibco::Rv::Msg;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.12';


use Inline with => 'Tibco::Rv::Inline';
use Inline C => 'DATA', NAME => __PACKAGE__,
   VERSION => $Tibco::Rv::Inline::VERSION;


use constant FIELDNAME_MAX => 127;

use constant MSG => 1;
use constant DATETIME => 3;
use constant OPAQUE => 7;
use constant STRING => 8;
use constant BOOL => 9;
use constant I8 => 14;
use constant U8 => 15;
use constant I16 => 16;
use constant U16 => 17;
use constant I32 => 18;
use constant U32 => 19;
use constant I64 => 20;
use constant U64 => 21;
use constant F32 => 24;
use constant F64 => 25;
use constant IPPORT16 => 26;
use constant IPADDR32 => 27;
use constant ENCRYPTED => 32;
use constant NONE => 22;
use constant I8ARRAY => 34;
use constant U8ARRAY => 35;
use constant I16ARRAY => 36;
use constant U16ARRAY => 37;
use constant I32ARRAY => 38;
use constant U32ARRAY => 39;
use constant I64ARRAY => 40;
use constant U64ARRAY => 41;
use constant F32ARRAY => 44;
use constant F64ARRAY => 45;

use constant XML => 47;


use Tibco::Rv::Msg::Field;
@CARP_NOT = qw/ Tibco::Rv::Msg::Field /;


use overload '""' => 'toString';


my ( %defaults );
BEGIN
{
   %defaults = ( sendSubject => undef, replySubject => undef );
}


sub new
{
   my ( $proto ) = shift;
   my ( %fields ) = ( );
   my ( %args ) = @_;
   foreach my $field ( keys %args )
   {
      next if ( exists $defaults{$field} );
      $fields{$field} = $args{$field};
      delete $args{$field};
   }
   my ( %params ) = ( %defaults, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Msg_Create( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   $self->sendSubject( $params{sendSubject} )
      if ( defined $params{sendSubject} );
   $self->replySubject( $params{replySubject} )
      if ( defined $params{replySubject} );
   map { $self->addString( $_ => $fields{$_} ) } sort keys %fields;

   return $self;
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $id ) = @_;
   my ( $self );
   my ( $class ) = ref( $proto );
   if ( $class )
   {
      $self->DESTROY;
      @$self{ 'id', keys %defaults } = ( $id, values %defaults );
   } else {
      $self = $proto->_new( $id );
   }
   $self->_getValues;
   return $self;
}


sub _getValues
{
   my ( $self ) = @_;
   Msg_GetValues( @$self{ qw/ id sendSubject replySubject / } );
}


sub createField { shift; return new Tibco::Rv::Msg::Field( @_ ) }
sub createDateTime { shift; return new Tibco::Rv::Msg::DateTime( @_ ) }


sub copy
{
   my ( $self ) = @_;
   my ( $copy );
   my ( $status ) = Msg_CreateCopy( $self->{id}, $copy );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return Tibco::Rv::Msg->_adopt( $copy );
}


sub createFromBytes
{
   my ( $proto, $bytes ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { id => undef,
      sendSubject => undef, replySubject => undef }, $class;

   my ( $status ) = Msg_CreateFromBytes( $self->{id}, $bytes );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub bytes
{
   my ( $self ) = @_;
   my ( $bytes );
   my ( $status ) = Msg_GetAsBytes( $self->{id}, $bytes );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $bytes;
}


sub bytesCopy
{
   my ( $self ) = @_;
   my ( $bytes );
   my ( $status ) = Msg_GetAsBytesCopy( $self->{id}, $bytes );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $bytes;
}


sub expand
{
   my ( $self, $additionalStorage ) = @_;
   my ( $status ) = tibrvMsg_Expand( $self->{id}, $additionalStorage );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub reset
{
   my ( $self ) = @_;
   my ( $status ) = tibrvMsg_Reset( $self->{id} );
   @$self{ qw/ sendSubject replySubject / } = ( undef, undef );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub numFields
{
   my ( $self ) = @_;
   my ( $num );
   my ( $status ) = Msg_GetNumFields( $self->{id}, $num );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $num;
}


sub byteSize
{
   my ( $self ) = @_;
   my ( $size );
   my ( $status ) = Msg_GetByteSize( $self->{id}, $size );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $size;
}


sub toString
{
   my ( $self ) = @_;
   my ( $str );
   my ( $status ) = Msg_ConvertToString( $self->{id}, $str );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $str;
}


sub sendSubject
{
   my ( $self ) = shift;
   return @_ ? $self->_setSendSubject( @_ ) : $self->{sendSubject};
}


sub _setSendSubject
{
   my ( $self, $subject ) = @_;
   my ( $status ) = tibrvMsg_SetSendSubject( $self->{id}, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{sendSubject} = $subject;
}


sub replySubject
{
   my ( $self ) = shift;
   return @_ ? $self->_setReplySubject( @_ ) : $self->{replySubject};
}


sub _setReplySubject
{
   my ( $self, $subject ) = @_;
   my ( $status ) = tibrvMsg_SetReplySubject( $self->{id}, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{replySubject} = $subject;
}


sub addField
{
   my ( $self, $field ) = @_;
   my ( $status ) = tibrvMsg_AddField( $self->{id}, $field->{ptr} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub addBool { shift->_addScalar( 'tibrvMsg_AddBoolEx', @_ ) }
sub addF32 { shift->_addScalar( 'tibrvMsg_AddF32Ex', @_ ) }
sub addF64 { shift->_addScalar( 'tibrvMsg_AddF64Ex', @_ ) }
sub addI8 { shift->_addScalar( 'tibrvMsg_AddI8Ex', @_ ) }
sub addI16 { shift->_addScalar( 'tibrvMsg_AddI16Ex', @_ ) }
sub addI32 { shift->_addScalar( 'tibrvMsg_AddI32Ex', @_ ) }
sub addI64 { shift->_addScalar( 'tibrvMsg_AddI64Ex', @_ ) }
sub addU8 { shift->_addScalar( 'tibrvMsg_AddU8Ex', @_ ) }
sub addU16 { shift->_addScalar( 'tibrvMsg_AddU16Ex', @_ ) }
sub addU32 { shift->_addScalar( 'tibrvMsg_AddU32Ex', @_ ) }
sub addU64 { shift->_addScalar( 'tibrvMsg_AddU64Ex', @_ ) }
sub addIPPort16 { shift->_addScalar( 'Msg_AddIPPort16', @_ ) }
sub addString { shift->_addScalar( 'tibrvMsg_AddStringEx', @_ ) }
sub addOpaque { shift->_addScalar( 'Msg_AddOpaque', @_ ) }
sub addXml { shift->_addScalar( 'Msg_AddXml', @_ ) }


sub addIPAddr32
{
   my ( $self, $fieldName, $ipaddr32, $fieldId ) = @_;
   my ( $a, $b, $c, $d ) = split( /\./, $ipaddr32 );
   $ipaddr32 = ( $a << 24 ) + ( $b << 16 ) + ( $c << 8 ) + $d;
   $self->_addScalar( 'Msg_AddIPAddr32', $fieldName, $ipaddr32, $fieldId );
}


sub addMsg
{
   my ( $self, $fieldName, $msg, $fieldId ) = @_;
   $self->_addScalar( 'tibrvMsg_AddMsgEx', $fieldName, $msg->{id}, $fieldId );
}


sub addDateTime
{
   my ( $self, $fieldName, $date, $fieldId ) = @_;
   $self->_addScalar( 'tibrvMsg_AddDateTimeEx',
      $fieldName, $date->{ptr}, $fieldId );
}


sub addF32Array { shift->_addArray( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub addF64Array { shift->_addArray( Tibco::Rv::Msg::F64ARRAY, @_ ) }
sub addI8Array { shift->_addArray( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub addI16Array { shift->_addArray( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub addI32Array { shift->_addArray( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub addI64Array { shift->_addArray( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub addU8Array { shift->_addArray( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub addU16Array { shift->_addArray( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub addU32Array { shift->_addArray( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub addU64Array { shift->_addArray( Tibco::Rv::Msg::U64ARRAY, @_ ) }


sub getField
{
   my ( $self, $fieldName, $fieldId ) = @_;
   my ( $field );
   my ( $status ) = Msg_GetField( $self->{id}, $fieldName, $field, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg::Field->_adopt( $field ) : undef;
}


sub getBool { return shift->_getScalar( Tibco::Rv::Msg::BOOL, @_ ) }
sub getF32 { return shift->_getScalar( Tibco::Rv::Msg::F32, @_ ) }
sub getF64 { return shift->_getScalar( Tibco::Rv::Msg::F64, @_ ) }
sub getI8 { return shift->_getScalar( Tibco::Rv::Msg::I8, @_ ) }
sub getI16 { return shift->_getScalar( Tibco::Rv::Msg::I16, @_ ) }
sub getI32 { return shift->_getScalar( Tibco::Rv::Msg::I32, @_ ) }
sub getI64 { return shift->_getScalar( Tibco::Rv::Msg::I64, @_ ) }
sub getU8 { return shift->_getScalar( Tibco::Rv::Msg::U8, @_ ) }
sub getU16 { return shift->_getScalar( Tibco::Rv::Msg::U16, @_ ) }
sub getU32 { return shift->_getScalar( Tibco::Rv::Msg::U32, @_ ) }
sub getU64 { return shift->_getScalar( Tibco::Rv::Msg::U64, @_ ) }
sub getIPPort16 { return shift->_getScalar( Tibco::Rv::Msg::IPPORT16, @_ ) }
sub getString { return shift->_getScalar( Tibco::Rv::Msg::STRING, @_ ) }
sub getOpaque { return shift->_getScalar( Tibco::Rv::Msg::OPAQUE, @_ ) }
sub getXml { return shift->_getScalar( Tibco::Rv::Msg::XML, @_ ) }


sub getIPAddr32
{
   my ( $self, $fieldName, $fieldId ) = @_;
   my ( $ipaddr32 ) =
      $self->_getScalar( Tibco::Rv::Msg::IPADDR32, $fieldName, $fieldId );
   my ( $a, $b, $c, $d );
   $a = $ipaddr32; $a >>= 24; $ipaddr32 -= $a << 24;
   $b = $ipaddr32; $b >>= 16; $ipaddr32 -= $b << 16;
   $c = $ipaddr32; $c >>= 8; $ipaddr32 -= $c << 8;
   $d = $ipaddr32;
   return "$a.$b.$c.$d";
}


sub getMsg
{
   my ( $self, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $msg );
   my ( $status ) = Msg_GetScalar( $self->{id},
      Tibco::Rv::Msg::MSG, $fieldName, $msg, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK ) ? Tibco::Rv::Msg->_adopt( $msg ) : undef;
}


sub getDateTime
{
   my ( $self, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $date );
   my ( $status ) = Msg_GetScalar( $self->{id},
      Tibco::Rv::Msg::DATETIME, $fieldName, $date, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg::DateTime->_adopt( $date ) : undef;
}


sub getF32Array { return shift->_getArray( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub getF64Array { return shift->_getArray( Tibco::Rv::Msg::F64ARRAY, @_ ) }
sub getI8Array { return shift->_getArray( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub getI16Array { return shift->_getArray( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub getI32Array { return shift->_getArray( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub getI64Array { return shift->_getArray( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub getU8Array { return shift->_getArray( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub getU16Array { return shift->_getArray( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub getU32Array { return shift->_getArray( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub getU64Array { return shift->_getArray( Tibco::Rv::Msg::U64ARRAY, @_ ) }


sub getFieldByIndex
{
   my ( $self, $fieldIndex ) = @_;
   my ( $field );
   my ( $status ) = Msg_GetFieldByIndex( $self->{id}, $field, $fieldIndex );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return Tibco::Rv::Msg::Field->_adopt( $field );
}


sub getFieldInstance
{
   my ( $self, $fieldName, $instance ) = @_;
   my ( $field );
   my ( $status ) = Msg_GetFieldInstance( $self->{id},
      $fieldName, $field, $instance );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg::Field->_adopt( $field ) : undef;
}


sub removeField
{
   my ( $self, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = tibrvMsg_RemoveFieldEx( $self->{id}, $fieldName, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return new Tibco::Rv::Status( status => $status );
}


sub removeFieldInstance
{
   my ( $self, $fieldName, $instance ) = @_;
   my ( $status ) = tibrvMsg_RemoveFieldInstance( $self->{id},
      $fieldName, $instance );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return new Tibco::Rv::Status( status => $status );
}


sub updateField
{
   my ( $self, $field ) = @_;
   my ( $status ) = tibrvMsg_UpdateField( $self->{id}, $field->{ptr} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub updateBool { shift->_updScalar( 'tibrvMsg_UpdateBoolEx', @_ ) }
sub updateF32 { shift->_updScalar( 'tibrvMsg_UpdateF32Ex', @_ ) }
sub updateF64 { shift->_updScalar( 'tibrvMsg_UpdateF64Ex', @_ ) }
sub updateI8 { shift->_updScalar( 'tibrvMsg_UpdateI8Ex', @_ ) }
sub updateI16 { shift->_updScalar( 'tibrvMsg_UpdateI16Ex', @_ ) }
sub updateI32 { shift->_updScalar( 'tibrvMsg_UpdateI32Ex', @_ ) }
sub updateI64 { shift->_updScalar( 'tibrvMsg_UpdateI64Ex', @_ ) }
sub updateU8 { shift->_updScalar( 'tibrvMsg_UpdateU8Ex', @_ ) }
sub updateU16 { shift->_updScalar( 'tibrvMsg_UpdateU16Ex', @_ ) }
sub updateU32 { shift->_updScalar( 'tibrvMsg_UpdateU32Ex', @_ ) }
sub updateU64 { shift->_updScalar( 'tibrvMsg_UpdateU64Ex', @_ ) }
sub updateIPPort16 { shift->_updScalar( 'Msg_UpdateIPPort16', @_ ) }
sub updateString { shift->_updScalar( 'tibrvMsg_UpdateStringEx', @_ ) }
sub updateOpaque { shift->_updScalar( 'Msg_UpdateOpaque', @_ ) }
sub updateXml { shift->_updScalar( 'Msg_UpdateXml', @_ ) }


sub updateIPAddr32
{
   my ( $self, $fieldName, $ipaddr32, $fieldId ) = @_;
   my ( $a, $b, $c, $d ) = split( /\./, $ipaddr32 );
   $ipaddr32 = ( $a << 24 ) + ( $b << 16 ) + ( $c << 8 ) + $d;
   $self->_updScalar( 'Msg_UpdateIPAddr32', $fieldName, $ipaddr32, $fieldId );
}


sub updateMsg
{
   my ( $self, $fieldName, $msg, $fieldId ) = @_;
   $self->_updScalar( 'tibrvMsg_UpdateMsgEx',
      $fieldName, $msg->{id}, $fieldId );
}


sub updateDateTime
{
   my ( $self, $fieldName, $date, $fieldId ) = @_;
   $self->_updScalar( 'tibrvMsg_UpdateDateTimeEx',
      $fieldName, $date->{ptr}, $fieldId );
}


sub updateF32Array { shift->_updArray( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub updateF64Array { shift->_updArray( Tibco::Rv::Msg::F64ARRAY, @_ ) }
sub updateI8Array { shift->_updArray( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub updateI16Array { shift->_updArray( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub updateI32Array { shift->_updArray( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub updateI64Array { shift->_updArray( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub updateU8Array { shift->_updArray( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub updateU16Array { shift->_updArray( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub updateU32Array { shift->_updArray( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub updateU64Array { shift->_updArray( Tibco::Rv::Msg::U64ARRAY, @_ ) }


sub clearReferences
{
   my ( $self ) = @_;
   my ( $status ) = tibrvMsg_ClearReferences( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub markReferences
{
   my ( $self ) = @_;
   my ( $status ) = tibrvMsg_MarkReferences( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub _addScalar
{
   my ( $self, $fxn, $fieldName, $value, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = $fxn->( $self->{id}, $fieldName, $value, $fieldId );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub _getScalar
{
   my ( $self, $type, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $value );
   my ( $status ) = Msg_GetScalar( $self->{id},
      $type, $fieldName, $value, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK ) ? $value : undef;
}


sub _updScalar
{
   my ( $self, $fxn, $fieldName, $value, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = $fxn->( $self->{id}, $fieldName, $value, $fieldId );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub _getArray
{
   my ( $self, $type, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $elts ) = [ ];
   my ( $status ) =
      Msg_GetArray( $self->{id}, $type, $fieldName, $elts, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK ) ? $elts : undef;
}


sub _addArray { shift->_addOrUpdArray( Tibco::Rv::TRUE, @_ ) }
sub _updArray { shift->_addOrUpdArray( Tibco::Rv::FALSE, @_ ) }


sub _addOrUpdArray
{
   my ( $self, $isAdd, $type, $fieldName, $elts, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = Msg_AddOrUpdateArray( $self->{id},
      $isAdd, $type, $fieldName, $elts, $fieldId );
   die Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = tibrvMsg_Destroy( $self->{id} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Msg - Tibco message object

=head1 SYNOPSIS

   my ( $rv ) = new Tibco::Rv;
   my ( $msg ) = $rv->createMsg;

   $msg->addString( myField => 'a string' );
   $msg->addBool( myField2 => Tibco::Rv::TRUE );
   $msg->addI8Array( myNums => [ 1, 2, 3 ] );

   $msg->sendSubject( 'MY.SEND.SUBJECT' );
   $rv->send( $msg );

=head1 DESCRIPTION

Tibco Message-manipulating class.  Add/update/delete data fields, set
subject addressing information, and get the on-the-wire byte representation.

All methods die with a L<Tibco::Rv::Status|Tibco::Rv::Status> message if
there are any TIB/Rendezvous errors.

=head1 CONSTRUCTOR

=over 4

=item $msg = new Tibco::Rv::Msg( %args )

   %args:
      sendSubject => $sendSubject,
      replySubject => $replySubject,
      $fieldName1 => $stringValue1,
      $fieldName2 => $stringValue2, ...

Creates a C<Tibco::Rv::Msg>, with sendSubject and replySubject as given
in %args (sendSubject and replySubject default to C<undef> if not specified).
Any other name => value pairs are added as string fields.

=back

=head1 METHODS

=over 4

=item $field = $msg->createField

Returns a new L<Tibco::Rv::Msg::Field|Tibco::Rv::Msg::Field> object.

=item $date = $msg->createDateTime

Returns a new L<Tibco::Rv::Msg::DateTime|Tibco::Rv::Msg::DateTime> object.

=item $msgCopy = $msg->copy

Returns a newly created, independent copy of C<$msg>.  C<$msgCopy> has all
the same field data as C<$msg>, but none of the subject addressing information.

=item $bytes = $msg->bytes

Returns the on-the-wire byte representation of C<$msg> as a scalar value.

=item $bytes = $msg->bytesCopy

Same as C<bytes>, but with an extraneous memory allocation.  You probably just
want to use C<bytes>.

=item $msg = Tibco::Rv::Msg->createFromBytes( $bytes )

Returns a newly created C<Tibco::Rv::Msg> from the on-the-wire byte
representation C<$bytes>.

=item $msg->expand( $additionalStorage )

Increase memory allocated for this message by C<$addtionalStorage> bytes.
You might want to do this before adding a lot of data to a message.

=item $msg->reset

Removes all fields and subject addressing information.

=item $numFields = $msg->numFields

Returns the number of fields in C<$msg> (not including fields in sub-messages).

=item $byteSize = $msg->byteSize

Returns the number of bytes taken up by the on-the-wire byte representation.

=item $string = $msg->toString (or "$msg")

Returns a string representation of C<$msg> for printing.

=item $subject = $msg->sendSubject

Returns the subject on which C<$msg> will be published when sent via a
Transport object.

=item $msg->sendSubject( $subject )

Sets the subject on which C<$msg> will be published went sent via a
Transport object.

=item $subject = $msg->replySubject

Returns the subject on which replies will be received when C<$msg> is sent
as a request/reply message via a Transport's sendRequest method.

=item $msg->replySubject( $subject )

Sets the subject on which replies will be recieved when C<$msg> is sent
as a request/reply message via a Transport's sendRequest method.  Returns
the new subject.

=item $msg->addField( $field )

Adds L<Field|Tibco::Rv::Msg::Field> C<$field> to C<$msg>.

=item $msg->add<type>( $fieldName => $value, $fieldId )

   <type> can be:
      Bool, String, Opaque, Xml,
      F32, F64, I8, I16, I32, I64, U8, U16, U32, U64,
      IPAddr32, IPPort16, DateTime, or Msg

Adds C<$value> to C<$msg> at field C<$fieldName>, as type E<lt>typeE<gt>.
C<$fieldId> is an optional field identifier.  It must be unique within this
message.

Bool values should be Tibco::Rv::TRUE or Tibco::Rv::FALSE.

Opaque values can contain embedded nulls "\0", while String and Xml values
cannot (and if you try, they'll be truncated to the first null).

IPAddr32 values should be specified in dotted-quad notation.  For example,
'66.33.193.143'.

DateTime values must be of type
L<Tibco::Rv::Msg::DateTime|Tibco::Rv::Msg::DateTime>.

=item $msg->add<type>Array( $fieldName => [ $val1, $val2, ... ], $fieldId )

   <type> can be:
   F32, F64, I8, I16, I32, I64, U8, U16, U32, or U64

Adds the given array reference of E<lt>typeE<gt> values to C<$msg> at field
C<$fieldName>.  C<$fieldId> is an optional field identifier.  It must be
unique within this message.

=item $value = $msg->get<type>( $fieldName, $fieldId )

   <type> can be:
      Field, Bool, String, Opaque, Xml,
      F32, F64, I8, I16, I32, I64, U8, U16, U32, U64,
      IPAddr32, IPPort16, DateTime, or Msg

Returns the value of the specified field.  If C<$fieldId> is not specified
(or C<undef>), returns the first field found named C<$fieldName>.  If
C<$fieldId> is specified, returns the field with the given C<$fieldId>.

If the specified field is not found, returns C<undef>.

If the field is found but it is of a different type, returns the value
converted to the given E<lt>typeE<gt>.  If conversion is not possible,
dies with a Tibco::Rv::CONVERSION_FAILED Status message.

If C<$fieldId> is specified but is not found, and a field named C<$fieldName>
is found but with a different C<$fieldId>, then this method dies with
a Tibco::Rv::ID_CONFLICT Status message.

=item $valAryRef = $msg->get<type>Array( $fieldName, $fieldId )

   <type> can be:
      F32, F64, I8, I16, I32, I64, U8, U16, U32, U64,

Behaves the same as getE<lt>typeE<gt>, except that it returns an array
reference of values instead of a single value.

=item $field = $msg->getFieldByIndex( $fieldIndex )

Returns field at index C<$fieldIndex>.  Iterate over all fields in C<$msg>
by using this method over range 0 .. numFields - 1.

=item $field = $msg->getFieldInstance( $fieldName, $instance )

When a message contains multiple fields with the same name, use this method
to interate over all messages named C<$fieldName>.  Returns C<undef> if
not found, and when C<$instance> exceeds the number of fields in this
message named C<$fieldName>.  The first field of a given name is retrieved
by using C<$instance = 1>.

=item $status = $msg->removeField( $fieldName, $fieldId )

Searches for a field using the same algorithm as getE<lt>typeE<gt>.  If
found, removes it.  Returns Status Tibco::Rv::OK if found and deleted,
or Status Tibco::Rv::NOT_FOUND if not found.

=item $status = $msg->removeFieldInstance( $fieldName, $instance )

Searches for a field using the same algorithm as getFieldInstance.  If
found, removes it.  Returns Status Tibco::Rv::OK if found and deleted,
or Status Tibco::Rv::NOT_FOUND if not found.

=item $msg->updateField( $field )

Updates the field specified by C<$field>'s name and identifier.  If the field
is not found, then C<$field> is simply added.

If the field is found in C<$msg>, and its type does not match the type of
C<$field>, this method dies with a Tibco::Rv::INVALID_TYPE Status message.

=item $msg->update<type>( $fieldName, $value, $fieldId )

   <type> can be:
      Field, Bool, String, Opaque, Xml,
      F32, F64, I8, I16, I32, I64, U8, U16, U32, U64,
      IPAddr32, IPPort16, DateTime, or Msg

Updates the field specified by C<$fieldName> and C<$fieldId> (C<$fieldId> is
optional).  If the field is not found, then C<$value> is simply added.

If the field is found in C<$msg>, and its type does not match the type of
C<$field>, this method dies with a Tibco::Rv::INVALID_TYPE Status message.

=item $msg->update<type>Array( $fieldName, [ $val1, $val2, ... ], $fieldId )

   <type> can be:
      F32, F64, I8, I16, I32, I64, U8, U16, U32, U64,

Behaves the same as updateE<lt>typeE<gt>, except that it takes an array
reference of values instead of a single value.

=item $msg->markReferences

See TIB/Rendezvous documentation for discussion on what this method does.

=item $msg->clearReferences

See TIB/Rendezvous documentation for discussion on what this method does.

=back

=head1 MESSAGE TYPE CONSTANTS

=over 4

=item Tibco::Rv::Msg::MSG => 1


=item Tibco::Rv::Msg::DATETIME => 3

=item Tibco::Rv::Msg::OPAQUE => 7

=item Tibco::Rv::Msg::STRING => 8

=item Tibco::Rv::Msg::BOOL => 9

=item Tibco::Rv::Msg::I8 => 14

=item Tibco::Rv::Msg::U8 => 15

=item Tibco::Rv::Msg::I16 => 16

=item Tibco::Rv::Msg::U16 => 17

=item Tibco::Rv::Msg::I32 => 18

=item Tibco::Rv::Msg::U32 => 19

=item Tibco::Rv::Msg::I64 => 20

=item Tibco::Rv::Msg::U64 => 21

=item Tibco::Rv::Msg::F32 => 24

=item Tibco::Rv::Msg::F64 => 25

=item Tibco::Rv::Msg::IPPORT16 => 26

=item Tibco::Rv::Msg::IPADDR32 => 27

=item Tibco::Rv::Msg::ENCRYPTED => 32

=item Tibco::Rv::Msg::NONE => 22

=item Tibco::Rv::Msg::I8ARRAY => 34

=item Tibco::Rv::Msg::U8ARRAY => 35

=item Tibco::Rv::Msg::I16ARRAY => 36

=item Tibco::Rv::Msg::U16ARRAY => 37

=item Tibco::Rv::Msg::I32ARRAY => 38

=item Tibco::Rv::Msg::U32ARRAY => 39

=item Tibco::Rv::Msg::I64ARRAY => 40

=item Tibco::Rv::Msg::U64ARRAY => 41

=item Tibco::Rv::Msg::F32ARRAY => 44

=item Tibco::Rv::Msg::F64ARRAY => 45

=item Tibco::Rv::Msg::XML => 47

=back

=head1 OTHER CONSTANTS

=over 4

=item Tibco::Rv::Msg::FIELDNAME_MAX => 127

Maximum length of a field name

=back

=head1 SEE ALSO

=over 4

=item L<Tibco::Rv::Msg::Field>

=item L<Tibco::Rv::Msg::DateTime>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut


__DATA__
__C__


tibrv_status tibrvMsg_SetSendSubject( tibrvMsg message, const char * subject );
tibrv_status tibrvMsg_SetReplySubject( tibrvMsg message, const char * subject );
tibrv_status tibrvMsg_Expand( tibrvMsg message, tibrv_i32 additionalStorage );
tibrv_status tibrvMsg_Reset( tibrvMsg message );
tibrv_status tibrvMsg_AddField( tibrvMsg message, tibrvMsgField * field );
tibrv_status tibrvMsg_ClearReferences( tibrvMsg message );
tibrv_status tibrvMsg_MarkReferences( tibrvMsg message );
tibrv_status tibrvMsg_RemoveFieldEx( tibrvMsg message, const char * fieldName,
   tibrv_u16 fieldId );
tibrv_status tibrvMsg_RemoveFieldInstance( tibrvMsg message,
   const char * fieldName, tibrv_u32 instance );
tibrv_status tibrvMsg_UpdateField( tibrvMsg message, tibrvMsgField * field );
tibrv_status tibrvMsg_Destroy( tibrvMsg message );
tibrv_status tibrvMsg_AddBoolEx( tibrvMsg message, const char * fieldName,
   tibrv_bool value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddF32Ex( tibrvMsg message, const char * fieldName,
   tibrv_f32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddF64Ex( tibrvMsg message, const char * fieldName,
   tibrv_f64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI8Ex( tibrvMsg message, const char * fieldName,
   tibrv_i8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI16Ex( tibrvMsg message, const char * fieldName,
   tibrv_i16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI32Ex( tibrvMsg message, const char * fieldName,
   tibrv_i32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI64Ex( tibrvMsg message, const char * fieldName,
   tibrv_i64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU8Ex( tibrvMsg message, const char * fieldName,
   tibrv_u8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU16Ex( tibrvMsg message, const char * fieldName,
   tibrv_u16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU32Ex( tibrvMsg message, const char * fieldName,
   tibrv_u32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU64Ex( tibrvMsg message, const char * fieldName,
   tibrv_u64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddStringEx( tibrvMsg message, const char * fieldName,
   const char * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddMsgEx( tibrvMsg message, const char * fieldName,
   tibrvMsg value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddDateTimeEx( tibrvMsg message, const char * fieldName,
   const tibrvMsgDateTime * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateBoolEx( tibrvMsg message, const char * fieldName,
   tibrv_bool value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateF32Ex( tibrvMsg message, const char * fieldName,
   tibrv_f32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateF64Ex( tibrvMsg message, const char * fieldName,
   tibrv_f64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI8Ex( tibrvMsg message, const char * fieldName,
   tibrv_i8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI16Ex( tibrvMsg message, const char * fieldName,
   tibrv_i16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI32Ex( tibrvMsg message, const char * fieldName,
   tibrv_i32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI64Ex( tibrvMsg message, const char * fieldName,
   tibrv_i64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU8Ex( tibrvMsg message, const char * fieldName,
   tibrv_u8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU16Ex( tibrvMsg message, const char * fieldName,
   tibrv_u16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU32Ex( tibrvMsg message, const char * fieldName,
   tibrv_u32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU64Ex( tibrvMsg message, const char * fieldName,
   tibrv_u64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateStringEx( tibrvMsg message, const char * fieldName,
   const char * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateMsgEx( tibrvMsg message, const char * fieldName,
   tibrvMsg value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateDateTimeEx( tibrvMsg message,
   const char * fieldName, const tibrvMsgDateTime * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_SetCMTimeLimit( tibrvMsg message, tibrv_f64 timeLimit );


tibrv_status Msg_Create( SV * sv_message )
{
   tibrvMsg message = (tibrvMsg)NULL;
   tibrv_status status = tibrvMsg_Create( &message );
   sv_setiv( sv_message, (IV)message );
   return status;
}


void Msg_GetValues( tibrvMsg message, SV * sv_sendSubject,
   SV * sv_replySubject )
{
   const char * sendSubject = NULL;
   const char * replySubject = NULL;
   tibrvMsg_GetSendSubject( message, &sendSubject );
   tibrvMsg_GetReplySubject( message, &replySubject );
   sv_setpv( sv_sendSubject, sendSubject );
   sv_setpv( sv_replySubject, replySubject );
}


tibrv_status Msg_CreateCopy( tibrvMsg message, SV * sv_copy )
{
   tibrvMsg copy;
   tibrv_status status = tibrvMsg_CreateCopy( message, &copy );
   sv_setiv( sv_copy, (IV)copy );
   return status;
}


tibrv_status Msg_GetField( tibrvMsg message, const char * fieldName,
   SV * sv_field, tibrv_u16 fieldId )
{
   tibrv_status status;
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;
   status = tibrvMsg_GetFieldEx( message, fieldName, field, fieldId );
   sv_setiv( sv_field, (IV)field );
   return status;
}


tibrv_status Msg_GetScalar( tibrvMsg message, tibrv_u8 type,
   const char * fieldName, SV * sv_value, tibrv_u16 fieldId )
{
   tibrv_status status;

   switch ( type )
   {
      case TIBRVMSG_BOOL: {
         tibrv_bool boolean;
         status = tibrvMsg_GetBoolEx( message, fieldName, &boolean, fieldId );
         sv_setiv( sv_value, (IV)boolean );
      } break;
      case TIBRVMSG_F32: {
         tibrv_f32 f32;
         status = tibrvMsg_GetF32Ex( message, fieldName, &f32, fieldId );
         sv_setnv( sv_value, f32 );
      } break;
      case TIBRVMSG_F64: {
         tibrv_f64 f64;
         status = tibrvMsg_GetF64Ex( message, fieldName, &f64, fieldId );
         sv_setnv( sv_value, f64 );
      } break;
      case TIBRVMSG_I8: {
         tibrv_i8 i8;
         status = tibrvMsg_GetI8Ex( message, fieldName, &i8, fieldId );
         sv_setiv( sv_value, (IV)i8 );
      } break;
      case TIBRVMSG_I16: {
         tibrv_i16 i16;
         status = tibrvMsg_GetI16Ex( message, fieldName, &i16, fieldId );
         sv_setiv( sv_value, (IV)i16 );
      } break;
      case TIBRVMSG_I32: {
         tibrv_i32 i32;
         status = tibrvMsg_GetI32Ex( message, fieldName, &i32, fieldId );
         sv_setiv( sv_value, (IV)i32 );
      } break;
      case TIBRVMSG_I64: {
         tibrv_i64 i64;
         status = tibrvMsg_GetI64Ex( message, fieldName, &i64, fieldId );
         sv_setiv( sv_value, (IV)i64 );
      } break;
      case TIBRVMSG_U8: {
         tibrv_u8 u8;
         status = tibrvMsg_GetU8Ex( message, fieldName, &u8, fieldId );
         sv_setuv( sv_value, (UV)u8 );
      } break;
      case TIBRVMSG_U16: {
         tibrv_u16 u16;
         status = tibrvMsg_GetU16Ex( message, fieldName, &u16, fieldId );
         sv_setuv( sv_value, (UV)u16 );
      } break;
      case TIBRVMSG_U32: {
         tibrv_u32 u32;
         status = tibrvMsg_GetU32Ex( message, fieldName, &u32, fieldId );
         sv_setuv( sv_value, (UV)u32 );
      } break;
      case TIBRVMSG_U64: {
         tibrv_u64 u64;
         status = tibrvMsg_GetU64Ex( message, fieldName, &u64, fieldId );
         sv_setuv( sv_value, (UV)u64 );
      } break;
      case TIBRVMSG_IPADDR32: {
         tibrv_ipaddr32 ipaddr32;
         status =
            tibrvMsg_GetIPAddr32Ex( message, fieldName, &ipaddr32, fieldId );
         sv_setuv( sv_value, (UV)ntohl( ipaddr32 ) );
      } break;
      case TIBRVMSG_IPPORT16: {
         tibrv_ipport16 ipport16;
         status =
            tibrvMsg_GetIPPort16Ex( message, fieldName, &ipport16, fieldId );
         sv_setuv( sv_value, (UV)ntohs( ipport16 ) );
      } break;
      case TIBRVMSG_STRING: {
         const char * str;
         status = tibrvMsg_GetStringEx( message, fieldName, &str, fieldId );
         sv_setpv( sv_value, str );
      } break;
      case TIBRVMSG_OPAQUE: {
         const void * opaque;
         tibrv_u32 len;
         status =
            tibrvMsg_GetOpaqueEx( message, fieldName, &opaque, &len, fieldId );
         sv_setpvn( sv_value, (char *)opaque, len );
      } break;
      case TIBRVMSG_XML: {
         const void * xml;
         tibrv_u32 len;
         status = tibrvMsg_GetXmlEx( message, fieldName, &xml, &len, fieldId );
         sv_setpvn( sv_value, (char *)xml, len );
      } break;
      case TIBRVMSG_MSG: {
         tibrvMsg msg = (tibrvMsg)NULL;
         status = tibrvMsg_GetMsgEx( message, fieldName, &msg, fieldId );
         sv_setiv( sv_value, (IV)msg );
      } break;
      case TIBRVMSG_DATETIME: {
         tibrvMsgDateTime * date =
            (tibrvMsgDateTime *)malloc( sizeof( tibrvMsgDateTime ) );
         if ( date == NULL ) return TIBRV_NO_MEMORY;
         status = tibrvMsg_GetDateTimeEx( message, fieldName, date, fieldId );
         sv_setiv( sv_value, (IV)date );
      } break;
   }

   return status;
}


tibrv_status Msg_GetArray( tibrvMsg message, tibrv_u8 type, const char * name,
   SV * elts, tibrv_u16 id )
{
   int i = 0;
   tibrv_status status = TIBRV_OK;
   tibrv_u32 n = 0;
   AV * e = (AV *)SvRV( elts );

   switch ( type )
   {
      case TIBRVMSG_F32ARRAY: {
         const tibrv_f32 * f32s;
         status = tibrvMsg_GetF32ArrayEx( message, name, &f32s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSVnv( f32s[ i ] ) );
      } break;
      case TIBRVMSG_F64ARRAY: {
         const tibrv_f64 * f64s;
         status = tibrvMsg_GetF64ArrayEx( message, name, &f64s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSVnv( f64s[ i ] ) );
      } break;
      case TIBRVMSG_I8ARRAY: {
         const tibrv_i8 * i8s;
         status = tibrvMsg_GetI8ArrayEx( message, name, &i8s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i8s[ i ] ) );
      } break;
      case TIBRVMSG_I16ARRAY: {
         const tibrv_i16 * i16s;
         status = tibrvMsg_GetI16ArrayEx( message, name, &i16s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i16s[ i ] ) );
      } break;
      case TIBRVMSG_I32ARRAY: {
         const tibrv_i32 * i32s;
         status = tibrvMsg_GetI32ArrayEx( message, name, &i32s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i32s[ i ] ) );
      } break;
      case TIBRVMSG_I64ARRAY: {
         const tibrv_i64 * i64s;
         status = tibrvMsg_GetI64ArrayEx( message, name, &i64s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i64s[ i ] ) );
      } break;
      case TIBRVMSG_U8ARRAY: {
         const tibrv_u8 * u8s;
         status = tibrvMsg_GetU8ArrayEx( message, name, &u8s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u8s[ i ] ) );
      } break;
      case TIBRVMSG_U16ARRAY: {
         const tibrv_u16 * u16s;
         status = tibrvMsg_GetU16ArrayEx( message, name, &u16s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u16s[ i ] ) );
      } break;
      case TIBRVMSG_U32ARRAY: {
         const tibrv_u32 * u32s;
         status = tibrvMsg_GetU32ArrayEx( message, name, &u32s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u32s[ i ] ) );
      } break;
      case TIBRVMSG_U64ARRAY: {
         const tibrv_u64 * u64s;
         status = tibrvMsg_GetU64ArrayEx( message, name, &u64s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u64s[ i ] ) );
      } break;
   }

   return status;
}



tibrv_status Msg_GetFieldByIndex( tibrvMsg message, SV * sv_field,
   tibrv_u32 fieldIndex )
{
   tibrv_status status;
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;
   status = tibrvMsg_GetFieldByIndex( message, field, fieldIndex );
   sv_setiv( sv_field, (IV)field );
   return status;
}


tibrv_status Msg_GetFieldInstance( tibrvMsg message, const char * fieldName,
   SV * sv_field, tibrv_u32 instance )
{
   tibrv_status status;
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;
   status = tibrvMsg_GetFieldInstance( message, fieldName, field, instance );
   sv_setiv( sv_field, (IV)field );
   return status;
}


tibrv_status Msg_CreateFromBytes( SV * sv_message, SV * sv_bytes )
{
   tibrvMsg message = (tibrvMsg)NULL;
   const void * bytes = SvPV( sv_bytes, PL_na );
   tibrv_status status = tibrvMsg_CreateFromBytes( &message, bytes );
   sv_setiv( sv_message, (IV)message );
   return status;
}


tibrv_status Msg_GetAsBytes( tibrvMsg message, SV * sv_bytes )
{
   tibrv_u32 byteSize;
   const void * bytes;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   if ( status != TIBRV_OK ) return status;
   status = tibrvMsg_GetAsBytes( message, &bytes );
   if ( status != TIBRV_OK ) return status;
   sv_setpvn( sv_bytes, (char *)bytes, byteSize );
   return status;
}


tibrv_status Msg_GetAsBytesCopy( tibrvMsg message, SV * sv_bytes )
{
   void * bytes;
   tibrv_u32 byteSize;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   bytes = malloc( byteSize );
   if ( bytes == NULL ) return TIBRV_NO_MEMORY;
   if ( status != TIBRV_OK ) return status;
   status = tibrvMsg_GetAsBytesCopy( message, bytes, byteSize );
   if ( status != TIBRV_OK ) return status;
   sv_setpvn( sv_bytes, (char *)bytes, byteSize );
   free( bytes );
   return status;
}


tibrv_status Msg_GetNumFields( tibrvMsg message, SV * sv_numFields )
{
   tibrv_u32 numFields;
   tibrv_status status = tibrvMsg_GetNumFields( message, &numFields );
   sv_setuv( sv_numFields, (UV)numFields );
   return status;
}


tibrv_status Msg_GetByteSize( tibrvMsg message, SV * sv_byteSize )
{
   tibrv_u32 byteSize;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   sv_setuv( sv_byteSize, (UV)byteSize );
   return status;
}


tibrv_status Msg_ConvertToString( tibrvMsg message, SV * sv_str )
{
   const char * str;
   tibrv_status status = tibrvMsg_ConvertToString( message, &str );
   sv_setpv( sv_str, str );
   return status;
}


tibrv_status Msg_AddIPAddr32( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId )
{
   return tibrvMsg_AddIPAddr32Ex( message, fieldName, htonl( value ), fieldId );
}


tibrv_status Msg_AddIPPort16( tibrvMsg message, const char * fieldName,
   tibrv_ipport16 value, tibrv_u16 fieldId )
{
   return tibrvMsg_AddIPPort16Ex( message, fieldName, htons( value ), fieldId );
}


tibrv_status Msg_AddOpaque( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_AddOpaqueEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_AddXml( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_AddXmlEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_AddOrUpdateArray( tibrvMsg message, tibrv_bool isAdd,
   tibrv_u8 type, const char * fieldName, SV * elts, tibrv_u16 fieldId )
{
   tibrv_status status = TIBRV_OK;
   I32 len;
   AV * e;
   int i;
   if ( SvTYPE( SvRV( elts ) ) != SVt_PVAV ) return TIBRV_INVALID_ARG;
   e = (AV *)SvRV( elts );

   len = av_len( e ) + 1;
   if ( len == 0 ) return TIBRV_OK;
   switch ( type )
   {
      case TIBRVMSG_F32ARRAY: {
         tibrv_f32 f32s[ len ];
         for ( i = 0; i < len; i ++ ) f32s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddF32ArrayEx( message, fieldName, f32s, len, fieldId ) :
            tibrvMsg_UpdateF32ArrayEx( message, fieldName, f32s, len, fieldId );
      } break;
      case TIBRVMSG_F64ARRAY: {
         tibrv_f64 f64s[ len ];
         for ( i = 0; i < len; i ++ ) f64s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddF64ArrayEx( message, fieldName, f64s, len, fieldId ) :
            tibrvMsg_UpdateF64ArrayEx( message, fieldName, f64s, len, fieldId );
      } break;
      case TIBRVMSG_I8ARRAY: {
         tibrv_i8 i8s[ len ];
         for ( i = 0; i < len; i ++ ) i8s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI8ArrayEx( message, fieldName, i8s, len, fieldId ) :
            tibrvMsg_UpdateI8ArrayEx( message, fieldName, i8s, len, fieldId );
      } break;
      case TIBRVMSG_I16ARRAY: {
         tibrv_i16 i16s[ len ];
         for ( i = 0; i < len; i ++ ) i16s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI16ArrayEx( message, fieldName, i16s, len, fieldId ) :
            tibrvMsg_UpdateI16ArrayEx( message, fieldName, i16s, len, fieldId );
      } break;
      case TIBRVMSG_I32ARRAY: {
         tibrv_i32 i32s[ len ];
         for ( i = 0; i < len; i ++ ) i32s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI32ArrayEx( message, fieldName, i32s, len, fieldId ) :
            tibrvMsg_UpdateI32ArrayEx( message, fieldName, i32s, len, fieldId );
      } break;
      case TIBRVMSG_I64ARRAY: {
         tibrv_i64 i64s[ len ];
         for ( i = 0; i < len; i ++ ) i64s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI64ArrayEx( message, fieldName, i64s, len, fieldId ) :
            tibrvMsg_UpdateI64ArrayEx( message, fieldName, i64s, len, fieldId );
      } break;
      case TIBRVMSG_U8ARRAY: {
         tibrv_u8 u8s[ len ];
         for ( i = 0; i < len; i ++ ) u8s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU8ArrayEx( message, fieldName, u8s, len, fieldId ) :
            tibrvMsg_UpdateU8ArrayEx( message, fieldName, u8s, len, fieldId );
      } break;
      case TIBRVMSG_U16ARRAY: {
         tibrv_u16 u16s[ len ];
         for ( i = 0; i < len; i ++ ) u16s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU16ArrayEx( message, fieldName, u16s, len, fieldId ) :
            tibrvMsg_UpdateU16ArrayEx( message, fieldName, u16s, len, fieldId );
      } break;
      case TIBRVMSG_U32ARRAY: {
         tibrv_u32 u32s[ len ];
         for ( i = 0; i < len; i ++ ) u32s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU32ArrayEx( message, fieldName, u32s, len, fieldId ) :
            tibrvMsg_UpdateU32ArrayEx( message, fieldName, u32s, len, fieldId );
      } break;
      case TIBRVMSG_U64ARRAY: {
         tibrv_u64 u64s[ len ];
         for ( i = 0; i < len; i ++ ) u64s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU64ArrayEx( message, fieldName, u64s, len, fieldId ) :
            tibrvMsg_UpdateU64ArrayEx( message, fieldName, u64s, len, fieldId );
      } break;
   }

   return status;
}


tibrv_status Msg_UpdateOpaque( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_UpdateOpaqueEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_UpdateXml( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_UpdateXmlEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_UpdateIPAddr32( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId )
{
   return
      tibrvMsg_UpdateIPAddr32Ex( message, fieldName, htonl( value ), fieldId );
}


tibrv_status Msg_UpdateIPPort16( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId )
{
   return
      tibrvMsg_UpdateIPPort16Ex( message, fieldName, htons( value ), fieldId );
}


tibrv_status MsgDateTime_Create( SV * sv_date, tibrv_i64 sec, tibrv_u32 nsec )
{
   tibrvMsgDateTime * date =
      (tibrvMsgDateTime *)malloc( sizeof( tibrvMsgDateTime ) );
   if ( date == NULL ) return TIBRV_NO_MEMORY;
   date->sec = sec;
   date->nsec = nsec;
   sv_setiv( sv_date, (IV)date );
   return TIBRV_OK;
}




tibrv_status MsgField_Create( SV * sv_field, const char * name, tibrv_u16 id )
{
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;

   field->name = name;
   field->id = id;

   sv_setiv( sv_field, (IV)field );
   return TIBRV_OK;
}


void MsgField_GetArrayValue( tibrvMsgField * field, SV * sv_data )
{
   int i;
   AV * e = newAV( );
   av_extend( e, field->count );

   switch ( field->type )
   {
      case TIBRVMSG_F32ARRAY: {
         tibrv_f32 * f32s = (tibrv_f32 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSVnv( f32s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_F64ARRAY: {
         tibrv_f64 * f64s = (tibrv_f64 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSVnv( f64s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I8ARRAY: {
         tibrv_i8 * i8s = (tibrv_i8 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i8s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I16ARRAY: {
         tibrv_i16 * i16s = (tibrv_i16 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i16s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I32ARRAY: {
         tibrv_i32 * i32s = (tibrv_i32 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i32s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I64ARRAY: {
         tibrv_i64 * i64s = (tibrv_i64 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i64s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U8ARRAY: {
         tibrv_u8 * u8s = (tibrv_u8 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u8s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U16ARRAY: {
         tibrv_u16 * u16s = (tibrv_u16 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u16s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U32ARRAY: {
         tibrv_u32 * u32s = (tibrv_u32 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u32s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U64ARRAY: {
         tibrv_u64 * u64s = (tibrv_u64 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u64s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
   }
   sv_setsv( sv_data, newRV( (SV *)e ) );
}


void MsgField_GetValues( tibrvMsgField * field, SV * sv_name, SV * sv_id,
   SV * sv_size, SV * sv_count, SV * sv_type, SV * sv_data )
{
   switch ( field->type )
   {
      case TIBRVMSG_MSG: sv_setiv( sv_data, (IV)field->data.msg );
      break;
      case TIBRVMSG_STRING: sv_setpvn( sv_data, field->data.str, field->size );
      break;
      case TIBRVMSG_OPAQUE:
      case TIBRVMSG_XML:
         sv_setpvn( sv_data, field->data.buf, field->size );
      break;
      case TIBRVMSG_I8ARRAY:
      case TIBRVMSG_U8ARRAY:
      case TIBRVMSG_I16ARRAY:
      case TIBRVMSG_U16ARRAY:
      case TIBRVMSG_I32ARRAY:
      case TIBRVMSG_U32ARRAY:
      case TIBRVMSG_I64ARRAY:
      case TIBRVMSG_U64ARRAY:
      case TIBRVMSG_F32ARRAY:
      case TIBRVMSG_F64ARRAY: {
         size_t len = field->size * field->count;
         void * array = malloc( len );
         if ( array == NULL )
         {
            field->size = field->count = 0;
            break;
         }
         field->data.array = memcpy( array, field->data.array, len );
         MsgField_GetArrayValue( field, sv_data );
      } break;
      case TIBRVMSG_BOOL: sv_setiv( sv_data, (IV)field->data.boolean ); break;
      case TIBRVMSG_I8: sv_setiv( sv_data, (IV)field->data.i8 ); break;
      case TIBRVMSG_U8: sv_setuv( sv_data, (UV)field->data.u8 ); break;
      case TIBRVMSG_I16: sv_setiv( sv_data, (IV)field->data.i16 ); break;
      case TIBRVMSG_U16: sv_setuv( sv_data, (UV)field->data.u16 ); break;
      case TIBRVMSG_I32: sv_setiv( sv_data, (IV)field->data.i32 ); break;
      case TIBRVMSG_U32: sv_setuv( sv_data, (UV)field->data.u32 ); break;
      case TIBRVMSG_I64: sv_setiv( sv_data, (IV)field->data.i64 ); break;
      case TIBRVMSG_U64: sv_setuv( sv_data, (UV)field->data.u64 ); break;
      case TIBRVMSG_F32: sv_setnv( sv_data, field->data.f32 ); break;
      case TIBRVMSG_F64: sv_setnv( sv_data, field->data.f64 ); break;
      case TIBRVMSG_IPPORT16:
         sv_setuv( sv_data, (UV)ntohs( field->data.ipport16 ) );
      break;
      case TIBRVMSG_IPADDR32:
         sv_setuv( sv_data, (UV)ntohl( field->data.ipaddr32 ) );
      break;
      case TIBRVMSG_DATETIME:
         MsgDateTime_Create( sv_data, (IV)field->data.date.sec,
            (UV)field->data.date.nsec );
      break;
   }
   if ( ! field->name ) field->name = strdup( "" );
   sv_setpv( sv_name, field->name );
   sv_setuv( sv_id, (UV)field->id );
   sv_setuv( sv_size, (UV)field->size );
   sv_setuv( sv_count, (UV)field->count );
   sv_setuv( sv_type, (UV)field->type );
}


void MsgField_SetName( tibrvMsgField * field, const char * name )
{
   field->name = name;
}


void MsgField_SetId( tibrvMsgField * field, tibrv_u16 id )
{
   field->id = id;
}


void MsgField_CheckDelOldArray( tibrvMsgField * field )
{
   switch ( field->type )
   {
      case TIBRVMSG_F32ARRAY:
      case TIBRVMSG_F64ARRAY:
      case TIBRVMSG_I8ARRAY:
      case TIBRVMSG_I16ARRAY:
      case TIBRVMSG_I32ARRAY:
      case TIBRVMSG_I64ARRAY:
      case TIBRVMSG_U8ARRAY:
      case TIBRVMSG_U16ARRAY:
      case TIBRVMSG_U32ARRAY:
      case TIBRVMSG_U64ARRAY:
         free( (void *)field->data.array );
         field->data.array = NULL;
   }
}


tibrv_u32 MsgField_SetMsg( tibrvMsgField * field, tibrvMsg message )
{
   MsgField_CheckDelOldArray( field );
   field->data.msg = message;
   field->size = 0;
   tibrvMsg_GetByteSize( message, &field->size );
   field->count = 1;
   field->type = TIBRVMSG_MSG;

   return field->size;
}


tibrv_u32 MsgField_SetBuf( tibrvMsgField * field, tibrv_u8 type, SV * sv_buf )
{
   STRLEN len;
   char * buf = SvPV( sv_buf, len );
   MsgField_CheckDelOldArray( field );
   switch ( type )
   {
      case TIBRVMSG_STRING:
         SvGROW( sv_buf, len + 1 );
         buf[ len ] = '\0';
         len = strlen( buf ) + 1;
         field->data.str = buf;
      break;
      case TIBRVMSG_OPAQUE:
      case TIBRVMSG_XML:
         field->data.buf = buf;
      break;
   }
   field->count = 1;
   field->type = type;
   return field->size = len;
}


tibrv_u32 MsgField_SetElt( tibrvMsgField * field, tibrv_u8 type, SV * sv_elt )
{
   MsgField_CheckDelOldArray( field );
   field->count = 1;
   field->type = type;
   switch ( type )
   {
      case TIBRVMSG_BOOL: field->data.boolean = SvIV( sv_elt ); break;
      case TIBRVMSG_I8: field->data.i8 = SvIV( sv_elt ); break;
      case TIBRVMSG_U8: field->data.u8 = SvUV( sv_elt ); break;
      case TIBRVMSG_I16: field->data.i16 = SvIV( sv_elt ); break;
      case TIBRVMSG_U16: field->data.i16 = SvUV( sv_elt ); break;
      case TIBRVMSG_I32: field->data.i32 = SvIV( sv_elt ); break;
      case TIBRVMSG_U32: field->data.u32 = SvUV( sv_elt ); break;
      case TIBRVMSG_I64: field->data.i64 = SvIV( sv_elt ); break;
      case TIBRVMSG_U64: field->data.u64 = SvUV( sv_elt ); break;
      case TIBRVMSG_F32: field->data.f32 = SvNV( sv_elt ); break;
      case TIBRVMSG_F64: field->data.f64 = SvNV( sv_elt ); break;
      case TIBRVMSG_IPPORT16:
         field->data.ipport16 = htons( SvUV( sv_elt ) );
      break;
      case TIBRVMSG_IPADDR32:
         field->data.ipaddr32 = htonl( SvUV( sv_elt ) );
      break;
   }
   switch ( type )
   {
      case TIBRVMSG_BOOL:
         return field->size = sizeof( tibrv_bool );
      case TIBRVMSG_I8:
      case TIBRVMSG_U8:
         return field->size = 1;
      case TIBRVMSG_I16:
      case TIBRVMSG_U16:
      case TIBRVMSG_IPPORT16:
         return field->size = 2;
      case TIBRVMSG_I32:
      case TIBRVMSG_U32:
      case TIBRVMSG_F32:
      case TIBRVMSG_IPADDR32:
         return field->size = 4;
      case TIBRVMSG_I64:
      case TIBRVMSG_U64:
      case TIBRVMSG_F64:
         return field->size = 8;
   }
   return 0;
}


tibrv_u32 MsgField_SetAry( tibrvMsgField * field, tibrv_u8 type, SV * sv_ary )
{
   AV * e;
   I32 len = 0;
   int i;
   MsgField_CheckDelOldArray( field );

   if ( SvTYPE( SvRV( sv_ary ) ) != SVt_PVAV ) return 0;

   e = (AV *)SvRV( sv_ary );
   field->count = len = av_len( e ) + 1;
   field->type = type;
   field->size = 0;

   switch ( type )
   {
      case TIBRVMSG_F32ARRAY: {
         tibrv_f32 * f32s = (tibrv_f32 *)malloc( len * sizeof( tibrv_f32 ) );
         if ( f32s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) f32s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         field->data.array = f32s;
         field->size = sizeof( tibrv_f32 );
      } break;
      case TIBRVMSG_F64ARRAY: {
         tibrv_f64 * f64s = (tibrv_f64 *)malloc( len * sizeof( tibrv_f64 ) );
         if ( f64s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) f64s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         field->data.array = f64s;
         field->size = sizeof( tibrv_f64 );
      } break;
      case TIBRVMSG_I8ARRAY: {
         tibrv_i8 * i8s = (tibrv_i8 *)malloc( len * sizeof( tibrv_i8 ) );
         if ( i8s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i8s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i8s;
         field->size = sizeof( tibrv_i8 );
      } break;
      case TIBRVMSG_I16ARRAY: {
         tibrv_i16 * i16s = (tibrv_i16 *)malloc( len * sizeof( tibrv_i16 ) );
         if ( i16s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i16s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i16s;
         field->size = sizeof( tibrv_i16 );
      } break;
      case TIBRVMSG_I32ARRAY: {
         tibrv_i32 * i32s = (tibrv_i32 *)malloc( len * sizeof( tibrv_i32 ) );
         if ( i32s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i32s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i32s;
         field->size = sizeof( tibrv_i32 );
      } break;
      case TIBRVMSG_I64ARRAY: {
         tibrv_i64 * i64s = (tibrv_i64 *)malloc( len * sizeof( tibrv_i64 ) );
         if ( i64s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i64s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i64s;
         field->size = sizeof( tibrv_i64 );
      } break;
      case TIBRVMSG_U8ARRAY: {
         tibrv_u8 * u8s = (tibrv_u8 *)malloc( len * sizeof( tibrv_u8 ) );
         if ( u8s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u8s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u8s;
         field->size = sizeof( tibrv_u8 );
      } break;
      case TIBRVMSG_U16ARRAY: {
         tibrv_u16 * u16s = (tibrv_u16 *)malloc( len * sizeof( tibrv_u16 ) );
         if ( u16s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u16s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u16s;
         field->size = sizeof( tibrv_u16 );
      } break;
      case TIBRVMSG_U32ARRAY: {
         tibrv_u32 * u32s = (tibrv_u32 *)malloc( len * sizeof( tibrv_u32 ) );
         if ( u32s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u32s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u32s;
         field->size = sizeof( tibrv_u32 );
      } break;
      case TIBRVMSG_U64ARRAY: {
         tibrv_u64 * u64s = (tibrv_u64 *)malloc( len * sizeof( tibrv_u64 ) );
         if ( u64s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u64s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u64s;
         field->size = sizeof( tibrv_u64 );
      } break;
   }
   return field->size;
}


tibrv_u32 MsgField_SetDateTime( tibrvMsgField * field,
   tibrvMsgDateTime * date )
{
   MsgField_CheckDelOldArray( field );
   field->data.date.sec = date->sec;
   field->data.date.nsec = date->nsec;
   field->count = 1;
   field->type = TIBRVMSG_DATETIME;

   return field->size = sizeof( tibrvMsgDateTime );
}


tibrv_status MsgField_Destroy( tibrvMsgField * field )
{
   MsgField_CheckDelOldArray( field );
   free( field );
   return TIBRV_OK;
}


void MsgDateTime_GetValues( tibrvMsgDateTime * date, SV * sv_sec,
   SV * sv_nsec )
{
   sv_setiv( sv_sec, date->sec );
   sv_setuv( sv_nsec, date->nsec );
}


void MsgDateTime_SetSec( tibrvMsgDateTime * date, tibrv_i64 sec )
{
   date->sec = sec;
}


void MsgDateTime_SetNsec( tibrvMsgDateTime * date, tibrv_u32 nsec )
{
   date->nsec = nsec;
}


tibrv_status MsgDateTime_Destroy( tibrvMsgDateTime * date )
{
   free( date );
   return TIBRV_OK;
}


void Msg_GetCMValues( tibrvMsg message, SV * sv_CMSender, SV * sv_CMSequence,
   SV * sv_CMTimeLimit )
{
   const char * CMSender = NULL;
   tibrv_u64 CMSequence = 0;
   tibrv_f64 CMTimeLimit = 0.0;

   if ( tibrvMsg_GetCMSender( message, &CMSender ) == TIBRV_OK )
      sv_setpv( sv_CMSender, CMSender );
   if ( tibrvMsg_GetCMSequence( message, &CMSequence ) == TIBRV_OK )
      sv_setuv( sv_CMSequence, (UV)CMSequence );
   if ( tibrvMsg_GetCMTimeLimit( message, &CMTimeLimit ) == TIBRV_OK )
      sv_setnv( sv_CMTimeLimit, CMTimeLimit );
}
