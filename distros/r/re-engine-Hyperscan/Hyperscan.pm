package re::engine::Hyperscan;
our ($VERSION, $XS_VERSION);
BEGIN {
  $VERSION = '0.03';
  $XS_VERSION = $VERSION;
  $VERSION = eval $VERSION;
}
use 5.010;
use strict;
use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN {
  XSLoader::load;
}

sub import {
  $^H{regcomp} = ENGINE;
}

sub unimport {
  delete $^H{regcomp} if $^H{regcomp} == ENGINE;
}

1;

__END__

=head1 NAME 

re::engine::Hyperscan - High-performance regular expression matching library (Intel only)

=head1 SYNOPSIS

    use re::engine::Hyperscan;

    if ("Hello, world" =~ /(Hello|Hi), (world)/) {
        print "Greetings, $1!";
    }

=head1 DESCRIPTION

ALPHA - Does not work YET

Replaces perl's regex engine in a given lexical scope with Intel's 
Hyperscan regular expressions provided by F<libhyperscan>.

This provides the fastest regular expression library on Intel-CPU's
only, but needs to fall back to the core perl regexp compiler with
backtracking, lookbehind, zero-width assertions and more advanced
patterns.  It is typically 50% faster then the core regex engine.

For the supported syntax see
L<https://01org.github.io/hyperscan/dev-reference/compilation.html>.

With the following unsupported constructs in the pattern, the compiler
will fall back to the core re engine:

=over

=item Backreferences and capturing sub-expressions.

=item Arbitrary zero-width assertions.

=item Subroutine references and recursive patterns.

=item Conditional patterns.

=item Backtracking control verbs.

=item The C<\C> "single-byte" directive (which breaks UTF-8 sequences).

=item The C<\R> newline match.

=item The C<\K> start of match reset directive.

=item Callouts and embedded code.

=item Atomic grouping and possessive quantifiers.

=back

=head1 METHODS

=over

=item min_width (RX)

Returns the result from hs_expression_info(). NYI
The minimum length in bytes of a match for the pattern.

=item max_width (RX)

Returns the result from hs_expression_info(). NYI
The maximum length in bytes of a match for the pattern. If the pattern
has an unbounded maximum width, this will be set to the maximum value of
an unsigned int (UINT_MAX).

=item unordered_matches (RX)

Returns the result from hs_expression_info(). NYI
Whether this expression can produce matches that are not returned in
order, such as those produced by assertions.

=item matches_at_eod (RX)

Returns the result from hs_expression_info(). NYI
Whether this expression can produce matches at end of data (EOD).

=item matches_only_at_eod (RX)

Returns the result from hs_expression_info(). NYI
Whether this expression can *only* produce matches at end of data (EOD).

=back

=head1 FUNCTIONS

=over

=item ENGINE

Returns a pointer to the internal Hyperscan engine, the database,
suitable for the XS API C<<< (regexp*)re->engine >>> field.

=back

=head1 AUTHORS

Reini Urban <rurban@cpan.org>

=head1 COPYRIGHT

Copyright 2017 Reini Urban.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
