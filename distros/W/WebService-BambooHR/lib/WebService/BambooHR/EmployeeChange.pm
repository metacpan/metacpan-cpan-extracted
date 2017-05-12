package WebService::BambooHR::EmployeeChange;
$WebService::BambooHR::EmployeeChange::VERSION = '0.07';
use 5.006;
use Moo;

has id          => (is => 'ro');
has lastChanged => (is => 'ro');
has action      => (is => 'ro');

sub deleted
{
    my $self = shift;
    return $self->action eq 'Deleted' ? 1 : 0;
}

sub inserted
{
    my $self = shift;
    return $self->action eq 'Inserted' ? 1 : 0;
}

sub updated
{
    my $self = shift;
    return $self->action eq 'Updated' ? 1 : 0;
}

1;

=head1 NAME

WebService::BambooHR::EmployeeChange - data class returned by changed_employees method

