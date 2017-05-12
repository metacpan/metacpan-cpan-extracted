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

package Text::WikiText::Output;

use strict;
use warnings;

use Text::WikiText ':types';

sub new ($) {
	my $class = shift;

	my $self = {};
	bless $self, $class;

	my %entities = $self->entities;
	$self->{entities} = \%entities;
	$self->{entity_re} = join '|', map { quotemeta } keys %entities;

	return $self;
}

sub escape ($$) {
	my $self = shift;
	my $text = shift;

	$text =~ s/$self->{entity_re}/$self->{entities}{$&}/ego;

	return $text;
}

sub separator ($) {
	return "\n";
}

my $RE_TLD = qr/
	com|edu|gov|int|mil|net|org
	|aero|biz|coop|info|museum|name|pro
	|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|az|ax
	|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz
	|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz
	|de|dj|dk|dm|do|dz
	|ec|ee|eg|eh|er|es|et|eu
	|fi|fj|fk|fm|fo|fr
	|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy
	|hk|hm|hn|hr|ht|hu
	|id|ie|il|im|in|io|iq|ir|is|it
	|je|jm|jo|jp
	|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz
	|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly
	|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz
	|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz
	|om
	|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py
	|qa
	|re|ro|ru|rw
	|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|sv|sy|sz
	|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz
	|ua|ug|uk|um|us|uy|uz
	|va|vc|ve|vg|vi|vn|vu
	|wf|ws
	|ye|yt|yu
	|za|zm|zw
/x;

sub fill_in_link {
	my ($self, $chunk) = @_;

	if ($chunk->{style} eq '') {
		# bitmap files
		if ($chunk->{target} =~ /\.(png|jpg|jpeg|gif|eps)$/) {
			$chunk->{style} = '=';

		# network protocols
		} elsif ($chunk->{target} =~ /^(http|ftp|news|mailto|irc):/) {
			$chunk->{style} = '>';

		# common top level domains
		} elsif ($chunk->{target} =~ /^(\w+\.){1,}$RE_TLD(\/|$)/) {
			$chunk->{style} = '>';

		# whitespace in urls is bad
		} elsif ($chunk->{target} =~ /\s/) {
			$chunk->{style} = '#';

		# fallback
		} else {
			$chunk->{style} = '>';
		}
	}

	$chunk->{label} ||= $chunk->{target};

	# outside link, without protocol and no directory identifier
	if ($chunk->{style} eq '>'
		&& $chunk->{target} !~ /^\w+:/
		&& $chunk->{target} !~ m,^(/|\.),
	) {
		if ($chunk->{target} =~ /@/) {
			$chunk->{target} = "mailto:" . $chunk->{target};

		} elsif ($chunk->{target} =~ /^www\./) {
			$chunk->{target} = "http://" . $chunk->{target};

		} elsif ($chunk->{target} =~ /^ftp\./) {
			$chunk->{target} = "ftp://" . $chunk->{target};

		} elsif ($chunk->{target} =~ /^(\w+\.){1,}$RE_TLD(\/|$)/) {
			$chunk->{target} = "http://" . $chunk->{target};
		}

		if ($chunk->{target} =~ /\.$RE_TLD$/) {
			$chunk->{target} .= '/';
		}
	}
}

sub dump_verbatim {
	my ($self, $verb, %opts) = @_;

	return $verb->{text};
}

# This helper method creates nice WikiText table, good for text based formats
sub dump_ascii_formatted_table {
	my ($self, $table, %opts) = @_;

	my @cell_texts = ();
	my @col_widths = ();
	my @col_aligns = ();
	my $is_compact = $opts{compact_tables};

	foreach my $row (@{$table->{content}}) {
		for (my $i = 0; $i < @{$row->{cols}}; $i++) {
			my $col = $row->{cols}[$i];
			my $text = $self->dump_text($col->{text}, %opts);
			$col_aligns[$i] = (!defined $col_aligns[$i]
				|| $col_aligns[$i]) && $text =~ /^[\d.]+$/;
			$text = " " if $text eq "" && !$is_compact;
			my $old_len = $col_widths[$i] || 0;
			my $new_len = length($text);
			push @cell_texts, $text;
			$col_widths[$i] = $new_len if $new_len > $old_len;
		}
	}

	my $separator_row = "+"
		. join("+", map { "-" x ($is_compact ? $_ : $_ + 2) } @col_widths)
		. "+\n";

	my $str = $separator_row;

	foreach my $row (@{$table->{content}}) {
		$str .= "|";

		for (my $i = 0; $i < @{$row->{cols}}; $i++) {
			### TODO: add support for $col->{span}
			my $col = $row->{cols}[$i];
			my $sign = $col_aligns[$i] ? "" : "-";
			$str .= "|" if $i;
			$str .= " " unless $is_compact;
			$str .= sprintf("%$sign$col_widths[$i]s", shift(@cell_texts));
			$str .= " " unless $is_compact;
		}

		$str .= "|\n";
		$str .= $separator_row if $row->{heading};
	}

	$str .= $separator_row;

	return $str;
}

# This helper method adds intentation block, good for text based formats
sub add_indentation_block {
	my ($self, $text, %opts) = @_;

	my $num_spaces = $opts{indent_spaces} || 2;

	join("", map { " " x $num_spaces . $_ . "\n" } split(/\n/, $text));
}

sub dump_list {
	my ($self, $list, %opts) = @_;

	my $str = '';

	my $first = 1;
	foreach my $sect (@$list) {
		$str .= $self->separator unless $first;
		$first = 0;

		if ($sect->{type} eq SECTION) {
			$str .= $self->dump_section($sect, %opts);

		} elsif ($sect->{type} eq DESCRIPTION) {
			$str .= $self->dump_description($sect, %opts);

		} elsif ($sect->{type} eq ENUMERATION) {
			$str .= $self->dump_enumeration($sect, %opts);

		} elsif ($sect->{type} eq LISTING) {
			$str .= $self->dump_listing($sect, %opts);

		} elsif ($sect->{type} eq QUOTE) {
			$str .= $self->dump_quotation($sect, %opts);

		} elsif ($sect->{type} eq TABLE) {
			$str .= $self->dump_table($sect, %opts);

		} elsif ($sect->{type} eq RULE) {
			$str .= $self->dump_rule($sect, %opts);

		} elsif ($sect->{type} eq VERBATIM) {
			$str .= $self->dump_verbatim($sect, %opts)
				unless $opts{no_verbatim};

		} elsif ($sect->{type} eq PRE) {
			$str .= $self->dump_preformatted($sect, %opts);

		} elsif ($sect->{type} eq CODE) {
			$str .= $self->dump_code($sect, %opts);

		} elsif ($sect->{type} eq P) {
			$str .= $self->dump_paragraph($sect, %opts);

		} elsif ($sect->{type} eq COMMENT) {
			# nada

		} else {
			warn(
				"Unrecognized block type '"
				. $sect->{type} . "' defined on line "
				. $sect->{line} . ".\n"
			);
		}
	}

	return $str;
}

sub dump {
	my ($self, $list, %opts) = @_;

	my $page = $self->dump_list($list, %opts);

	if ($opts{full_page}) {
		$opts{escaped_title} = $self->escape($opts{title} || 'No Title');
		$opts{escaped_author} = $self->escape($opts{author} || 'Unknown');

		$page = $self->construct_full_page($page, %opts);
	}

	return $page;
}

1;

__END__
