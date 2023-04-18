package Wikibase::Datatype::Print::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print_aliases print_common print_descriptions
	print_forms print_glosses print_labels print_references print_senses
	print_sitelinks print_statements);

our $VERSION = 0.08;

sub print_aliases {
	my ($obj, $opts_hr, $alias_cb) = @_;

	return print_common($obj, $opts_hr, 'aliases', $alias_cb,
		'Aliases', sub {
			grep { $_->language eq $opts_hr->{'lang'} } @_
		},
	);
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

	return print_common($obj, $opts_hr, 'descriptions', $desc_cb,
		'Description', sub {
			grep { $_->language eq $opts_hr->{'lang'} } @_
		}, 1,
	);
}

sub print_forms {
	my ($obj, $opts_hr, $form_cb) = @_;

	return print_common($obj, $opts_hr, 'forms', $form_cb,
		'Forms');
}

sub print_glosses {
	my ($obj, $opts_hr, $glosse_cb) = @_;

	return print_common($obj, $opts_hr, 'glosses', $glosse_cb,
		'Glosses');
}

sub print_labels {
	my ($obj, $opts_hr, $label_cb) = @_;

	return print_common($obj, $opts_hr, 'labels', $label_cb,
		'Label', sub {
			grep { $_->language eq $opts_hr->{'lang'} } @_
		}, 1,
	);
}

sub print_references {
	my ($obj, $opts_hr, $reference_cb) = @_;

	return print_common($obj, $opts_hr, 'references', $reference_cb,
		'References');
}

sub print_senses {
	my ($obj, $opts_hr, $sense_cb) = @_;

	return print_common($obj, $opts_hr, 'senses', $sense_cb,
		'Senses');
}

sub print_sitelinks {
	my ($obj, $opts_hr, $sitelink_cb) = @_;

	return print_common($obj, $opts_hr, 'sitelinks', $sitelink_cb,
		'Sitelinks');
}

sub print_statements {
	my ($obj, $opts_hr, $statement_cb) = @_;

	return print_common($obj, $opts_hr, 'statements', $statement_cb,
		'Statements');
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Utils - Wikibase pretty print helper utils.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Utils qw(print_aliases print_common print_descriptions
         print_forms print_glosses print_labels print_references print_senses
         print_sitelinks print_statements);

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

 print_common():
         Multiple values are printed to one line.

 print_descriptions():
         From print_common():
                 Multiple values are printed to one line.

 print_labels():
         From print_common():
                 Multiple values are printed to one line.

=head1 EXAMPLE

=for comment filename=utils_print_aliases.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(encode_utf8);
 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
 use Wikibase::Datatype::Print::Utils qw(print_aliases);
 use Wikibase::Datatype::Print::Value::Monolingual;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;
 my @ret = print_aliases($obj, {'lang' => 'cs'},
         \&Wikibase::Datatype::Print::Value::Monolingual::print);

 # Print.
 print encode_utf8(join "\n", @ret);
 print "\n";

 # Output:
 # Aliases:
 #   pes domácí (cs)

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

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
