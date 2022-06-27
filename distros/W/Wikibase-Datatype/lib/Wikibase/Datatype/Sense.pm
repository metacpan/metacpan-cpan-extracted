package Wikibase::Datatype::Sense;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_array_object check_number_of_items);

our $VERSION = 0.16;

has glosses => (
	default => [],
	is => 'ro',
);

has id => (
	is => 'ro',
);

has statements => (
	default => [],
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check glosses.
	check_array_object($self, 'glosses', 'Wikibase::Datatype::Value::Monolingual',
		'Glosse');
	check_number_of_items($self, 'glosses', 'language', 'Glosse', 'language');

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

Wikibase::Datatype::Sense - Wikibase sense datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Sense;

 my $obj = Wikibase::Datatype::Sense->new(%params);
 my $glosses_ar = $obj->glosses;
 my $id = $obj->id;
 my $statements_ar = $obj->statements;

=head1 DESCRIPTION

This datatype is snak class for representing relation between property and value.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Snak->new(%params);

Constructor.

Retruns instance of object.

=over 8

=item * C<glosses>

Item glosses. One per language.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

=item * C<id>

Id.
Parameter is optional.

=item * C<statements>

Item statements.
Reference to array with Wikibase::Datatype::Statement instances.
Parameter is optional.

=back

=head2 C<glosses>

 my $glosses_ar = $obj->glosses;

Get glosses.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array with Wikibase::Datatype::Statement instances.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                Glosse isn't 'Wikibase::Datatype::Value::Monolingual' object.
                Parameter 'glosses' must be a array.
                Parameter 'statements' must be a array.
                Statement isn't 'Wikibase::Datatype::Statement' object.
         From Mo::utils::check_number_of_items():
                Glosse for language '%s' has multiple values.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8);
 use Wikibase::Datatype::Sense;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Value::String;

 # One sense for Czech noun 'pes'.
 # https://www.wikidata.org/wiki/Lexeme:L469

 # Statements.
 my $statement_item = Wikibase::Datatype::Statement->new(
         # item for this sense (P5137) dog (Q144)
         'snak' => Wikibase::Datatype::Snak->new(
                  'datatype' => 'wikibase-item',
                  'datavalue' => Wikibase::Datatype::Value::Item->new(
                          'value' => 'Q144',
                  ),
                  'property' => 'P5137',
         ),
 );
 my $statement_image = Wikibase::Datatype::Statement->new(
         # image (P5137) 'Canadian Inuit Dog.jpg'
         'snak' => Wikibase::Datatype::Snak->new(
                  'datatype' => 'commonsMedia',
                  'datavalue' => Wikibase::Datatype::Value::String->new(
                          'value' => 'Canadian Inuit Dog.jpg',
                  ),
                  'property' => 'P18',
         ),
 );

 # Object.
 my $obj = Wikibase::Datatype::Sense->new(
         'glosses' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                          'language' => 'en',
                          'value' => 'domesticated mammal related to the wolf',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                          'language' => 'cs',
                          'value' => decode_utf8('psovitá šelma chovaná jako domácí zvíře'),
                 ),
         ],
         'id' => 'ID',
         'statements' => [
                 $statement_item,
                 $statement_image,
         ],
 );

 # Get id.
 my $id = $obj->id;

 # Get glosses.
 my @glosses = map { $_->value.' ('.$_->language.')' } @{$obj->glosses};

 # Get statements.
 my $statements_count = @{$obj->statements};

 # Print out.
 print "Id: $id\n";
 print "Glosses:\n";
 map { print "\t$_\n"; } @glosses;
 print "Number of statements: $statements_count\n";

 # Output:
 # Id: ID
 # Glosses:
 #         domesticated mammal related to the wolf (en)
 #         psovitá šelma chovaná jako domácí zvíře (cs)
 # Number of statements: 2

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

© Michal Josef Špaček 2020-2022

BSD 2-Clause License

=head1 VERSION

0.16

=cut
