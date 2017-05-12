package t::MockXMLSAXConsumer;

use strict;

sub new
{
   my $class = shift;
   return bless [], $class;
}

sub GET_LOG
{
   my $self = shift;

   my @log = @$self;
   @$self = ();
   return @log;
}

# Package variables so that test scripts can append to them
our @IGNORE = qw( 
   set_document_locator
   start_document
   xml_decl
   end_document
);
our @CAPTURE = qw(
   start_element
   end_element
   start_prefix_mapping
   end_prefix_mapping
   comment
   processing_instruction
);

sub characters
{
   my $self = shift;
   my ( $e ) = @_;

   if( $self->[-1][0] eq "characters" ) {
      # Merge data in consequetive calls
      $self->[-1][1]{Data} .= $e->{Data};
   }
   else {
      push @$self, [ "characters", $e ];
   }
}

### GENERIC FRAMEWORK

sub can
{
   my $self = shift;
   my ( $methodname ) = @_;

   my $method;

   if( my $specificmethod = $self->SUPER::can( $methodname ) ) {
      $method = $specificmethod;
   }

   # Strip just the method name
   $methodname =~ s/^.*:://;

   if( !$method and grep { $_ eq $methodname } @IGNORE ) {
      $method = sub { };
   }

   if( !$method and grep { $_ eq $methodname } @CAPTURE ) {
      $method = sub {
         shift; # self
         push @$self, [ $methodname, @_ ]
      };
   }

   return $method;
}

our $AUTOLOAD;

sub AUTOLOAD
{
   my $self = shift;

   my $method = $self->can( $AUTOLOAD );

   if( $method ) {
      $method->( $self, @_ );
   }
   else {
      die "$self does not know how to $AUTOLOAD\n";
   }
}

sub DESTROY
{
   # ignore, but keep AUTOLOAD happy
}

sub fatal_error
{
   my $self = shift;
   my ( $error ) = @_;

   die "$self has fatal error: $error\n";
}

1;
