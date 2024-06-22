package Wikibase::Datatype::Print::Form;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(defaults print_statements);
use Wikibase::Datatype::Print::Value::Item;
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.17;

sub print {
	my ($obj, $opts_hr) = @_;

	$opts_hr = defaults($obj, $opts_hr);

	if (! $obj->isa('Wikibase::Datatype::Form')) {
		err "Object isn't 'Wikibase::Datatype::Form'.";
	}

	my @ret = (
		$opts_hr->{'texts'}->{'id'}.': '.$obj->id,
	);

	# Representation.
	# XXX In every time one?
	my ($representation) = @{$obj->representations};
	if (defined $representation) {
		push @ret, $opts_hr->{'texts'}->{'representation'}.': '.
			Wikibase::Datatype::Print::Value::Monolingual::print($representation, $opts_hr);
	}

	# Grammatical features
	my @gr_features;
	foreach my $gr_feature (@{$obj->grammatical_features}) {
		push @gr_features,
			Wikibase::Datatype::Print::Value::Item::print($gr_feature, $opts_hr);
	}
	if (@gr_features) {
		push @ret, $opts_hr->{'texts'}->{'grammatical_features'}.': '.(join ', ', @gr_features);
	}

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

Wikibase::Datatype::Print::Form - Wikibase form pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Form qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Form>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         From Wikibase::Datatype::Print::Utils::defaults():
                 Defined text keys are bad.
         Object isn't 'Wikibase::Datatype::Form'.

=head1 EXAMPLE

=for comment filename=create_and_print_form.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Form;
 use Wikibase::Datatype::Print::Form;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Monolingual;

 # Object.
 my $obj = Wikibase::Datatype::Form->new(
         'grammatical_features' => [
                 # singular
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q110786',
                 ),
                 # nominative case
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q131105',
                 ),
         ],
         'id' => 'L469-F1',
         'representations' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'pes',
                 ),
         ],
         'statements' => [
                 Wikibase::Datatype::Statement->new(
                         'snak' => Wikibase::Datatype::Snak->new(
                                 'datatype' => 'string',
                                 'datavalue' => Wikibase::Datatype::Value::String->new(
                                        'value' => decode_utf8('pɛs'),
                                 ),
                                 'property' => 'P898',
                         ),
                 ),
         ],
 );

 # Print.
 print encode_utf8(scalar Wikibase::Datatype::Print::Form::print($obj))."\n";

 # Output:
 # Id: L469-F1
 # Representation: pes (cs)
 # Grammatical features: Q110786, Q131105
 # Statements:
 #   P898: pɛs (normal)

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Print::Statement>,
L<Wikibase::Datatype::Print::Utils>,
L<Wikibase::Datatype::Print::Value::Item>,
L<Wikibase::Datatype::Print::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Form>

Wikibase form datatype.

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
