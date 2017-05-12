package WebService::XING::Function::Parameter;

use Mo 0.30 qw(is required);

use overload '""' => sub { $_[0]->name }, bool => sub { 1 }, fallback => 1;

has name => (is => 'ro', required => 1);

has is_required => (is => 'ro');

has is_placeholder => (is => 'ro');

has is_boolean => (is => 'ro');

has is_list => (is => 'ro');

has default => (is => 'ro');

1;

__END__

=head1 NAME

WebService::XING::Function::Parameter - XING API Function Parameter Class

=head1 DESCRIPTION

An object of the C<WebService::XING::Function::Parameter> class describes
a parameter element of the L<WebService::XING::Function/params>.

=head1 OVERLOADING

A C<WebService::XING::Function::Parameter> object returns the function
L</name> in string context.

=head1 ATTRIBUTES

=head2 name

Parameter name. Read-only.

=head2 is_required

Flag that is C<true> if parameter is required. Read-only.

=head2 is_placeholder

Flag that is C<true> if parameter is part of the resource. Logically a
placeholder parameter always L</is_required>. Read-only.

=head2 is_boolean

Flag that is C<true> if parameter is a boolean flag. Read-only.

=head2 is_list

Flag that is C<true> if parameter may contain multiple values. Read-only.

=head2 default

The default value for the parameter. Read-only. Default: C<undef>.
