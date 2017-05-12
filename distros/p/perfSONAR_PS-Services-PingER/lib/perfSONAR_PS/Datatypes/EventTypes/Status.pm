package perfSONAR_PS::Datatypes::EventTypes::Status;

=head1 NAME

    perfSONAR_PS::Datatypes::EventTypes::Status -  a container for various perfSONAR http://schemas.perfsonar.net/status/ eventtypes 

=head1 DESCRIPTION

The purpose of this module is to  create OO interface for  status eventtypes  and therefore
add the layer of abstraction for any  status eventtypes  related operation ( mostly for perfSONAR response).
 All  perfSONAR-PS classes should work with the instance of this class and avoid using explicit   eventtype  declarations. 

=head1 SYNSTATUSIS
 
    use perfSONAR_PS::Datatypes::EventTypes::Status; 
    
    # create Status eventtype object with default URIs
    my $sd_status = perfSONAR_PS::Datatypes::EventTypes::Status->new('setupdata');
     
    print  $sd_status->success
    # will print: "http://schemas.perfsonar.net/status/success/setupdata/1.0/"
    # overwrite only specific Namesapce   with  custom URI 
     
    
=head1 Methods

There is accessor mutator for every defined  status
 
=head2 new('operationName')

Creates a new object, accepts scalar operation name, if missed then default is 'echo'
    
=cut

use strict;
use warnings;
use version; our $VERSION = 0.09; 
use Log::Log4perl qw(get_logger);
use Class::Accessor;
use Class::Fields;
use base qw(Class::Accessor Class::Fields);
use fields qw( success failure operation);
perfSONAR_PS::Datatypes::EventTypes::Status->mk_accessors(perfSONAR_PS::Datatypes::EventTypes::Status->show_fields('Public'));

use constant { 
              CLASSPATH => "perfSONAR_PS::Datatypes::EventTypes::Status",
              STATUS  => "http://schemas.perfsonar.net/status",
              RELEASE => "1.0"
	      };
	      
       
sub new {
    my $that = shift;
    my $operation  = shift;
  
    my $logger  = get_logger( CLASSPATH ); 
 
    if($operation && !ref($operation))   {
        $logger->error("ONLY single scalar parameter accepted" . $operation ); 
        return undef;
    }
    my $class = ref($that) || $that;
    my $self =  fields::new( $class );  
    $operation = 'echo' unless $operation;
    $self->_init($operation);
    return $self;

}

#
#   initialize status types with operation
#

sub _init {
    my $self = shift;
    my $operation = shift;
    foreach my $tool (qw/success failure/) {
        $self->{$tool} = STATUS . "/$tool/$operation/" . RELEASE . "/";
    } 

}
=head2 operation('operationName')

Resets  current operation or returns it if argument is missed 
    
=cut

sub operation {
    my $self = shift;
    my $operation  = shift; 
    if($operation) {
        $self->_init($operation);
    } else {
        return $self->{operation};
    }
}
 
1;

 
__END__

  
=head2  Supported Status:  
 
  success / failure 
   

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
