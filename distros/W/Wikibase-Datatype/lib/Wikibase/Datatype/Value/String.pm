package Wikibase::Datatype::Value::String;

use strict;
use warnings;

use Mo;

our $VERSION = 0.20;

extends 'Wikibase::Datatype::Value';

sub type {
	return 'string';
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Value::String - Wikibase string value datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Value::String;

 my $obj = Wikibase::Datatype::Value::String->new(%params);
 my $type = $obj->type;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is string class for representation of common string. There are
upper datatypes as commonsMedia, external-id, geo-shape, math, musical-notation,
string, tabular-data and url, which uses this data type.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Value::String->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<value>

Value of instance.
Parameter is required.

=back

=head2 C<type>

 my $type = $obj->type;

Get type. This is constant 'string'.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Wikibase::Datatype::Value::new():
                 Parameter 'value' is required.

=head1 EXAMPLE

=for comment filename=create_and_print_value_string.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Value::String;

 # Object.
 my $obj = Wikibase::Datatype::Value::String->new(
         'value' => 'foo',
 );

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Type: string
 # Value: foo

=head1 DEPENDENCIES

L<Mo>,
L<Wikibase::Datatype::Value>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.20

=cut
