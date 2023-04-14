package Wikibase::Datatype::Print::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print_aliases print_common print_descriptions
	print_forms print_glosses print_labels print_references print_senses
	print_sitelinks print_statements);

our $VERSION = 0.04;

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

sub print_aliases {
	my ($obj, $opts_hr, $alias_cb) = @_;

	return print_common($obj, $opts_hr, 'aliases', $alias_cb,
		'Aliases', sub {
			grep { $_->language eq $opts_hr->{'lang'} } @_
		},
	);
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
	my ($obj, $opts_hr, $forms_cb) = @_;

	return print_common($obj, $opts_hr, 'forms', $forms_cb,
		'Forms');
}

sub print_glosses {
	my ($obj, $opts_hr, $glosses_cb) = @_;

	return print_common($obj, $opts_hr, 'glosses', $glosses_cb,
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
