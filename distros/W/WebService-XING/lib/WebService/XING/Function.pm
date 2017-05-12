package WebService::XING::Function;

use 5.010;
use Mo 0.30 qw(builder is required);
use WebService::XING::Function::Parameter;

use overload '""' => sub { $_[0]->name }, bool => sub { 1 }, fallback => 1;

has name => (is => 'ro', required => 1);

has method => (is => 'ro', required => 1);

has resource => (is => 'ro', required => 1);

has params_in => (is => 'ro', required => 1);

has params => (is => 'ro', builder => '_build_params');
sub _build_params {
    my $self = shift;
    my @p;

    for ($self->resource =~ /:(\w+)/g) {
        push @p, WebService::XING::Function::Parameter->new(
            name => $_,
            is_required => 1,
            is_placeholder => 1,
        );
    }

    for (@{$self->params_in}) {
        my ($flag, $key, $default) = /^([\@\!\?]*)(\w+)(?:=(.*))?$/;
        my @a;

        for (split '', $flag) {
            when ('@') { push @a, is_list => 1 }
            when ('!') { push @a, is_required => 1 }
            when ('?') { push @a, is_boolean => 1 }
        }
        push @p, WebService::XING::Function::Parameter->new(
            name => $key,
            default => $default,
            @a
        );
    }

    return \@p;
}

my $CODE = sub {
    my $f = shift;

    return sub {
        my ($self, %p) = @_;

        return $self->request($f->method, $self->_scour_args($f, \%p));
    }
};

has code => (is => 'ro', builder => '_build_code');
sub _build_code { $CODE->(shift) }

1;

__END__

=head1 NAME

WebService::XING::Function - XING API Function Class

=head1 DESCRIPTION

An object of the C<WebService::XING::Function> class represents an
abstract description of a XING API function. It is usually created and
returned by L<WebService::XING/function>.

=head1 OVERLOADING

A C<WebService::XING::Function> object returns the function L</name> in
string context.

=head1 ATTRIBUTES

=head2 name

Function name. Required.

=head2 method

HTTP method. Required.

=head2 resource

The REST resource. Required.

=head2 params_in

Array reference of the parameters list. Required. Use for object creation
only.

=head2 params

Read-only attribute, that contains a reference to an array of
L<WebService::XING::Function::Parameter> objects, of which each describes
a parameter.

=head2 code

Read-only attribute, that contians a code reference. This code is
actually a closure method of the L<WebService::XING> class, with a
reference to this L<WebService::XING::Function> object in order to
validate the method arguments and to build the API request.

=head1 SEE ALSO

L<WebService::XING>, L<WebService::XING::Function::Parameter>
