package  perfSONAR_PS::Datatypes::NSMap;
use strict;
use warnings;
=head1 NAME

 perfSONAR_PS::Datatypes::NSMap - namespace mapper interface class

=head1 DESCRIPTION
   
      see each call description for details

=cut
use version;our $VERSION = 0.09;
use Readonly;  
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::NSMap';
use perfSONAR_PS::Datatypes::Namespace;
use fields qw( namespace );
##use Log::Log4perl qw(get_logger); 

sub new {
   my $class = shift;
   $class = ref($class) || $class;
   my $self =   fields::new($class);
   my $param = shift;
   if(ref($param) eq  'HASH')  {
     foreach my $key (keys %{$param}) { 
      $self->mapname($key => $param->{$key});
     }
   }
   $self->{namespace} = {};
   return $self; 
}
 
=head2      mapname ()

    namespace definitions, 
    first parameter is the current object 
    othe parameters:
    with single paramter ( element name ) it will return  
    id ( not the actual URI) of the namesapce and with two parameters will set namespace
    to specific element name
    and without parameters it will return the whole namespaces hashref

=cut 

 
sub mapname {
      my ($self, $element, $nsid) = @_;
     
      ##my $logger  = get_logger( CLASSPATH );
      if ( $element  &&  $nsid) {
         if(perfSONAR_PS::Datatypes::Namespace::getNsByKey($nsid)) {  
	     ##$logger->debug("Setting id=$nsid for element=$element");
	     $self->{namespace}->{$element}  =  $nsid;
	     return $self;
	 }
      } elsif($element  && $self->{namespace}->{$element} && !$nsid) {
         ##$logger->debug("Returning namespace id for element name=$element id=". $self->{namespace}->{$element});
         return $self->{namespace}->{$element};
      } elsif(!$nsid && !$element ) {
         ##$logger->debug("Returning whole namespace hashref");
         return $self->{namespace};
      }   
      return;    
} 
 

=head1 AUTHORS

   Maxim Grigoriev (FNAL)  2007, maxim@fnal.gov

=cut

1;
