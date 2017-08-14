package Text::WordDiff::Unified::ANSIColor;

our $DATE = '2017-08-12'; # DATE
our $VERSION = '0.002'; # VERSION

## no critic (Modules::ProhibitAutomaticExportation)

# based on MojoMojo::WordDiff, which in turn was based on Text::WordDiff

use strict;
use warnings;
use base qw(Exporter);
use Algorithm::Diff;

our @EXPORT = qw(word_diff);

our %colors = (
    delete_line => "\e[31m",
    insert_line => "\e[32m",
    delete_word => "\e[7m",
    insert_word => "\e[7m",
);

sub _split_str {
    split //, $_[0];
}

sub word_diff {
    my @args = map {my @a = _split_str($_); \@a;} @_;
    my $diff = Algorithm::Diff->new(@args);
    my $out1 = "";
    my $out2 = "";
    while ($diff->Next) {
        if (my @same = $diff->Same) {
            $out1 .= (join '', @same);
            $out2 .= (join '', @same);
        } else {
            if (my @del = $diff->Items(1)) {
                $out1 .= $colors{delete_word} . (join '', @del) . "\e[0m" . $colors{delete_line};
            }
            if (my @ins = $diff->Items(2)) {
                $out2 .= $colors{insert_word} . (join '', @ins) . "\e[0m" . $colors{insert_line};
            }
        }
    }

    $out1 =~ s/^/$colors{delete_line}-/gm;
    $out1 =~ s/$/\e[0m/gm;
    $out2 =~ s/^/$colors{insert_line}+/gm;
    $out2 =~ s/$/\e[0m/gm;

    $out1 . $out2;
}

1;
# ABSTRACT: Generate unified-style word-base ANSIColor diffs

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::WordDiff::Unified::ANSIColor - Generate unified-style word-base ANSIColor diffs

=head1 VERSION

This document describes version 0.002 of Text::WordDiff::Unified::ANSIColor (from Perl distribution Text-WordDiff-Unified-ANSIColor), released on 2017-08-12.

=head1 SYNOPSIS

 use Text::WordDiff::Unified::ANSIColor;

 say word_diff "line 1", "line 2";

Sample output (color shown using <I<color>> and <I</color>>):

 <red>-line <reverse>1</reverse></red>
 <green>+line <reverse>2</reverse></green>

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 word_diff

Usage: word_diff($str1, $str2) => str

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-WordDiff-Unified-ANSIColor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-WordDiff-Unified-ANSIColor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-WordDiff-Unified-ANSIColor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::WordDiff>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
