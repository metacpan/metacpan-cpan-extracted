package Text::Levenshtein::Flexible;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw/
        levenshtein
        levenshtein_c
        levenshtein_l
        levenshtein_lc
        levenshtein_l_all
        levenshtein_lc_all
        /
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.09';

require XSLoader;
XSLoader::load('Text::Levenshtein::Flexible', $VERSION);

sub levenshtein_l_all {
    Text::Levenshtein::Flexible->new(shift)->distance_l_all(@_);
}

sub levenshtein_lc_all {
    Text::Levenshtein::Flexible->new(splice(@_, 0, 4))->distance_lc_all(@_);
}

1;
__END__

=encoding UTF-8

=head1 NAME

Text::Levenshtein::Flexible - XS Levenshtein distance calculation with bounds and costs

=head1 SYNOPSIS

  use Text::Levenshtein::Flexible;

=head1 DESCRIPTION

Yet another Levenshtein module written in C, but a tad more flexible than the rest.

This module uses code from PostgreSQL's levenshtein distance function to
provide the following features on top of plain distance calculation as it is
done by Levenshtein::XS and others:

=over 4

=item Distance-limited calculation: if a certain maximum distance is exceeded,
the algorithm aborts without result. This helps performance in situations where
it is clear that results over a certain maximum are not useful.

=item Configurable costs for insert, delete ans substitute operations. The
traditional Levenshtein algorithm assumes equal cost for insertion and deletion
but modifying these allows preferential correction of certain errors.

=back

=head2 EXPORT

Nothing is exported by default.

=head2 Exportable

The following functions can be exported upon request, e.g.:

    use Text::Levenshtein::Flexible qw( levenshtein levenshtein_l_all );

=over 4

=item C<levenshtein>

=item C<levenshtein_c>

=item C<levenshtein_l>

=item C<levenshtein_lc>

=item C<levenshtein_l_all>

=item C<levenshtein_lc_all>

=back

=head2 Procedural interface

The functions listed under L</Exportable> consitute the module's procedural
API. Neither the names nor the huge parameter lists are particularly pretty so
the OO interface is usually recommended.

=head3 levenshtein($src, $dst)

Plain Levenshtein distance calculation between the two strings C<$src> and C<$dst>.
Always returns an integer. If the strings are too long (currently there is a
hard-coded limit of 255 characters), the function may C<die()>, so call it in an
eval block if this is a possibility.

=head3 levenshtein_c($src, $dst, $cost_ins, $cost_del, $cost_sub)

Distance between the two strings C<$src> and C<$dst> using the specified costs for
insertion, deletion and substitution respectively. Always returns an integer
unless it dies.

=head3 levenshtein_l($src, $dst, $max_distance)

Distance between C<$src> and C<$dst> unless it is bigger than C<$max_distance>
(think C<_l>imit!), in which case C<undef> is returned. May die just like the
other functions.

=head3 levenshtein_lc($src, $dst, $max_distance, $cost_ins, $cost_del, $cost_sub)

Distance between C<$src> and C<$dst> using the specified costs, up to C<$max_distance>,

=head3 levenshtein_l_all($max_distance, $src, @dst)

For an array C<@dst> of strings, return all that are up to C<$max_distance>
from C<$src>. The result is a list of 2-element arrays consisting of
string-distance pairs. To get a list of strings sorted by distance:

    map { $_->[0] }
    sort { $a->[1] <=> $b->[1] }
    levenshtein_l_all(2, "bar", "foo", "blah", "baz");

Note that since the C<*_all> functions were converted to XS as well, this
function delegates to the OO version internally to avoid too much XS code
duplication, so the OO interface is preferable for this in any case.

=head3 levenshtein_lc_all($max_distance, $cost_ins, $cost_del, $cost_sub, $src, @dst)

For an array C<@dst> of strings, return all that are up to C<$max_distance>
from C<$src> when using the specified costs as in levenshtein_c. The result is
the same as for C<levenshtein_l_all> and the remark about the OO version
applies equally here.

Note that there is no C<levenshtein_all()> function because it is trivial to
write using C<map>.

=head2 Object-oriented interface

The OO API will usually be more convenient except for trivial calculations
because it allows to specify limits and costs once and pass only variable data
to object methods. Being implemented in C/XS it is just as fast as the
procedural one, or faster in the case of the list functions.

=head3 new($max_distance, $cost_ins, $cost_del, $cost_sub)

All four constructor arguments are optional but must be defined if they are
used, i.e. you have to specify a number for C<$max_distance> if you want to use
the costs. Pass 1 for costs and some number over 255 times the largest of the
cost values for C<$max_distance> (passing something significantly bigger
doesn't hurt, in case the hardcoded limit for calculations should grow some
day) if you don't care.

=head3 distance($src, $dst)

Just for orthogonality, this does the same as C<levenshtein()>.

=head3 distance_c($src, $dst)

Just like C<levenshtein_c()> but using the previously specified costs.

=head3 distance_l($src, $dst)

C<levenshtein_l()>'s modern brother.

=head3 distance_lc($src, $dst, $max_distance, $cost_ins, $cost_del, $cost_sub)

The nicer variant of C<levenshtein_lc()>.

=head3 distance_l_all($src, @dst)

Not quite as ugly but otherwise equivalent to C<levenshtein_l_all()>.

=head3 distance_lc_all($src, @dst)

Where C<levenshtein_lc_all()> gets really nasty, this does the same in a saner way.

Of course there's no C<distance_all()> method either.

=head2 Speed

According to a few completely made-up benchmarks,
L<Text::Levenshtein::Flexible> is at least as fast as either
L<Text::Levenshtein::XS>, L<Text::LevenshteinXS> or L<Text::Fuzzy> (Core i7
920) and between 25% and 48% faster on some systems (Phenom II X6 1090T). A
small benchmark script is included to test on your system, I'd be interested to
hear about any unexpectedly good or bad performance.

=head1 SEE ALSO

L<Text::Levenshtein::XS>

Dont even bother with anything else unless you're more interested in the
algorithm than in practical applications as the algorithm is one of the better
examples for something reasonably efficient in C that Perl is terrible at.

To find this module's lastest updates that are not on CPAN yet, check
L<https://github.com/mbethke/Text-Levenshtein-Flexible>

=head1 ACKNOWLEDGEMENTS

All the credit for speed and algorithmic cleverness goes to Joe Conway and
Volkan Yazici who wrote the bulk of this module's code, originally for
PostgreSQL.

=head1 AUTHOR

Matthias Bethke, E<lt>matthias@towiski.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Matthias Bethke

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.14.2 or, at your option,
any later version of Perl 5 you may have available. Significant portions of the
code are (C) PostgreSQL Global Development Group and The Regents of the
University of California. All modified versions must retain the file COPYRIGHT
included in the distribution.

=cut
