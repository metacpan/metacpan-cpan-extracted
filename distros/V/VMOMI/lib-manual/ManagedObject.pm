package VMOMI::ManagedObject;
use parent 'VMOMI::ComplexType';

use strict;
use warnings;

use Scalar::Util qw(weaken);

our @class_members   = ( );
our @class_ancestors = ( );

sub AUTOLOAD {
    my $self = shift;
    my $name = our $AUTOLOAD;
        
    return if $name =~ /::DESTROY$/;
    $name =~ s/.*://;
        
    my $class = ref($self);
    my $type = $class;
    $type =~ s/.*:://;
    my ($info) = grep { $_->[0] eq $name } $class->get_class_members;
    
    # TODO: Persist properties to reduce API calls, check for previously fetched properties first
    if (defined $info) {
        my $options = new VMOMI::RetrieveOptions(maxObjects => 1);
        my $pcoll = new VMOMI::ManagedObjectReference(
            type  => 'PropertyCollector',
            value => 'propertyCollector'
        );
        
        my $spec = new VMOMI::PropertyFilterSpec(reportMissingObjectsInResult => 0);
        my $pSet = [ new VMOMI::PropertySpec(
                        all => 0, 
                        type => $self->moref->type, 
                        pathSet => [ $name ],
                    )];
        my $oSet = [ new VMOMI::ObjectSpec(obj => $self->moref, skip => 0) ];
        $spec->objectSet($oSet);
        $spec->propSet($pSet);
        
        my $result = $self->stub->RetrievePropertiesEx(
            _this => $pcoll, 
            specSet => [$spec],
            options => $options
        );
        
        my $value = undef;
        # Ignoring token, *shouldn't require more than one iteration*
        # Also adding some hacked detection for permission errors when retrieving properties
        # before a login.
        for my $object (@{$result->objects}) {
            if (defined $object->missingSet) {
                my $fault = $object->missingSet->[0]->fault->fault;
                my $fault_type = ref $fault;
                $fault_type =~ s/.*:://;
                Exception::SoapFault->throw(
                    message     => "fault: $fault_type",
                );
            }
            for my $property (@{$object->propSet}) {
                if ($property->name eq $name) {
                    $self->{$name} = $property->val;
                    return $property->val;
                }
            }
        }
        return $value;    
    }
    
    # Just set or retrieve if the value is defined, should *pass-through* non SDK properties
    if (exists $self->{$name}) {
        $self->{$name} = shift if @_;
        return $self->{$name};
    }
    
    # Try a method invocation against the API otherwise
    my %args = @_;
    $args{'_this'} = $self->{'moref'};
    my $method = $self->stub->can($name);
    unless ($method) {
        Exception::Autoload->throw(message => "Unknown method '$name' in " . ref($self));
    }
    return $self->stub->$method(%args);
}

sub new {
    my ($class, $stub, $moref, %args) = @_;
    my $self = $class->SUPER::new(%args);
    
    if (ref($stub) ne 'VMOMI::SoapStub') {
        die "Parameter (0) to class '$class' constructor must be VMOMI::SoapStub: ";
    }
    if (ref($moref) ne 'VMOMI::ManagedObjectReference') {
        die "Parameter (1) to class '$class' constructor must be VMOMI::ManagedObjectReference";
    } 
    $self->{'stub'}   = $stub;
    $self->{'moref'}  = $moref;
    
    weaken $self->{'stub'};
    return bless $self, $class;
}

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
