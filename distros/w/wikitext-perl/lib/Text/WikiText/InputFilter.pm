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

package Text::WikiText::InputFilter;

use strict;
use warnings;

use IO::Handle;

sub new {
	my $class = shift;
	my $string_or_handle = shift;
	my $is_handle = ref($string_or_handle);

	my $self = {
		handle =>  $is_handle && $string_or_handle,
		string => !$is_handle && $string_or_handle,
		line_n => 0,
		eof    => 0,

		lookahead => undef,
		filter    => [],

		buffer    => undef,

		last_prefix => undef,
		last_match  => undef,
	};

	return bless $self, $class;
}

sub line_n {
	my $self = shift;

	return $self->{line_n};
}

sub last_prefix {
	my $self = shift;

	return $self->{last_prefix};
}

sub last_match {
	my $self = shift;

	return $self->{last_match};
}

sub peek {
	my $self = shift;

	if (! defined $self->{buffer}) {
		my $line = $self->readline;

		if (defined $line) {
			foreach my $filter (@{$self->{filter}}) {
				if ($line !~ s/^$filter//) {
					$line = undef;
					last;
				}
			}
		}

		$self->{buffer} = $line;
	}

	return $self->{buffer};
}

sub readline {
	my $self = shift;

	return $self->{lookahead}
		if defined $self->{lookahead} || $self->{eof};

	my $line = $self->{handle}
		? $self->{handle}->getline
		: $self->{string} =~ s/\A(.+\z|.*(?:\r*\n|\r))// ? $1 : undef;

	$self->{eof} = !defined $line;
	$line =~ s/(?:\r*\n|\r)/\n/ if defined $line;

	++$self->{line_n};

	return $self->{lookahead} = $line;
}

sub try {
	my ($self, $arg) = @_;

	$self->peek;
	my $ret = defined $self->{buffer} && $self->{buffer} =~ /^(\s*)($arg)/;

	$self->{last_prefix} = $1;
	$self->{last_match} = $2;

	return $ret;
}

sub match {
	my ($self, $arg) = @_;

	$self->peek;
	my $ret = defined $self->{buffer} && $self->{buffer} =~ s/^(\s*)($arg)//;

	$self->{last_prefix} = $1;
	$self->{last_match} = $2;

	return $ret;
}

sub commit {
	my $self = shift;

	$self->{buffer} = undef;
	$self->{lookahead} = undef;
}

sub flush_empty {
	my $self = shift;

	local $_;

	while (
		(defined ($_ = $self->readline) && /^\s*$/)
		|| (defined ($_ = $self->peek) && /^\s*$/)
	) {
		$self->commit;
	}
}

sub push_filter {
	my ($self, $filter) = @_;

	push @{$self->{filter}}, defined $self->{last_prefix}
		? qr/\Q$self->{last_prefix}\E$filter/
		: $filter;
}

sub pop_filter {
	my $self = shift;

	pop @{$self->{filter}};
	$self->{buffer} = undef;
}

1;

__END__

=head1 NAME

Text::WikiText::InputFilter - A stream filter

=head1 SYNOPSIS

	use Text::WikiText::InputFilter;

	my $filter = Text::WikiText::InputFilter->new(\*STDIN);
	$filter->push_filter(qr/> ?/);
	while (defined ($_ = $filter->readline)) {
		print "$_";
		$filter->commit;
	}
	$filter->pop_filter;

=head1 DESCRIPTION

Text::WikiText::InputFilter provides a simple interface to aid
parsing line-based, prefix-structured content.

=head1 METHODS

The following methods are available:

B<new>,
B<line_n>,
B<last_prefix>,
B<last_match>,
B<peek>,
B<readline>,
B<try>,
B<match>,
B<commit>,
B<flush_empty>,
B<push_filter>,
B<pop_filter>.

=over 4

=item B<new> I<handle>

=item B<new> I<string>

Create a new input filter over the given string or L<IO::Handle>.

=item B<line_n>

Return the current line number.

=item B<last_prefix>

Returns the whitespace before the last match.  See B<try> and
B<match>.

=item B<last_match>

Returns the last match.  See B<try> and B<match>.

=item B<peek>

Returns the current input line with all prefixes removed, or B<undef>
if a filter does not match.

=item B<readline>

Return the current input line unchanged, or B<undef> on end-of-file or
error.

=item B<try> I<regexp>

Try to match I<regexp> against the beginning of the current, filtered
input line (see B<peek>).  The matched string and any preceeding
whitespace can be accessed with B<last_match> and B<last_prefix>.
Returns a true value if I<regexp> matched.

=item B<match> I<regexp>

Same as B<try>, but removes the match and prefix from the current
input line.

=item B<commit>

Mark the current input line as processed.  Future calls to B<peek> or
B<readline> will return the next input line.

=item B<flush_empty>

Skip all input lines containing only whitespace.

=item B<push_filter> I<regexp>

Add another input filter.  Future calls to B<peek> will strip
B<last_prefix> and I<regexp> from the beginning of all lines.

=item B<pop_filter>

Remove top-most input filter.

=back

=head1 AUTHORS

Enno Cramer, Mikhael Goikhman

=head1 SEE ALSO

L<Text::WikiText>

=cut
