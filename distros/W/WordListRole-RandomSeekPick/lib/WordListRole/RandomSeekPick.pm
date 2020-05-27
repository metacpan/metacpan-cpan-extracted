package WordListRole::RandomSeekPick;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-23'; # DATE
our $DIST = 'WordListRole-RandomSeekPick'; # DIST
our $VERSION = '0.004'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Role::Tiny;

sub pick {
    # why is still this necesary? does Role::Tiny enforce strict?
    no strict 'refs';

    my ($self, $n, $allow_duplicates) = @_;

    $n = 1 if !defined $n;
    die "Please don't pick too many items" if $n >= 10_000;

    my $class = $self->{orig_class} || ref($self);
    my $fh = \*{"$class\::DATA"};
    my $start = ${"$class\::DATA_POS"};
    my $end   = -s $fh;

    my (%items, @items);
    my $iter = 0;
    while (1) {
        if ($allow_duplicates) {
            last if @items >= $n;
        } else {
            last if keys(%items) >= $n;
        }

        seek $fh, $start + int(rand() * ($end-$start+1)), 0;
        <$fh>; # skip the line fragment
        seek $fh,0,0 if eof $fh; # wrap if hit EOF
        chomp(my $item = scalar <$fh>); # get the next line

        if ($allow_duplicates) {
            push @items, $item;
        } else {
            $items{$item}++;
            last if $iter++ > 50_000;
        }
    }

    if ($allow_duplicates) {
        return @items;
    } else {
        return keys %items;
    }
}

1;
# ABSTRACT: Provide a pick() implementation that random-seeks DATA

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListRole::RandomSeekPick - Provide a pick() implementation that random-seeks DATA

=head1 VERSION

This document describes version 0.004 of WordListRole::RandomSeekPick (from Perl distribution WordListRole-RandomSeekPick), released on 2020-05-23.

=head1 DESCRIPTION

The default L<WordList>'s C<pick()> performs a scan on the whole word list once
while collecting random items. This role provides an alternative implementation
that random-seeks on DATA, discard the line fragment, then get the next line.
This algorithm does not provide uniformly random picking, but for many cases it
should be random enough. It is faster if you have a huge word list and just want
to pick one or a few items.

Note: since this role's C<pick()> operates on the DATA filehandle directly
instead of using C<each_word()>, it cannot be used on dynamic wordlists.

=head1 PROVIDED METHODS

=head2 pick

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListRole-RandomSeekPick>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListRole-RandomSeekPick>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListRole-RandomSeekPick>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::RandomLine> provides a similar algorithm.

L<WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
