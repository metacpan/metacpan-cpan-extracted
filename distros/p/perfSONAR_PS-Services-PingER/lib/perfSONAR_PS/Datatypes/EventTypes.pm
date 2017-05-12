package perfSONAR_PS::Datatypes::EventTypes;
use strict;
use warnings;

=head1 NAME

    EventTypes -  a container for various perfSONAR eventtypes 

=head1 DESCRIPTION

The purpose of this module is to  create OO interface to eventtype registration and therefore
add the layer of abstraction for any eventtype related operation. All  perfSONAR-PS classes should
work with the instance of this class and avoid using explicit eventtype declarations. 

=head1 SYNOPSIS
 
     use perfSONAR_PS::Datatypes::EventTypes; 
     use perfSONAR_PS::Datatypes::EventTypes::Tools; 
     use perfSONAR_PS::Datatypes::EventTypes::Ops;
     use perfSONAR_PS::Datatypes::EventTypes::Characteristics; 
     
    my $tool = perfSONAR_PS::Datatypes::EventTypes::Tools->new({'pinger' => 'http://ogf.org/ns/nmwg/pinger/3.0 '});
   
    # create  EventTypes object and pass operation name to status class
    my $event= perfSONAR_PS::Datatypes::EventTypes->new({ operation => 'setupdata'});
    
    
    
    # overwrite only specific EventType  with  custom  one
    
      
    $pinger_tool = $event->tools->pinger; ## get URI by key
    $event->tools->pinger('http://newpinger/eventtype/'); ## set URI for pinger key
    
 
=head1 API

There are   get/set methods for tools and characteristics  fields

=cut


use version; our $VERSION = 0.09; 
use Readonly;
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Datatypes::EventTypes::Tools;
use perfSONAR_PS::Datatypes::EventTypes::Characteristics;
use perfSONAR_PS::Datatypes::EventTypes::Ops;
use perfSONAR_PS::Datatypes::EventTypes::Status;
use Class::Accessor;
use Class::Fields;
use base qw(Class::Accessor Class::Fields);
use fields qw( tools  characteristics ops status);
perfSONAR_PS::Datatypes::EventTypes->mk_accessors(perfSONAR_PS::Datatypes::EventTypes->show_fields('Public'));

Readonly::Scalar our $CLASSPATH => "perfSONAR_PS::Datatypes::EventTypes";

=head2 new({})

Creates a new object, accepts only single parameter - hash ref

=cut
               
sub new {
 my ($that, $param) = @_;  
 my $logger  = get_logger( $CLASSPATH ); 
 
  if($param &&  ref($param) ne 'HASH')   {
    $logger->error("ONLY hash ref  parameter accepted: " . $param ); 
    return;
  }
  my $class = ref($that) || $that;
  my $self =  fields::new( $class );
  $self->tools(  perfSONAR_PS::Datatypes::EventTypes::Tools->new());
  $self->characteristics(perfSONAR_PS::Datatypes::EventTypes::Characteristics->new()); 
  $self->ops(  perfSONAR_PS::Datatypes::EventTypes::Ops->new());
  $self->status(perfSONAR_PS::Datatypes::EventTypes::Status->new(
               (($param && $param->{operation})?$param->{operation}:q{}) ));
  
  return $self;

}
 
1;
 
__END__

 
=head2 Supported Accessors/Mutators

    tools, characteristics, ops, status
 
=head1 SEE ALSO
 
To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 AUTHOR

Maxim Grigoriev, E<lt>maxim@fnal.govE<gt>, 2007

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
