package perfSONAR_PS::Datatypes::EventTypes::Tools;

=head1 NAME

    perfSONAR_PS::Datatypes::EventTypes::Tools -  a container for various perfSONAR http://ggf.org/ns/nmwg/tools/ eventtypes 

=head1 DESCRIPTION

The purpose of this module is to  create OO interface for tools eventtypes  and therefore
add the layer of abstraction for any tools eventtypes  related operation ( mostly for perfSONAR response).
 All  perfSONAR-PS classes should work with the instance of this class and avoid using explicit   eventtype  declarations. 

=head1 SYNOPSIS
 
    use perfSONAR_PS::Datatypes::EventTypes::Tools; 
    
    # create Tools eventtype object with default URIs
    my $tools_event = perfSONAR_PS::Datatypes::EventTypes::Tools->new();
     
    
    # overwrite only specific Namesapce   with  custom URI 
    
    $tools_event  = perfSONAR_PS::Datatypes::EventTypes::Tools->new( {'pinger' => 'http://ggf.org/ns/nmwg/tools/pinger/2.0'});
      
    my $pinger_tool = $tools_event->pinger; ## get URI by key
    
    $tools_event->pinger(  'http://ggf.org/ns/nmwg/tools/pinger/2.0'); ## set URI by key

=head1 Methods

There is accessor mutator for every defined Characteristic
 
=head2 new( )

Creates a new object, pass hash ref as collection of event types for tools namespace
    
=cut

use strict;
use warnings;
use version; our $VERSION = 0.09; 
use Log::Log4perl qw(get_logger);
use Class::Accessor;
use Class::Fields;
use base qw(Class::Accessor Class::Fields);
use fields qw( snmp pinger traceroute ping owamp bwctl  iperf);
perfSONAR_PS::Datatypes::EventTypes::Tools->mk_accessors(perfSONAR_PS::Datatypes::EventTypes::Tools->show_fields('Public'));

use constant { 
              CLASSPATH => "perfSONAR_PS::Datatypes::EventTypes::Tools",
              TOOL  => "http://ggf.org/ns/nmwg/tools",
              RELEASE => "2.0"
	      };
	      
       
sub new {
  my $that = shift;
  my $param = shift;
  
  my $logger  = get_logger( CLASSPATH ); 
 
  if($param && ref($param) ne 'HASH')   {
    $logger->error("ONLY hash ref accepted as param " . $param ); 
    return undef;
  }
  my $class = ref($that) || $that;
  my $self =  fields::new( $class );  
  foreach my $tool ($self->show_fields('Public')) {
  	$self->{$tool} =    TOOL . "/$tool/" . RELEASE . "/";
  }
  return $self;

}

 
1;

 
__END__

  
=head2  Supported Tools:  
 
 'pinger'  'traceroute','snmp', 'ping', 'owamp',   'bwctl', 'pinger', 'iperf'
   

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
