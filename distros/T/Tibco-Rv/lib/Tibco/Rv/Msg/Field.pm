package Tibco::Rv::Msg::Field;


use vars qw/ $VERSION @CARP_NOT /;
$VERSION = '1.12';


use Tibco::Rv::Msg::DateTime;
@CARP_NOT = qw/ Tibco::Rv::Msg::DateTime /;


my ( %defaults );
BEGIN
{
   %defaults = ( name => '', id => 0,
      size => undef, count => undef, type => undef, data => undef );
}


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( name => '', id => 0 );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   $params{name} = '' unless ( defined $params{name} );
   @$self{ qw/ name id / } = @params{ qw/ name id / };

   my ( $status ) =
      Tibco::Rv::Msg::MsgField_Create( @$self{ qw/ ptr name id / } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   $self->bool( Tibco::Rv::FALSE );

   return $self;
}


sub _new
{
   my ( $class, $ptr ) = @_;
   return bless { ptr => $ptr, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $ptr ) = @_;
   my ( $self );
   my ( $class ) = ref( $proto );
   if ( $class )
   {
      $self = $proto;
      $self->DESTROY;
      @$self{ 'ptr', keys %defaults } = ( $ptr, values %defaults );
   } else {
      $self = bless $proto->_new( $ptr ), $proto;
   }
   $self->_getValues;
   return $self;
}


sub _getValues
{
   my ( $self ) = @_;
   Tibco::Rv::Msg::MsgField_GetValues(
      @$self{ qw/ ptr name id size count type data / } );
   if ( $self->{type} == Tibco::Rv::Msg::MSG )
   {
      $self->{data} = Tibco::Rv::Msg->_adopt( $self->{data} );
   } elsif ( $self->{type} == Tibco::Rv::Msg::DATETIME ) {
      $self->{data} = Tibco::Rv::Msg::DateTime->_adopt( $self->{data} );
   } elsif ( $self->{type} == Tibco::Rv::Msg::IPADDR32 ) {
      my ( $a, $b, $c, $d );
      my ( $ipaddr32 ) = $self->{data};
      $a = $ipaddr32; $a >>= 24; $ipaddr32 -= $a << 24;
      $b = $ipaddr32; $b >>= 16; $ipaddr32 -= $b << 16;
      $c = $ipaddr32; $c >>= 8; $ipaddr32 -= $c << 8;
      $d = $ipaddr32;
      $self->{data} = "$a.$b.$c.$d";
   }
}


sub name
{
   my ( $self ) = shift;
   return @_ ? $self->_setName( @_ ) : $self->{name};
}


sub _setName
{
   my ( $self, $name ) = @_;
   $name = '' unless ( defined $name );
   Tibco::Rv::Msg::MsgField_SetName( $self->{ptr}, $name );
   return $self->{name} = $name;
}


sub id
{
   my ( $self ) = shift;
   return @_ ? $self->_setId( @_ ) : $self->{id};
}


sub _setId
{
   my ( $self, $id ) = @_;
   Tibco::Rv::Msg::MsgField_SetId( $self->{ptr}, $id );
   return $self->{id} = $id;
}


sub count { return shift->{count} }
sub size { return shift->{size} }
sub type { return shift->{type} }


sub msg
{
   my ( $self ) = shift;
   return @_ ? $self->_setMsg( @_ ) : $self->_get( Tibco::Rv::Msg::MSG );
}


sub str { return shift->_bufAccessor( Tibco::Rv::Msg::STRING, @_ ) }
sub opaque { return shift->_bufAccessor( Tibco::Rv::Msg::OPAQUE, @_ ) }
sub xml { return shift->_bufAccessor( Tibco::Rv::Msg::XML, @_ ) }

