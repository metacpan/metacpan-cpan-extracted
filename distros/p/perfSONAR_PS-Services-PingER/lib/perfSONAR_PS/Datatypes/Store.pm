package perfSONAR_PS::Datatypes::Store;
{
=head1 NAME

 perfSONAR_PS::Datatypes::Store  -  this is the    store object  


=head1 DESCRIPTION

   it is an aggregation of    Data and   MetaData  objects
  
   new will throw exception in case of wrong parameters
  it accepts only one parameter -  hashref to the hash of this form:
    {
     name => 'store', ### store by default
   
       } 
     
   Namespaces wil lbe added dynamically from the underlying data and metadata
  
=head1 SYNOPSIS
             
  
	     use perfSONAR_PS::Datatypes::Store ;
	   
	     
	     my ($DOM) = $requestMessage->getElementsByTag('store');
	    
	     my $message = new perfSONAR_PS::Datatypes::Store($DOM);
             $message = new perfSONAR_PS::Datatypes::Store({ id => '2345', 
	                                                     type = 'SetupDataResponse',
							     namespace=>{nmwg=> 'something'}, 
							     MetaData => {'id1' =>   <obj>},
							     Data=> {'id1' => <obj>}}); 
	 
	    #######   add data element, namespaces will be added from this object to  store object namespace declaration
             $message->addDataById('id1', new perfSONAR_PS::Datatypes::Store::Data({id=> 'id1', id => 'id1', datum => 'OK'}));
        
	    ########add metadata element, namespaces will be added from this object to  store object namespace declaration
	     $message->addMetaDataById('id1', new perfSONAR_PS::Datatypes::Store::MetaData({metaID=> 'id1' });
	     
	     my $dom = $message->getDOM(); # get as DOM 
	     print $message->asString();  # print the whole store
	     
	     
=head1   METHODS

=cut


use strict;
use warnings;
use Log::Log4perl qw(get_logger); 
use perfSONAR_PS::Datatypes::Message;
use base qw('perfSONAR_PS::Datatypes::Message');
 

use constant CLASSPATH =  'perfSONAR_PS::Datatypes::Store';
 
=head2 new( )
   
      creates store object, accepts DOM with nmwg:store element tree or hashref to the list of
        type => <string>, id => <string> , namespace => {}, MetaData => {}, ...,   Data   => { }  ,

=cut

sub new {
  my $that = shift;
  my $param = shift;
  my $logger  = get_logger( CLASSPATH );
  my $class = ref($that) || $that; 
  my $self = $that->SUPER::new($param); 
  $self->name('store');
  bless   $self, $class;   
  
  }  
  return $self;
}
#
#  no shortcuts !
#
sub AUTOLOAD {}
#
#  allow explicit invocation
#
sub DESTROY {

}

 

=head1 AUTHORS

   Maxim Grigoriev (FNAL)   2007

=cut
}

1;
