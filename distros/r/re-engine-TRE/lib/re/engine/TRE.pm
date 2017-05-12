package re::engine::TRE;
# ABSTRACT: TRE regular expression engine


use strict;
use utf8;
use warnings qw(all);

use 5.010000;
use Scalar::Util qw(looks_like_number);
use XSLoader ();

# All engines should subclass the core Regexp package
our @ISA = 'Regexp';

BEGIN {
    our $VERSION = '0.09'; # VERSION
    XSLoader::load __PACKAGE__, $VERSION;
}


sub import {
    shift;

    $^H{regcomp} = ENGINE;

    if (@_) {
        my %args = @_;
        $^H{__PACKAGE__ . '::' . $_} =
            $args{$_} < 0
                ? 0x7fff
                : int($args{$_})
            for grep {
                exists $args{$_}
                and looks_like_number($args{$_})
            } qw(
                cost_ins
                cost_del
                cost_subst
                max_cost
                max_ins
                max_del
                max_subst
                max_err
            );
    }
}

sub unimport {
    delete $^H{regcomp}
        if $^H{regcomp} == ENGINE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

re::engine::TRE - TRE regular expression engine

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use re::engine::TRE max_cost => 1;

    if ("A pearl is a hard object produced..." =~ /\(Perl\)/i) {
        say $1; # "pearl"
    }

=head1 DESCRIPTION

Replaces Perl's regex engine in a given lexical scope with POSIX
regular expressions provided by the TRE regular expression
library. L<tre-0.8.0|http://laurikari.net/tre/download/> is shipped with this module.

=head1 PRAGMA OPTIONS

=over 4

=item *

C<cost_ins>: The default cost of an inserted character, that is, an extra character in string (default: 1).

=item *

C<cost_del>: The default cost of a deleted character, that is, a character missing from string (default: 1).

=item *

C<cost_subst>: The default cost of a substituted character (default: 1).

=item *

C<max_cost>: The maximum allowed cost of a match. If this is set to zero, an exact matching is searched for (default: 0).

=item *

C<max_ins>: Maximum allowed number of inserted characters (default: unspecified).

=item *

C<max_del>: Maximum allowed number of deleted characters (default: unspecified).

=item *

C<max_subst>: Maximum allowed number of substituted characters (default: unspecified).

=item *

C<max_err>: Maximum allowed number of errors (inserts + deletes + substitutes; default: unspecified).

=back

Set any value to C<-1> to represent "unspecified, but very high".

=head1 REFERENCES

=head2 Algorithm & Implementation

=over 4

=item *

L<Bitap algorithm|https://en.wikipedia.org/wiki/Bitap>

=item *

L<Introduction to the TRE regexp matching library.|http://laurikari.net/tre/about/>

=back

=head2 Salvaged several parts from

=over 4

=item *

L<re::engine::PCRE> (recent Perl compatibility)

=item *

L<re::engine::RE2> (parameter passing)

=item *

L<String::Approx> (tests for approximate matching)

=back

=for Pod::Coverage ENGINE

=head1 AUTHOR

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ævar Arnfjörð Bjarmason.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
