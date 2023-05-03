package Wikibase::Datatype::Print::Lexeme;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Form;
use Wikibase::Datatype::Print::Sense;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(print_forms print_senses print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.13;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}

	if (! $obj->isa('Wikibase::Datatype::Lexeme')) {
		err "Object isn't 'Wikibase::Datatype::Lexeme'.";
	}

	my @ret = (
		'Title: '.$obj->title,
	);

	# Lemmas.
	my ($lemma) = @{$obj->lemmas};
	if (defined $lemma) {
		push @ret, 'Lemmas: '.
			Wikibase::Datatype::Print::Value::Monolingual::print($lemma, $opts_hr);
	}

	# Language.
	if ($obj->language) {
		push @ret, (
			'Language: '.$obj->language,
		);
	}

	# Lexical category.
	if ($obj->lexical_category) {
		push @ret, (
			'Lexical category: '.$obj->lexical_category,
		);
	}

	# Statements.
	push @ret, print_statements($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Statement::print);

	# Senses.
	push @ret, print_senses($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Sense::print);

	# Forms.
	push @ret, print_forms($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Form::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Lexeme - Wikibase lexeme pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Lexeme qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Lexeme>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Lexeme'.

=head1 EXAMPLE

=for comment filename=create_and_print_lexeme.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Lexeme;
 use Wikibase::Datatype::Print::Lexeme;
 use Wikibase::Datatype::Reference;
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

 # Object.
 my $obj = Wikibase::Datatype::Lexeme->new(
         'id' => 'L469',
         'lemmas' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'pes',
                 ),
         ],
         'statements' => [
                 $statement1,
                 $statement2,
         ],
         'title' => 'Lexeme:L469',
 );

 # Print.
 print Wikibase::Datatype::Print::Lexeme::print($obj)."\n";

 # Output:
 # Title: Lexeme:L469
 # Lemmas: pes (cs)
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
L<Wikibase::Datatype::Print::Form>,
L<Wikibase::Datatype::Print::Sense>,
L<Wikibase::Datatype::Print::Statement>,
L<Wikibase::Datatype::Print::Utils>,
L<Wikibase::Datatype::Print::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Lexeme>

Wikibase lexeme datatype.

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

