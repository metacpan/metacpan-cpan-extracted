package Wikibase::Datatype::Print::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(all);
use Readonly;
use Wikibase::Datatype::Print::Texts qw(text_keys texts);

Readonly::Array our @EXPORT_OK => qw(defaults print_aliases print_common print_descriptions
	print_forms print_glosses print_labels print_references print_senses
	print_sitelinks print_statements);

our $VERSION = 0.19;

sub defaults {
	my ($obj, $opts_hr) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}

	if (! exists $opts_hr->{'lang'}) {
		$opts_hr->{'lang'} = 'en';
	}

	if (! exists $opts_hr->{'texts'}) {
		$opts_hr->{'texts'} = texts($opts_hr->{'lang'});

	# Check 'texts' keys if are right.
	} else {
		if (! all { exists $opts_hr->{'texts'}->{$_} } text_keys()) {
			err 'Defined text keys are bad.';
		}
	}

	return $opts_hr;
}

sub print_aliases {
	my ($obj, $opts_hr, $alias_cb) = @_;

	if ($opts_hr->{'lang'}) {
		return print_common($obj, $opts_hr, 'aliases', $alias_cb,
			$opts_hr->{'texts'}->{'aliases'}, sub {
				grep { $_->language eq $opts_hr->{'lang'} } @_
			},
		);
	} else {
		return print_common($obj, $opts_hr, 'aliases', $alias_cb,
			$opts_hr->{'texts'}->{'aliases'});
	}
}

sub print_common {
	my ($obj, $opts_hr, $list_method, $print_cb, $title, $input_cb,
		$flag_one_line) = @_;

	my @input;
	if (defined $input_cb) {
		@input = map { $input_cb->($_) } @{$obj->$list_method};
	} else {
		@input = @{$obj->$list_method};
	}

	my @ret;
	my @values;
	my $separator = '  ';
	if ($flag_one_line) {
		$separator = ' ';
	}
	foreach my $list_item (@input) {
		push @values, map { $separator.$_ } $print_cb->($list_item, $opts_hr);
	}
	if (@values) {
		if ($flag_one_line) {
			if (@values > 1) {
				err "Multiple values are printed to one line.";
			}
			push @ret, $title.':'.$values[0];
		} else {
			push @ret, (
				$title.':',
				@values,
			);
		}
	}

	return @ret;
}

sub print_descriptions {
	my ($obj, $opts_hr, $desc_cb) = @_;

	if ($opts_hr->{'lang'}) {
		return print_common($obj, $opts_hr, 'descriptions', $desc_cb,
			$opts_hr->{'texts'}->{'description'}, sub {
				grep { $_->language eq $opts_hr->{'lang'} } @_
			}, 1,
		);
	} else {
		return print_common($obj, $opts_hr, 'descriptions', $desc_cb,
			$opts_hr->{'texts'}->{'description'});
	}
}

sub print_forms {
	my ($obj, $opts_hr, $form_cb) = @_;

	return print_common($obj, $opts_hr, 'forms', $form_cb,
		$opts_hr->{'texts'}->{'forms'});
}

sub print_glosses {
	my ($obj, $opts_hr, $glosse_cb) = @_;

	return print_common($obj, $opts_hr, 'glosses', $glosse_cb,
		$opts_hr->{'texts'}->{'glosses'});
}

sub print_labels {
	my ($obj, $opts_hr, $label_cb) = @_;

	if ($opts_hr->{'lang'}) {
		return print_common($obj, $opts_hr, 'labels', $label_cb,
			$opts_hr->{'texts'}->{'label'}, sub {
				grep { $_->language eq $opts_hr->{'lang'} } @_
			}, 1,
		);
	} else {
		return print_common($obj, $opts_hr, 'labels', $label_cb,
			$opts_hr->{'texts'}->{'label'});
	}
}

sub print_references {
	my ($obj, $opts_hr, $reference_cb) = @_;

	return print_common($obj, $opts_hr, 'references', $reference_cb,
		$opts_hr->{'texts'}->{'references'});
}

sub print_senses {
	my ($obj, $opts_hr, $sense_cb) = @_;

	return print_common($obj, $opts_hr, 'senses', $sense_cb,
		$opts_hr->{'texts'}->{'senses'});
}

sub print_sitelinks {
	my ($obj, $opts_hr, $sitelink_cb) = @_;

	return print_common($obj, $opts_hr, 'sitelinks', $sitelink_cb,
		$opts_hr->{'texts'}->{'sitelinks'}, sub {
			my @sitelinks = @_;
			my $l = $opts_hr->{'lang'};
			if (defined $l) {
				return grep { $_->site =~ m/${l}wiki/ms } @sitelinks;
			} else {
				return @sitelinks;
			}
		});
}

