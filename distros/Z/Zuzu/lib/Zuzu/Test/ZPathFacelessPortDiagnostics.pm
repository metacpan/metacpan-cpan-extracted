package Zuzu::Test::ZPathFacelessPortDiagnostics;

use strict;
use warnings;

our $VERSION = '0.007000';

use Exporter qw( import );

our @EXPORT_OK = qw(
	classify_query
	summarize_failed_queries
	format_summary_lines
);

my @CATEGORY_RULES = (
	{
		tag => 'function-node-set-coercion',
		re => qr{\b(?:count|sum|min|max|join|replace|substring|index-of|string-length|matches|format)\s*\(},
	},
	{
		tag => 'position-key-context',
		re => qr{\b(?:index|key)\s*\(|#\d+|\.\.\*|\.\.|\bis-first\s*\(|\bis-last\s*\(},
	},
	{
		tag => 'xml-attributes-namespaces',
		re => qr{\@|\burl\s*\(|\brdf:},
	},
	{
		tag => 'comparison-truthiness',
		re => qr{==|!=|\[[^\]]*\]|\btype\s*\(},
	},
	{
		tag => 'numeric-tokenization',
		re => qr{\bnumber\s*\(|\d\s*[+\-*\/]\s*\d|\d\.\d},
	},
);

sub classify_query {
	my ( $query ) = @_;

	$query = '' if not defined $query;

	for my $rule ( @CATEGORY_RULES ) {
		if ( $query =~ $rule->{re} ) {
			return $rule->{tag};
		}
	}

	return 'other';
}

sub summarize_failed_queries {
	my ( $queries ) = @_;

	$queries = [] if not defined $queries;

	my %stats;
	for my $query ( @{ $queries } ) {
		my $tag = classify_query( $query );
		$stats{ $tag }{count}++;
		if ( not defined $stats{ $tag }{examples} ) {
			$stats{ $tag }{examples} = [];
		}
		if ( scalar @{ $stats{ $tag }{examples} } < 3 ) {
			push @{ $stats{ $tag }{examples} }, $query;
		}
	}

	my @summary = map {
		{
			tag => $_,
			count => $stats{$_}{count} || 0,
			examples => $stats{$_}{examples} || [],
		}
	} keys %stats;

	@summary = sort {
		$b->{count} <=> $a->{count}
			or $a->{tag} cmp $b->{tag}
	} @summary;

	return \@summary;
}

sub format_summary_lines {
	my ( $summary ) = @_;

	$summary = [] if not defined $summary;

	my @lines;
	for my $row ( @{ $summary } ) {
		my $sample = join '; ', @{ $row->{examples} || [] };
		push @lines, sprintf(
			"%s: %d (examples: %s)",
			$row->{tag},
			$row->{count} || 0,
			$sample eq '' ? 'n/a' : $sample,
		);
	}

	return \@lines;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Test::ZPathFacelessPortDiagnostics >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
