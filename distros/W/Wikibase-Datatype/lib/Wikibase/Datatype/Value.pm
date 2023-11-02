package Wikibase::Datatype::Value;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);

our $VERSION = 0.33;

has value => (
	is => 'ro',
);

has type => (
	'is' => 'ro',
);

sub BUILD {
	my $self = shift;

	check_required($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Value - Wikibase value datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Value;

 my $obj = Wikibase::Datatype::Value->new(%params);
 my $type = $obj->type;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is base class for all Value datatypes.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Value->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<type>

Type of instance.
Default value is undef.

=item * C<value>

Value of instance.
Parameter is required.

=back

=head2 C<type>

 my $type = $obj->type;

Get type.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'value' is required.
                 Parameter 'type' is required.

=head1 EXAMPLE

=for comment filename=create_and_print_value.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Value;

 # Object.
 my $obj = Wikibase::Datatype::Value->new(
         'value' => 'foo',
         'type' => 'string',
 );

 # Get value.
 my $value = $obj->value;

 # Get type.
 my $type = $obj->type;

 # Print out.
 print "Value: $value\n";
 print "Type: $type\n";

 # Output:
 # Value: foo
 # Type: string

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Globecoordinate>

Wikibase globe coordinate value datatype.

=item L<Wikibase::Datatype::Value::Item>

Wikibase item value datatype.

=item L<Wikibase::Datatype::Value::Monolingual>

Wikibase monolingual value datatype.

=item L<Wikibase::Datatype::Value::Property>

Wikibase property value datatype.

=item L<Wikibase::Datatype::Value::Quantity>

Wikibase quantity value datatype.

=item L<Wikibase::Datatype::Value::Sense>

Wikibase sense value datatype.

=item L<Wikibase::Datatype::Value::String>

Wikibase string value datatype.

=item L<Wikibase::Datatype::Value::Time>

Wikibase time value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.33

=cut
