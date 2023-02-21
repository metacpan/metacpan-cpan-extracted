package Text::Wrap::NoStrip;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-18'; # DATE
our $DIST = 'Text-Wrap-NoStrip'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(
                       wrap
               );

our $columns = 76;

sub wrap {
    my $initial_indent = shift;
    my $subsequent_indent = shift;

    my @res = ($initial_indent);
    my $width = length($initial_indent);
    my $si_len = length($subsequent_indent);

    for my $text (@_) {
        my @chunks = split /(\R+|\s+)/, $text;
        #use DD; dd \@chunks;
        for my $chunk (@chunks) {
            if ($chunk =~ /\R/) {
                $width = 0;
                push @res, $chunk;
            } else {
              L1:
                my $len = length $chunk;
                #print "D:got chunk=<$chunk> ($len), width=$width, scalar(\@res)=".scalar(@res)."\n";
                if ($width + $len > $columns) {

                    # should we chop long word?
                    if ($chunk !~ /\s/ && $len > $columns - $si_len) {
                        my $s = substr($chunk, 0, $columns - $width);
                        #print "D:wrapping <$s>\n";
                        substr($chunk, 0, $columns - $width) = "";
                        push @res, $s, "\n$subsequent_indent";
                        $width = $si_len;
                        goto L1;
                    } else {
                        push @res, "\n$subsequent_indent", $chunk;
                        $width = $len;
                    }
                } else {
                    #print "D:adding <$chunk>\n";
                    push @res, $chunk;
                    $width += $len;
                }
            }
            #print "D:width=$width\n";
        }
    }

    join("", @res);
}

1;
# ABSTRACT: Line wrapping without stripping the whitespace

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Wrap::NoStrip - Line wrapping without stripping the whitespace

=head1 VERSION

This document describes version 0.003 of Text::Wrap::NoStrip (from Perl distribution Text-Wrap-NoStrip), released on 2023-02-18.

=head1 SYNOPSIS

Use like you would use L<Text::Wrap> (but currently only C<$columns> variable is
supported):

 use Text::Wrap::NoStrip qw(wrap);
 $Text::Wrap::NoStrip::columns = 80; # default 76
 print wrap('', '  ', @text);

=head1 DESCRIPTION

NOTE: Early implementaiton, no tab handling.

This module provides C<wrap()> variant that does not strip the whitespaces, to
make unfolding easier and capable of returning the original text. Contrast:

 # original $text
 longwordlongwordlongword word   word   word word

 # wrapped by Text::Wrap::wrap('', 'x', $text), with added quotes
 # 123456789012
 "longwordlongw"
 "xordlongword"
 "xword   word"
 "xword word"

 # wrapped by Text::Wrapp::NoStrip::wrap('', ' ', $text)
 "longwordlongw"
 "xordlongword"
 "x word   word"
 "x   word word"

To get back the original $text, you can do:

 ($text = $wrapped) =~ s/\nx//g;

=head1 FUNCTIONS

=head2 wrap

Usage:

 wrap($initial_indent, $subsequent_indent, @text); # => str

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Wrap-NoStrip>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Wrap-NoStrip>.

=head1 SEE ALSO

L<Text::Wrap>

Other wrapping modules, see L<Acme::CPANModules::TextWrapping>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Wrap-NoStrip>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
