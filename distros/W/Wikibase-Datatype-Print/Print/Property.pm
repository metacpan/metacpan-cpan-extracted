package Wikibase::Datatype::Print::Property;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(print_aliases print_descriptions
	print_labels print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.13;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}

	if (! exists $opts_hr->{'lang'}) {
		$opts_hr->{'lang'} = 'en';
	}

	if (! $obj->isa('Wikibase::Datatype::Property')) {
		err "Object isn't 'Wikibase::Datatype::Property'.";
	}

	my @ret = (
		'Data type: '.$obj->datatype,
	);

	# Label.
	push @ret, print_labels($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Description.
	push @ret, print_descriptions($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Aliases.
	push @ret, print_aliases($obj, $opts_hr,
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

Wikibase::Datatype::Print::Property - Wikibase property pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Property qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Property>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Property'.

=head1 EXAMPLE

=for comment filename=create_and_print_property.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Print::Property;
 use Wikibase::Datatype::Property;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Sitelink;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Statement.
 my $statement1 = Wikibase::Datatype::Statement->new(
         # instance of (P31) Wikidata property (Q18616576)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q18616576',
                 ),
                 'property' => 'P31',
         ),
 );

 # Main item.
 my $obj = Wikibase::Datatype::Property->new(
         'aliases' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'je',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'is a',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'is an',
                 ),
         ],
         'datatype' => 'wikibase-item',
         'descriptions' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('tato položka je jedna konkrétní věc (exemplář, '.
                                 'příklad) patřící do této třídy, kategorie nebo skupiny předmětů'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'that class of which this subject is a particular example and member',
                 ),
         ],
         'id' => 'P31',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('instance (čeho)'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'instance of',
                 ),
         ],
         'page_id' => 3918489,
         'statements' => [
                 $statement1,
         ],
         'title' => 'Property:P31',
 );

 # Print.
 print encode_utf8(scalar Wikibase::Datatype::Print::Property::print($obj))."\n";

 # Output:
 # Data type: wikibase-item
 # Label: instance of (en)
 # Description: that class of which this subject is a particular example and member (en)
 # Aliases:
 #   is a (en)
 #   is an (en)
 # Statements:
 #   P31: Q18616576 (normal)

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<Readonly>,
L<Wikibase::Datatype::Print::Statement>,
L<Wikibase::Datatype::Print::Utils>,
L<Wikibase::Datatype::Print::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Property>

Wikibase property datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.13

=cut

