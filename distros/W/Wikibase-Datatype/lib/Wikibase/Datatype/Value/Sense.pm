package Wikibase::Datatype::Value::Sense;

use strict;
use warnings;

use Mo qw(build);
use Wikibase::Datatype::Utils qw(check_sense);

our $VERSION = 0.29;

extends 'Wikibase::Datatype::Value';

sub type {
	return 'sense';
}

sub BUILD {
	my $self = shift;

	check_sense($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Value::Sense - Wikibase sense value datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Value::Sense;

 my $obj = Wikibase::Datatype::Value::Sense->new(%params);
 my $type = $obj->type;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is sense class for representation of wikibase item (e.g. L34727-S1).

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Value::Sense->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<value>

Value of instance.
Parameter must be in form /^L\d+-S\d+$/ (regexp).
Parameter is required.

=back

=head2 C<type>

 my $type = $obj->type;

Get type. This is constant 'sense'.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Wikibase::Datatype::Value::new():
                 Parameter 'value' is required.
         From Wikibase::Datatype::Utils::check_sense():
                 Parameter 'value' must begin with 'L' and number, dash, S and number after it.

=head1 EXAMPLE

=for comment filename=create_and_print_value_sense.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Value::Sense;

 # Object.
 my $obj = Wikibase::Datatype::Value::Sense->new(
         'value' => 'L34727-S1',
 );

 # Get value.
 my $value = $obj->value;

 # Get type.
 my $type = $obj->type;

 # Print out.
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Type: sense
 # Value: L34727-S1

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Wikibase::Datatype::Utils>,
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

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.29

=cut
