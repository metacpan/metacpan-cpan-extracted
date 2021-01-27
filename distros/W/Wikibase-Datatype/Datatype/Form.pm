package Wikibase::Datatype::Form;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_array_object);

our $VERSION = 0.08;

has grammatical_features => (
	default => [],
	is => 'ro',
);

has id => (
	is => 'ro',
);

has representations => (
	default => [],
	is => 'ro',
);

has statements => (
	default => [],
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check grammatical features.
	check_array_object($self, 'grammatical_features',
		'Wikibase::Datatype::Value::Item', 'Grammatical feature');

	# Check representations.
	check_array_object($self, 'representations',
		'Wikibase::Datatype::Value::Monolingual', 'Representation');

	# Check statements.
	check_array_object($self, 'statements', 'Wikibase::Datatype::Statement',
		'Statement');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Form - Wikibase form datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Form;

 my $obj = Wikibase::Datatype::Form->new(%params);
 my $grammatical_features_ar = $obj->grammatical_features;
 my $id = $obj->id;
 my $representations_ar = $obj->representations;
 my $statements_ar = $obj->statements;

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Form->new(%params);

Constructor.

Retruns instance of object.

=over 8

=item * C<grammatical_features>

Grammatical features.
Items of array are Q items.
Parameter is optional.

=item * C<id>

Identifier of form.
Parameter is optional.

=item * C<representations>

Representations.
Items of array are Wikibase::Datatype::Value::Monolingual items.
Parameter is optional.

=item * C<statements>

Statements.
Items of array are Wikibase:Datatype::Statement items.
Parameter is optional.

=back

=head2 C<grammatical_features>

 my $grammatical_features_ar = $obj->grammatical_features;

Get grammatical features.

Returns reference to array of Q items.

=head2 C<id>

 my $id = $obj->id;

Get form identifier.

Returns string.

=head2 C<representations>

 my $representations_ar = $obj->representations;

Get representations.

Returns reference to array with Wikibase::Datatype::Value::Monolingual items.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array of Wikibase::Datatype::Statemnet items.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Grammatical feature isn't 'Wikibase::Datatype::Value::Item' object.
                 Parameter 'grammatical_features' must be a array.
                 Parameter 'representations' must be a array.
                 Parameter 'statements' must be a array.
                 Representation isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Statement isn't 'Wikibase::Datatype::Statement' object.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Wikibase::Datatype::Form;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;

 # Object.
 my $obj = Wikibase::Datatype::Form->new(
         'grammatical_features' => [
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q123',
                 ),
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q321',
                 ),
         ],
         'id' => 'identifier',
         'representations' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Text',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Text',
                 ),
         ],
         'statements' => [
                 Wikibase::Datatype::Statement->new(
                         'snak' => Wikibase::Datatype::Snak->new(
                                 'datatype' => 'wikibase-item',
                                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                                        'value' => 'Q1',
                                 ),
                                 'property' => 'P1',
                         ),
                 ),
         ],
 );

 # Get id.
 my $id = $obj->id;

 # Get counts.
 my $gr_count = @{$obj->grammatical_features};
 my $re_count = @{$obj->representations};
 my $st_count = @{$obj->statements};

 # Print out.
 print "Id: $id\n";
 print "Number of grammatical features: $gr_count\n";
 print "Number of representations: $re_count\n";
 print "Number of statements: $st_count\n";

 # Output:
 # Id: identifier
 # Number of grammatical features: 2
 # Number of representations: 2
 # Number of statements: 1

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2021

BSD 2-Clause License

=head1 VERSION

0.08

=cut