sub print_statements {
	my ($obj, $opts_hr, $statement_cb) = @_;

	return print_common($obj, $opts_hr, 'statements', $statement_cb,
		$opts_hr->{'texts'}->{'statements'});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Utils - Wikibase pretty print helper utils.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Utils qw(defaults print_aliases print_common print_descriptions
         print_forms print_glosses print_labels print_references print_senses
         print_sitelinks print_statements);

 my $opts_hr = defaults($obj, $opts_hr);
 my @aliase_strings = print_aliases($obj, $opts_hr, $alias_cb);
 my @common_strings = print_common($obj, $opts_hr, $list_method, $print_cb, $title, $input_cb, $flag_one_line);
 my @desc_strings = print_descriptions($obj, $opts_hr, $desc_cb);
 my @form_strings = print_forms($obj, $opts_hr, $form_cb);
 my @glosse_strings = print_glosses($obj, $opts_hr, $glosse_cb);
 my @label_strings = print_labels($obj, $opts_hr, $label_cb);
 my @reference_strings = print_references($obj, $opts_hr, $reference_cb);
 my @sense_strings = print_senses($obj, $opts_hr, $sense_cb);
 my @sitelink_strings = print_sitelinks($obj, $opts_hr, $sitelink_cb);
 my @statement_strings = print_statements($obj, $opts_hr, $statement_cb);

=head1 SUBROUTINES

=head2 C<defaults>

 my $opts_hr = defaults($obj, $opts_hr);

Set default C<$opts_hr> options variable which is used in all main objects.
Updates:

=over

=item main C<$opts_hr> variable if doesn't exist ({})

=item language if doesn't exist (en)

=item texts (English texts)

=item check texts if are defined from user (error)

=back

Returns updated C<$opts_hr> variable.

Returns reference to hash.

=head2 C<print_aliases>

 my @aliase_strings = print_aliases($obj, $opts_hr, $alias_cb);

Get aliase strings from data object.

Returns array with pretty print strings.

=head2 C<print_common>

 my @common_strings = print_common($obj, $opts_hr, $list_method, $print_cb, $title, $input_cb, $flag_one_line);

Common function for get pretty print strings from object.

Returns array with pretty print strings.

=head2 C<print_descriptions>

 my @desc_strings = print_descriptions($obj, $opts_hr, $desc_cb);

Get description strings from data object.

Returns array with pretty print strings.

=head2 C<print_forms>

 my @form_strings = print_forms($obj, $opts_hr, $form_cb);

Get form strings from data object.

Returns array with pretty print strings.

=head2 C<print_glosses>

 my @glosse_strings = print_glosses($obj, $opts_hr, $glosse_cb);

Get glosse strings from data object.

Returns array with pretty print strings.

=head2 C<print_labels>

 my @label_strings = print_labels($obj, $opts_hr, $label_cb);

Get label strings from data object.

Returns array with pretty print strings.

=head2 C<print_references>

 my @reference_strings = print_references($obj, $opts_hr, $reference_cb);

Get reference strings from data object.

Returns array with pretty print strings.

=head2 C<print_senses>

 my @sense_strings = print_senses($obj, $opts_hr, $sense_cb);

Get sense strings from data object.

Returns array with pretty print strings.

=head2 C<print_sitelinks>

 my @sitelink_strings = print_sitelinks($obj, $opts_hr, $sitelink_cb);

Get sitelink strings from data object.

Returns array with pretty print strings.

=head2 C<print_statements>

 my @statement_strings = print_statements($obj, $opts_hr, $statement_cb);

Get statement strings from data object.

Returns array with pretty print strings.

=head1 ERRORS

 defaults():
         Defined text keys are bad.

 print_common():
         Multiple values are printed to one line.

 print_descriptions():
         From print_common():
                 Multiple values are printed to one line.

 print_labels():
         From print_common():
                 Multiple values are printed to one line.

=head1 EXAMPLE1

=for comment filename=utils_print_aliases.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(encode_utf8);
 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
 use Wikibase::Datatype::Print::Utils qw(print_aliases);
 use Wikibase::Datatype::Print::Value::Monolingual;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
 my @ret = print_aliases($obj, {'lang' => 'cs', 'texts' => {'aliases' => 'Aliases'}},
         \&Wikibase::Datatype::Print::Value::Monolingual::print);

 # Print.
 print encode_utf8(join "\n", @ret);
 print "\n";

 # Output:
 # Aliases:
 #   pes domácí (cs)

=head1 EXAMPLE2

=for comment filename=utils_print_descriptions.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(encode_utf8);
 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
 use Wikibase::Datatype::Print::Utils qw(print_descriptions);
 use Wikibase::Datatype::Print::Value::Monolingual;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
 my @ret = print_descriptions($obj, {'lang' => 'cs', 'texts' => {'description' => 'Description'}},
         \&Wikibase::Datatype::Print::Value::Monolingual::print);

 # Print.
 print encode_utf8(join "\n", @ret);
 print "\n";

 # Output:
 # Description: domácí zvíře (cs)

=head1 EXAMPLE3

=for comment filename=utils_print_forms.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(encode_utf8);
 use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
 use Wikibase::Datatype::Print::Form;
 use Wikibase::Datatype::Print::Utils qw(defaults print_forms);

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;
 my $opts_hr = defaults({'lang' => 'cs'});
 my @ret = print_forms($obj, $opts_hr,
         \&Wikibase::Datatype::Print::Form::print);

 # Print.
 print encode_utf8(join "\n", @ret);
 print "\n";

 # Output:
 # Forms:
 #   Id: L469-F1
 #   Representation: pes (cs)
 #   Grammatical features: Q110786, Q131105
 #   Statements:
 #     P898: pɛs (normal)

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.19

=cut
