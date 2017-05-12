##==============================================================================
## Text::Pluralize - simple pluralization routine
##==============================================================================
## $Id: Pluralize.pm,v 1.1 2007/08/08 02:14:03 kevin Exp $
##==============================================================================
require 5.006001;
package Text::Pluralize;
use strict;
use warnings;
our $VERSION = '1.1';

use base qw(Exporter);

##==============================================================================
## Exported Items
##==============================================================================
our @EXPORT = qw(pluralize);

##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
##==============================================================================
## pluralize
##==============================================================================
sub pluralize ($$;@) {
	my ($template, $count) = splice @_, 0, 2;
	my $output = '';
	my $control_count = 0;

	while (
		$template =~ /
			^([^({]*)			## leading string up to a ( or {
			 ((?:				## either
			    \([^|)}]*[)}]	## ( string )
			  |					## or
			    [({][^|]*		## ( or { up to the first |
			    (?:\|[^|)}]*)+	## one or more | followed by non-|, ), or }
			    [)}]			## closing ) or }
			 ))
			 (.*)$				## and then the rest of the string
		/xs
	) {
		++$control_count;
		$output .= $1;
		$template = $3;
		my $pattern = $2;
		my @alternatives;
		if ($pattern =~ /^\((.*)[)}]$/) {
			@alternatives = split /\|/, $1;
			push @alternatives, '' if $1 =~ /\|$/;
			unshift @alternatives, '' if @alternatives == 1;
			unshift @alternatives, $alternatives[-1];
		} elsif ($pattern =~ /^\{(.*)[})]$/) {
			@alternatives = split /\|/, $1;
			push @alternatives, '' if $1 =~ /\|$/;
		} else {
			$output .= $pattern;
			--$control_count;
			next;
		}
		if ($count >= $#alternatives || $count < 0) {
			$output .= $alternatives[-1];
		} else {
			$output .= $alternatives[$count];
		}
	}
	$output .= $template;

	if ($control_count == 0 && $count != 1) {
		$output .= 's';
	}

	$output = sprintf $output, $count, @_ if $output =~ /%/;

	return $output;
}

##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

1;

__END__

=pod

=for Tk::PodView tuck:0,tabstop:4

=head1 NAME

Text::Pluralize - simple pluralization routine

=head1 SYNOPSIS

	use Text::Pluralize;
	
	print pluralize("file", $count);
	print pluralize("%d file(s) copied\n"), $count;
	print pluralize("There (was|were) {no|one|%d} error(s)\n", $count);

=head1 DESCRIPTION

C<Text::Pluralize> provides a lightweight routine to produce the proper form, 
singular or plural, of a word or phrase. Its intended purpose is to produce 
messages for the user, whether error messages or informational messages, without
the awkward "1 file(s) copied" appearance.

=head1 EXPORTED ROUTINE

=over 4

=item pluralize

C<< I<$string> = pluralize(I<$template>, I<$count>); >>

Returns I<$template> customized by I<$count>. I<$template> may contain items 
matching the following formats:

=over 4

=item C<< (I<s1>|I<pl>) >>

If I<$count> is equal to one, I<s1> will appear here; otherwise I<$pl> will 
appear at this point in the output. Either I<s1> or I<pl> can be empty.

=item C<< (I<pl>) >>

If I<$count> is not equal to one, the string I<pl> will appear at this point in 
the output. This is equivalent to C<< (|I<pl>) >>.

=item C<< (I<s1>|I<s2>|...|I<pl>) >>

This can be generalized. I<s1> is used if I<$count> is equal to one, I<s2> if 
the count is equal to two, and so forth; I<pl> is used for anything greater than
the last specific string applied.

=item C<< {I<s0>|I<s1>|I<pl>} >>

With curly braces, the choices start at zero. I<s0> is used if I<$count> is 
zero, I<s1> if it's one, and I<pl> if it's anything else.

=item C<< {I<s0>|I<s1>|I<s2>|...|I<pl>} >>

As with the parenthesized version, this can be generalized.

=back

If none of the above substitutions appear in I<$template>, it is treated as if 
it ended in C<< (s) >>.

Once the above substitutions have been applied, the result is examined to see if
it contains any C<%> characters. If so, it is used as a format for 
L<sprintf|perlfunc/sprintf>, with the count and any other arguments passed to 
B<pluralize>. This means that if you have a C<%> in your template that is I<not>
supposed to be a format character, you must specify C<%%> instead.

=back

=head1 EXAMPLES

In each of the examples below, the first column represents the template, the 
second column the count, and the third column the result.

	item                            0   items
	                                1   item
	                                2   items

	item(s) need{|s|} attention     0   items need attention
	                                1   item needs attention
	                                2   items need attention

	{No|%d} quer(y|ies) (is|are)    0   No queries are
	                                1   1 query is
	                                2   2 queries are

	{No|One|Two|Three|%d} item(s)   0   No items
	                                1   One item
	                                2   Two items
	                                3   Three items
	                                4   4 items

=head1 NOTE

If the brackets for a substitution don't match up, the one on the left controls 
what happens.

=head1 HISTORY

=for Tk::PodView tuck:1

=over 4

=item 1.0

Initial version

=item 1.1

Fix a problem with format strings containing newlines.

=back

=for Tk::PodView tuck:restore

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Kevin Michael Vail, all rights reserved

This library is free software. You may modify and/or redistribute it under the 
same terms as Perl itself.

=head1 AUTHOR

Kevin Michael Vail <kvail@cpan.org>