sub bool { return shift->_eltAccessor( Tibco::Rv::Msg::BOOL, @_ ) }
sub i8 { return shift->_eltAccessor( Tibco::Rv::Msg::I8, @_ ) }
sub u8 { return shift->_eltAccessor( Tibco::Rv::Msg::U8, @_ ) }
sub i16 { return shift->_eltAccessor( Tibco::Rv::Msg::I16, @_ ) }
sub u16 { return shift->_eltAccessor( Tibco::Rv::Msg::U16, @_ ) }
sub i32 { return shift->_eltAccessor( Tibco::Rv::Msg::I32, @_ ) }
sub u32 { return shift->_eltAccessor( Tibco::Rv::Msg::U32, @_ ) }
sub i64 { return shift->_eltAccessor( Tibco::Rv::Msg::I64, @_ ) }
sub u64 { return shift->_eltAccessor( Tibco::Rv::Msg::U64, @_ ) }
sub f32 { return shift->_eltAccessor( Tibco::Rv::Msg::F32, @_ ) }
sub f64 { return shift->_eltAccessor( Tibco::Rv::Msg::F64, @_ ) }
sub ipport16 { return shift->_eltAccessor( Tibco::Rv::Msg::IPPORT16, @_ ) }


sub ipaddr32
{
   my ( $self ) = shift;
   return @_ ? $self->_setIPAddr32( @_ )
      : $self->_get( Tibco::Rv::Msg::IPADDR32, $ipaddr32 );
}


sub date
{
   my ( $self ) = shift;
   return @_ ? $self->_setDate( @_ ) : $self->_get( Tibco::Rv::Msg::DATETIME );
}


