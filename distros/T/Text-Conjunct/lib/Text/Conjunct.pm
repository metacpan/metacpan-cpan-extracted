##==============================================================================
## Text::Conjunct - join lists of items together
##==============================================================================
## $Id: Conjunct.pm,v 1.0 2004/05/23 05:44:28 kevin Exp $
##==============================================================================
require 5.006;

package Text::Conjunct;
use strict;
use warnings;
our ($VERSION) = q$Revision: 1.0 $ =~ /Revision:\s+(\S+)/ or $VERSION = "0.0";
use base qw(Exporter);
our @EXPORT = qw(conjunct);

our $SERIAL_COMMA = 1;

=pod

=head1 NAME

Text::Conjunct - join lists of items together

=head1 SYNOPSIS

C<< use Text::Conjunct; >>

C<< print conjunct "and", "3 apples", "2 pears", "no oranges"; >>

prints

C<< 3 apples, 2 pears, and no oranges >>

=head1 DESCRIPTION

Text::Conjunct joins strings together with a conjunction, typically "and" or
"or".

=over 4

=item *

If there is only one string, it is just returned.

=item *

If there are two strings, they are returned with the supplied conjunction
between them.

=item *

If there are three or more strings, all but the last are separated by commas.
The separator between the second-to-last and the last is the conjunction,
possibly with a comma preceding it (see L<"SERIAL COMMAS"> below).

=back

=head1 EXPORTED ROUTINE

=over 4

=item conjunct

C<< I<$string> = conjunct I<$conjunction>, I<@list>; >>

Returns the strings conjoined as explained above. I<$conjunction> can be any
string, which can yield nonsensical results; generally it will be "and" or "or".

=back

=head1 EXAMPLES

=over 4

=item C<< conjunct "and", "one apple" >>

C<< one apple >>

=item C<< conjunct "and", "one apple", "two oranges" >>

C<< one apple and two oranges >>

=item C<< conjunct "and", "one apple", "two oranges", "three pears" >>

C<< one apple, two oranges, and three pears >>

=back

=head1 SERIAL COMMAS

Text::Conjunct defaults to placing a comma before the final conjunction if there
are more than two connected phrases (William Strunk Jr. and E.B. White, I<The
Elements of Style>, rule 2). This is commonly called the I<serial comma>. Many
people, however, omit this comma. I am not one of them, because this seems
illogical to me, and frequently results in unintended ambiguity. Compare

=over 4

I'd like to thank my parents, Ayn Rand and God.

=back

with

=over 4

I'd like to thank my parents, Ayn Rand, and God.

=back

and see which you think makes more sense. Commas in writing generally reflect
pauses in speech, and pretty much everybody except the children of Ayn Rand and
God will pause between those two terms.

But this is Perl, where the standard dogma is that we don't do dogma. You can
set the global variable C<$Text::Conjunct::SERIAL_COMMA> to reflect your
preference or requirements. It defaults to 1 to reflect my personal preference,
but you can set it to zero if you would rather do it the other way.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Kevin Michael Vail

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Kevin Michael Vail <F<kevin>@F<vaildc>.F<net>>

=cut

##==============================================================================
## conjunct
##==============================================================================
sub conjunct ($@) {
	my $conjunction = shift;

	return shift if @_ <= 1;

	return join(" $conjunction ", @_) if @_ == 2;

	my $final = pop @_;
	my $temp = join ', ', @_;
	$temp .= ',' if $SERIAL_COMMA;

	join " $conjunction ", $temp, $final;
}

1;

##==============================================================================
## $Log: Conjunct.pm,v $
## Revision 1.0  2004/05/23 05:44:28  kevin
## Initial revision
##
##==============================================================================
