package Wikibase::Datatype::Print::Item;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Sitelink;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(defaults print_aliases print_descriptions
	print_labels print_sitelinks print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.17;

sub print {
	my ($obj, $opts_hr) = @_;

	$opts_hr = defaults($obj, $opts_hr);

	if (! $obj->isa('Wikibase::Datatype::Item')) {
		err "Object isn't 'Wikibase::Datatype::Item'.";
	}

	my @ret;

	# Label.
	push @ret, print_labels($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Description.
	push @ret, print_descriptions($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Aliases.
	push @ret, print_aliases($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Sitelinks.
	push @ret, print_sitelinks($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Sitelink::print);

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

Wikibase::Datatype::Print::Item - Wikibase item pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Item qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Item>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         From Wikibase::Datatype::Print::Utils::defaults():
                 Defined text keys are bad.
         Object isn't 'Wikibase::Datatype::Item'.

=head1 EXAMPLE

=for comment filename=create_and_print_item.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Item;
 use Wikibase::Datatype::Print::Item;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Sitelink;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Statements.
 my $statement1 = Wikibase::Datatype::Statement->new(
         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'wikibase-item',
                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                 'value' => 'Q474741',
                         ),
                         'property' => 'P642',
                 ),
         ],
         'references' => [
                 Wikibase::Datatype::Reference->new(
                         'snaks' => [
                                 # stated in (P248) Virtual International Authority File (Q53919)
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'wikibase-item',
                                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                 'value' => 'Q53919',
                                         ),
                                         'property' => 'P248',
                                 ),

                                 # VIAF ID (P214) 113230702
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'external-id',
                                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                                 'value' => '113230702',
                                         ),
                                         'property' => 'P214',
                                 ),

                                 # retrieved (P813) 7 December 2013
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'time',
                                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                 'value' => '+2013-12-07T00:00:00Z',
                                         ),
                                         'property' => 'P813',
                                 ),
                         ],
                 ),
         ],
 );
 my $statement2 = Wikibase::Datatype::Statement->new(
         # sex or gender (P21) male (Q6581097)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q6581097',
                 ),
                 'property' => 'P21',
         ),
         'references' => [
                 Wikibase::Datatype::Reference->new(
                         'snaks' => [
                                 # stated in (P248) Virtual International Authority File (Q53919)
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'wikibase-item',
                                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                 'value' => 'Q53919',
                                         ),
                                         'property' => 'P248',
                                 ),

                                 # VIAF ID (P214) 113230702
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'external-id',
                                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                                 'value' => '113230702',
                                         ),
                                         'property' => 'P214',
                                 ),

                                 # retrieved (P813) 7 December 2013
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'time',
                                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                 'value' => '+2013-12-07T00:00:00Z',
                                         ),
                                         'property' => 'P813',
                                 ),
                         ],
                 ),
         ],
 );

 # Main item.
 my $obj = Wikibase::Datatype::Item->new(
         'aliases' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('Douglas Noël Adams'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas Noel Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas N. Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas Noel Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => decode_utf8('Douglas Noël Adams'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas N. Adams',
                 ),
         ],
         'descriptions' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('anglický spisovatel, humorista a dramatik'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'English writer and humorist',
                 ),
         ],
         'id' => 'Q42',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas Adams',
                 ),
         ],
         'page_id' => 123,
         'sitelinks' => [
                 Wikibase::Datatype::Sitelink->new(
                         'site' => 'cswiki',
                         'title' => 'Douglas Adams',
                 ),
                 Wikibase::Datatype::Sitelink->new(
                         'site' => 'enwiki',
                         'title' => 'Douglas Adams',
                 ),
         ],
         'statements' => [
                 $statement1,
                 $statement2,
         ],
         'title' => 'Q42',
 );

 # Print.
 print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($obj))."\n";

 # Output:
 # Label: Douglas Adams (en)
 # Description: English writer and humorist (en)
 # Aliases:
 #   Douglas Noel Adams (en)
 #   Douglas Noël Adams (en)
 #   Douglas N. Adams (en)
 # Sitelinks:
 #   Douglas Adams (cswiki)
 #   Douglas Adams (enwiki)
 # Statements:
 #   P31: Q5 (normal)
 #    P642: Q474741
 #   References:
 #     {
 #       P248: Q53919
 #       P214: 113230702
 #       P813: 7 December 2013 (Q1985727)
 #     }
 #   P21: Q6581097 (normal)
 #   References:
 #     {
 #       P248: Q53919
 #       P214: 113230702
 #       P813: 7 December 2013 (Q1985727)
 #     }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Sitelink>,
L<Wikibase::Datatype::Print::Statement>,
L<Wikibase::Datatype::Print::Utils>,
L<Wikibase::Datatype::Print::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Item>

Wikibase item datatype.

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