sub i8array { return shift->_aryAccessor( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub u8array { return shift->_aryAccessor( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub i16array { return shift->_aryAccessor( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub u16array { return shift->_aryAccessor( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub i32array { return shift->_aryAccessor( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub u32array { return shift->_aryAccessor( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub i64array { return shift->_aryAccessor( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub u64array { return shift->_aryAccessor( Tibco::Rv::Msg::U64ARRAY, @_ ) }
sub f32array { return shift->_aryAccessor( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub f64array { return shift->_aryAccessor( Tibco::Rv::Msg::F64ARRAY, @_ ) }


sub _bufAccessor
{
   my ( $self ) = shift;
   my ( $type ) = shift;
   return @_ ? $self->_setBuf( $type, @_ ) : $self->_get( $type );
}


sub _eltAccessor
{
   my ( $self ) = shift;
   my ( $type ) = shift;
   return @_ ? $self->_setElt( $type, @_ ) : $self->_get( $type );
}


sub _aryAccessor
{
   my ( $self ) = shift;
   my ( $type ) = shift;
   return @_ ? $self->_setAry( $type, @_ ) : $self->_get( $type );
}


sub _setIPAddr32
{
   my ( $self, $ipaddr32 ) = @_;
   @$self{ qw/ data type count / } = ( $ipaddr32, Tibco::Rv::Msg::IPADDR32, 1 );
   my ( $a, $b, $c, $d ) = split( /\./, $ipaddr32 );
   $ipaddr32 = $d + ( $c << 8 ) + ( $b << 16 ) + ( $a << 24 );
   $self->{size} =
      Tibco::Rv::Msg::MsgField_SetElt( @$self{ qw/ ptr type / }, $ipaddr32 );
   return $self->{data};
}


sub _setDate
{
   my ( $self, $date ) = @_;
   @$self{ qw/ data type count / } = ( $date, Tibco::Rv::Msg::DATETIME, 1 );
   $self->{size} =
      Tibco::Rv::Msg::MsgField_SetDateTime( $self->{ptr}, $self->{data}{ptr} );
   return $self->{data};
}


sub _get
{
   my ( $self, $type ) = @_;
   Tibco::Rv::die( Tibco::Rv::ARG_CONFLICT ) unless ( $self->{type} == $type );
   return $self->{data};
}


sub _setMsg
{
   my ( $self, $msg ) = @_;
   @$self{ qw/ data type count / } = ( $msg, Tibco::Rv::Msg::MSG, 1 );
   $self->{size} =
      Tibco::Rv::Msg::MsgField_SetMsg( $self->{ptr}, $self->{data}{id} );
   return $self->{data};
}


sub _setBuf
{
   my ( $self, $type, $buf ) = @_;
   @$self{ qw/ data type count / } = ( $buf, $type, 1 );
   $self->{size} =
      Tibco::Rv::Msg::MsgField_SetBuf( $self->{ptr}, $type, $self->{data} );
   $self->{data} = substr( $self->{data}, 0, $self->{size} - 1 )
      if ( $type == Tibco::Rv::Msg::STRING );
   return $self->{data};
}


sub _setElt
{
   my ( $self, $type, $elt ) = @_;
   @$self{ qw/ data type count / } = ( $elt, $type, 1 );
   $self->{size} =
      Tibco::Rv::Msg::MsgField_SetElt( @$self{ qw/ ptr type data / } );
   return $self->{data};
}


sub _setAry
{
   my ( $self, $type, $ary ) = @_;
   $ary = [ ] unless ( ref( $ary ) eq 'ARRAY' );
   @$self{ qw/ data type count / } = ( $ary, $type, $#$ary + 1 );
   $self->{size} =
      Tibco::Rv::Msg::MsgField_SetAry( @$self{ qw/ ptr type data / } );
   return $self->{data};
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{ptr} );

   my ( $status ) = Tibco::Rv::Msg::MsgField_Destroy( $self->{ptr} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Msg::Field - Manipulate a Tibco message field

=head1 SYNOPSIS

   my ( $field ) = $msg->createField( name => 'myField' );
   $field->i8( 123 );
   $field->opaque( "abc\0abc" );
   $field->ipaddr32( '66.35.250.150' );
   $field->u64array( [ 1, 123, 3030 ] );
   print "U64Array\n" if ( $field->type == Tibco::Rv::Msg::U64ARRAY );
   print "Count: ", $field->count, "; size: ", $field->size, "\n";

=head1 DESCRIPTION

Message Field-manipulating class.  Holds a single value, like a C enum,
along with a name and an id.

=head1 CONSTRUCTOR

=over 4

=item $field = new Tibco::Rv::Msg::Field( %args )

   %args:
      name => $name,
      id => $id

Creates a C<Tibco::Rv::Msg::Field>, with name and id as given in %args
(name defaults '' and id defaults to 0, if not specified).
C<$field> is initialized with boolean value C<Tibco::Rv::FALSE>.

=back

=head1 METHODS

=over 4

=item $name = $field->name

Returns C<$field>'s name.

=item $field->name( $name )

Sets C<$field>'s name to C<$name>.  If C<$name> is C<undef>, sets name to ''.

=item $id = $field->id

Returns C<$field>'s id.

=item $field->id( $id )

Sets C<$field>'s id.

=item $count = $field->count

Returns C<$field>'s count.  For array types, C<$count> is the number of
elements in the array.  For all other types, C<$count> is 1.

=item $size = $field->size

Returns C<$field>'s size.  For array types, C<$size> is the size in bytes 
of one element of the array.  For all other types, C<$size> is the size in
bytes of the data (for strings, this includes the NULL terminator, and for
xml or opaque fields, this is the total number of bytes).

=item $type = $field->type

Returns the
L<Tibco::Rv::Msg Message Type Constant|Tibco::Rv::Msg/"MESSAGE TYPE CONSTANTS">
representing the type of data contained in the field.

=item $value = $field-><type>

Gets the C<$value> currently held in C<$field>.  Dies with a
Tibco::Rv::ARG_CONFLICT Status message if E<lt>typeE<gt> does not match
the type of data currently held by C<$field>.

=item $field-><type>( $value )

   <type> can be:
      bool, str, opaque, xml,
      f32, f64, i8, i16, i32, i64, u8, u16, u32, u64,
      ipaddr32, ipport16, date, or msg

Sets the value of C<$field> to C<$value>, changing C<$field> to type
E<lt>typeE<gt> if it is not already.

=item $valueAryRef = $field-><type>array

Same as E<lt>typeE<gt>, except it returns an array reference of values.

=item $field-><type>array( [ $val1, $val2, ... ] )

   <type> can be:
      f32, f64, i8, i16, i32, i64, u8, u16, u32, u64

Some as E<lt>typeE<gt>, except it must be given an array reference of values.

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
