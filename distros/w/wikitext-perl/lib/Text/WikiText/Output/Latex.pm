# WikiText parser modules, Copyright (C) 2006-7 Enno Cramer, Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the Perl Artistic License or the GNU General
# Public License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

package Text::WikiText::Output::Latex;

use strict;
use warnings;

use base 'Text::WikiText::Output';

use Text::WikiText ':types';

# TODO: fix ~ and ^
sub entities {
	'{' => '\{',
	'}' => '\}',
	'#' => '\#',
	'_' => '\_',
	'$' => '\$',
	'%' => '\%',
	'&' => '\&',

	'>' => '$>$',
	'<' => '$<$',
	'|' => '$|$',

	'^' => '\verb+^+',
	'~' => '\verb+~+',

	'\\' => '$\backslash$',
}

# TODO: is it possible to escape these?
my %URL_ENTITIES = (
	'{'  => '',
	'}'  => '',
	'\\' => '',
);

my $URL_ENTITY_RE = join '|', map { quotemeta } keys %URL_ENTITIES;

sub url_escape {
	my $text = shift;

	$text =~ s/$URL_ENTITY_RE/$URL_ENTITIES{$&}/ego;

	return $text;
}

# TODO: does hyperref support labeled links?
sub dump_text {
	my ($self, $text, %opts) = @_;

	my $str = '';
	foreach my $chunk (@$text) {
		if ($chunk->{type} eq VERBATIM) {
			$str .= $chunk->{text}
				unless $opts{no_verbatim};

		} elsif ($chunk->{type} eq TEXT) {
			$str .= $self->escape($chunk->{text});

		} elsif ($chunk->{type} eq EMPHASIS) {
			$str .= '\emph{' . $self->escape($chunk->{text}) . '}';

		} elsif ($chunk->{type} eq STRONG) {
			$str .= '\textbf{' . $self->escape($chunk->{text}) . '}';

		} elsif ($chunk->{type} eq UNDERLINE) {
			$str .= '\underbar{' . $self->escape($chunk->{text}) . '}';

		} elsif ($chunk->{type} eq STRIKE) {
			$str .= '\textst{' . $self->escape($chunk->{text}) . '}';

		} elsif ($chunk->{type} eq TYPEWRITER) {
			$str .= '\texttt{' . $self->escape($chunk->{text}) . '}';

		} elsif ($chunk->{type} eq LINK) {
			$self->fill_in_link($chunk);

			my $target = $self->escape($chunk->{target});
			my $label = $self->escape($chunk->{label});

			if ($chunk->{style} eq '>') {
				if ($label ne $target) {
					$str .= "$label \\footnote{$label: \\url{$target}}";
				} else {
					$str .= "\\url{$target}";
				}

			} elsif ($chunk->{style} eq '=') {
				$str .= "\\includegraphics{$target}";

			} elsif ($chunk->{style} eq '#') {
				$str .= "\\ref{$target}~$label";

			} else {
				warn("Unrecognized link style '" . $chunk->{style} . "'.\n");
			}

		} else {
			warn("Unrecognized text markup '" . $chunk->{type} . "'.\n");
		}
	}

	return $str;
}

sub dump_paragraph {
	my ($self, $para, %opts) = @_;

	my $text = '';

	$text .= "\\paragraph{" . $self->escape($para->{heading}) . "} "
		if defined $para->{heading};

	$text .= $self->dump_text($para->{text}, %opts);

	return $text;
}

sub dump_code {
	my ($self, $code, %opts) = @_;

	return "\\begin{verbatim}\n"
		. $code->{text}
		. "\\end{verbatim}\n";
}

sub dump_preformatted {
	my ($self, $pre, %opts) = @_;

	my $str = $self->dump_text($pre->{text}, %opts);
	$str =~ s/ /\\ /g;

	return "{\\tt\\obeylines $str}\n";
}

sub dump_table {
	my ($self, $table, %opts) = @_;

	my $ncols = 0;
	map { my $c = @{$_->{cols}}; $ncols = $c if $c > $ncols; }
		@{$table->{content}};

	my $str = "\\begin{tabular}{|" . ('l|' x $ncols) . "}\n";
	$str .= "\\hline\n";

	foreach my $row (@{$table->{content}}) {
		my $first = 1;

		foreach my $col (@{$row->{cols}}) {
			$str .= ' & ' unless $first;
			$first = 0;

			$str .= "\\multicolumn{$col->{span}}{|l|}{" if $col->{span};
			$str .= "\\textbf{" if $row->{heading};

			$str .= $self->dump_text($col->{text}, %opts);

			$str .= "}" if $row->{heading};
			$str .= "}" if $col->{span};
		}
		$str .= "\\\\\n";

		$str .= "\\hline\n";
		$str .= "\\hline\n" if $row->{heading};
	}

	$str .= "\\end{tabular}\n";

	return $str;
}

sub dump_rule {
	my ($self, $rule, %opts) = @_;

	return "\\hrule\n";
}

sub dump_quotation {
	my ($self, $quote, %opts) = @_;

	return "\\begin{quote}\n" 
		. $self->dump_list($quote->{content}, %opts) 
		. "\\end{quote}\n"
}

sub dump_listing {
	my ($self, $listing, %opts) = @_;

	return
		"\\begin{itemize}\n" .
		join("\n", map {
			"\\item " . $self->dump_list($_, %opts)
		} @{$listing->{content}}) .
		"\\end{itemize}\n";
}

sub dump_enumeration {
	my ($self, $enum, %opts) = @_;

	return
		"\\begin{enumerate}\n" .
		join("\n", map {
			"\\item " . $self->dump_list($_, %opts)
		} @{$enum->{content}}) .
		"\\end{enumerate}\n";
}

sub dump_description {
	my ($self, $descr, %opts) = @_;

	return
		"\\begin{description}\n" .
		join("\n", map {
			"\\item[$_->[0]] " . $self->dump_list($_->[1], %opts)
		} @{$descr->{content}}) .
		"\\end{description}\n";
}

my @SECTION = qw(
	\chapter
	\section \subsection \subsubsection
	\paragraph \subparagraph
);

sub dump_section {
	my ($self, $heading, %opts) = @_;

	my $level = $heading->{level} + ($opts{heading_offset} || 0);
	my $label = $heading->{heading};

	my $anchor = $label;
	$anchor =~ s/\W/_/g;

	return $SECTION[$level] . "{$label}\n" 
		. "\\label{$anchor}\n\n"
		. $self->dump_list($heading->{content}, %opts);
}

sub construct_full_page {
	my ($self, $page, %opts) = @_;

	my $class = $self->escape($opts{class} || "article");

	return <<EOS;
\\documentclass{$class}

\\usepackage[utf8]{inputenc}
\\usepackage{soul}
\\usepackage{hyperref}
\\usepackage{url}

\\author{$opts{escaped_author}}
\\title{$opts{escaped_title}}

\\begin{document}
\\maketitle
\\tableofcontents
\\newpage

$page
\\end{document}
EOS
}

1;

__END__
