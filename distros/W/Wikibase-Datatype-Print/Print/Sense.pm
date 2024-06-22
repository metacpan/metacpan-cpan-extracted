package Wikibase::Datatype::Print::Sense;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(defaults print_glosses print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.17;

sub print {
	my ($obj, $opts_hr) = @_;

	$opts_hr = defaults($obj, $opts_hr);

	if (! $obj->isa('Wikibase::Datatype::Sense')) {
		err "Object isn't 'Wikibase::Datatype::Sense'.";
	}

	# Id.
	my @ret = (
		$opts_hr->{'texts'}->{'id'}.': '.$obj->id,
	);

	# Glosses.
	push @ret, print_glosses($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Statements.
	push @ret, print_statements($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Statement::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Sense - Wikibase sense pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Sense qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Sense>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         From Wikibase::Datatype::Print::Utils::defaults():
                 Defined text keys are bad.
         Object isn't 'Wikibase::Datatype::Sense'.

=head1 EXAMPLE

=for comment filename=create_and_print_sense.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Print::Sense;
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

 # Print.
 print encode_utf8(scalar Wikibase::Datatype::Print::Sense::print($obj))."\n";

 # Output:
 # Id: ID
 # Glosses:
 #   domesticated mammal related to the wolf (en)
 #   psovitá šelma chovaná jako domácí zvíře (cs)
 # Statements:
 #   P5137: Q144 (normal)
 #   P18: Canadian Inuit Dog.jpg (normal)

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Statement>,
L<Wikibase::Datatype::Print::Utils>,
L<Wikibase::Datatype::Print::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Sense>

Wikibase sense datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.17

=cut
