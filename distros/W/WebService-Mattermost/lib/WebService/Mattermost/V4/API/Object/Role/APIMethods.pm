package WebService::Mattermost::V4::API::Object::Role::APIMethods;

use Moo::Role;
use Types::Standard qw(HashRef Str);

################################################################################

has available_api_methods => (is => 'rw', isa => HashRef, default => sub { {} });
has api_resource_name     => (is => 'rw', isa => Str);

################################################################################

sub call {
    my $self   = shift;
    my $method = shift;
    my $args   = shift;

    if (my $where = $self->method_is_valid($method)) {
        return $where->$method($self->id, $args);
    }

    return $self->error_return("'${method}' is not available");
}

sub set_available_api_methods {
    my $self    = shift;
    my $methods = shift;

    my %available = map { $_ => 1 } @{$methods};

    return $self->available_api_methods(\%available);
}

sub method_is_valid {
    my $self   = shift;
    my $method = shift;

    my $where    = $self->api_resource_name;
    my $expected = $where ? $self->api->$where : $self;

    return $self->available_api_methods->{$method} && $expected->can($method) && $expected;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::V4::API::Object::Role::APIMethods

=head1 DESCRIPTION

Mark methods as available for use from a result object.

=head2 USAGE

    package SomeResultObj;

    use Moo;
    
    extends 'WebService::Mattermost::V4::API::Object';
    with    'WebService::Mattermost::V4::API::Object::Role::APIMethods';

    sub BUILD {
        my $self = shift;

        # e.g. user
        $self->api_resource_name('lower case name of the API resource');

        $self->set_available_api_methods([ qw(
            method_name
            another_method_name
            yet_another_method_name
        ) ]);
    }

    1;

=head1 METHODS

=over 4

=item C<call()>

Call an API method which is available to this class.

    $object->call('method_name', {
        some => 'arguments',
    });

=item C<set_available_api_methods()>

    $self->set_available_api_methods([ qw(foo bar baz) ]);

=item C<method_is_valid()>

Checks whether the given method is set as permitted.

    my $valid = $self->method_is_valid('foo'); # 1 or 0

=back

