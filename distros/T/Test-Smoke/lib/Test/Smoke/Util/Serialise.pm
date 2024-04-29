package Test::Smoke::Util::Serialise;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw( serialise );

=head1 NAME

Test::Smoke::Util::Serialise - Serialise (stringify) values, a bit like
L<Data::Dumper>.

=head1 SYNOPSIS

    use Test::Smoke::Util::Serialise 'serialise';

    my $value = [ qw( one two three ) ];
    printf "Looks like: '%s'\n", serialise($value);
    # Looks like: '[one, two, three]'\n

=head1 DESCRIPTION

Mostly looks like L<Data::Dumper::Dumper>, with C<$Indent = 0>, C<$Sortkeys = 1>
and C<$Terse = 1>.

=head2 serialise($to_serialise)

Make a string representation of the argument passed.

Arrays are represented with enclosing square brackets

Hashes are represented with enclosing curly braces, where all te Key-Value-pairs
have enclosing parenthesis with a C<< => >> (fat comma) in-between.

    {(one => two), (three => [four, five]), (six => {(seven => eight)}, (nine => \ten))}

=head3 Arguments

Positional:

=over

=item 1. B<$to_serialise>

=back

=head3 Responses

A string representation of the value passed.

=cut

sub serialise {
    my ($to_serialise) = @_;

    GIVEN {
        local $_ = ref($to_serialise);

        m{^ SCALAR $}x and do {
            return "\\" . serialise($$to_serialise);
        };
        m{^ ARRAY $}x and do {
            return sprintf(
                "[%s]",
                join(", ", map { serialise($_) } @$to_serialise)
            );
        };
        m{^ HASH $}x and do {
            return sprintf(
                "{%s}",
                join(
                    ", ",
                    map {
                        sprintf("(%s => %s)", $_, serialise($to_serialise->{$_}))
                    } sort keys %$to_serialise
                )
            );
        };
        # default, trust stringify
        do {
            return defined($to_serialise) ? "$to_serialise" : undef;
        };
    }
}

1;

=head1 COPYRIGHT

(c) 2020, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
