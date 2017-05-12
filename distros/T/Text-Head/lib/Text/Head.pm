package Text::Head;

our $DATE = '2016-04-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter::Rinci qw(import);

our %SPEC;

# TODO: accept filehandle in addition to string
# TODO: mode characters/bytes
# TODO: record separator option
# TODO: accept negative number (-N), which means all but last N lines of file

$SPEC{head_text} = {
    v => 1.1,
    summary => 'Output the first part of text',
    args => {
        text => {
            schema => 'str*',
            req => 1,
        },
        lines => {
            schema => 'int*',
            default => 10,
        },
        hint => {
            schema => 'bool',
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {text=>"line 1\nline 2\nline 3\nline 4\n", lines=>2},
            result => "line 1\nline 2\n",
        }
    ],
};
sub head_text {
    my %args = @_;

    my $lines = $args{lines} // 10;

    my @lines = split /^/, $args{text};
    if ($lines >= @lines) {
        return $args{text};
    } else {
        my $remaining = @lines - $lines;
        my $res = join("", @lines[0..$lines-1]);
        if ($args{hint}) {
            $res .= "\n" unless $res =~ /\R\z/;
            $res .= "(... $remaining more line(s) not shown ...)\n";
        }
        return $res;
    }
}

1;
# ABSTRACT: Output the first part of text

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Head - Output the first part of text

=head1 VERSION

This document describes version 0.001 of Text::Head (from Perl distribution Text-Head), released on 2016-04-01.

=head1 FUNCTIONS


=head2 head_text(%args) -> any

Output the first part of text.

Examples:

=over

=item * Example #1:

 head_text(lines => 2, text => "line 1\nline 2\nline 3\nline 4\n"); # -> "line 1\nline 2\n"

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<hint> => I<bool>

=item * B<lines> => I<int> (default: 10)

=item * B<text>* => I<str>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Head>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Head>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Head>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The L<head> Unix command.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
