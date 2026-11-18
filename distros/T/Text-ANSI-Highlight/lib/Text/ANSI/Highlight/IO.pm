package Text::ANSI::Highlight::IO;

use v5.16;
use warnings;

use IO::Factotum;
use Text::ANSI::Highlight;

# Give a highlighter to IO::Factotum: the files which are opened by it
# are read in the colors of the highlighter.  The arguments are those
# of Text::ANSI::Highlight->new.
sub setup {
    my $class = shift;
    IO::Factotum::register(with => Text::ANSI::Highlight->new(@_));
    return;
}

# use Text::ANSI::Highlight::IO: the files which are read by <> are
# read by IO::Factotum
sub import {
    my $class = shift;
    $class->setup(@_);
    IO::Factotum::tie_argv();
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Highlight::IO - read source files in colors, in a program as it is

=head1 SYNOPSIS

From one-liners:

    perl -MText::ANSI::Highlight::IO -ne 'print' file.c file.pl

    perl -MText::ANSI::Highlight::IO=gnu -pe 's/^/> /' README.md

From a script:

    use Text::ANSI::Highlight::IO with => 'pandoc';

    while (<>) {
        ...
    }

In a program which opens its files by L<IO::Factotum>:

    use Text::ANSI::Highlight::IO ();
    Text::ANSI::Highlight::IO->setup('pandoc');

    my $fh = IO::Factotum::open_input($file);

=head1 DESCRIPTION

With this module, a program which reads files by C<E<lt>E<gt>> reads
them in colors, the syntax highlight of L<Text::ANSI::Highlight>, and
nothing of the program has to be changed.  A file whose language is
not known is read as it is, and so is the standard input.  C<$ARGV>,
C<$.> and C<eof> work as usual.

It does not color by itself, and does not read files by itself.  It
gives a highlighter of L<Text::ANSI::Highlight> to L<IO::Factotum>,
which reads files through what it is given, and makes C<E<lt>E<gt>>
read by L<IO::Factotum>.  Neither of the two knows the other.

The arguments are those of C<< Text::ANSI::Highlight->new >>:
C<< with => I<name> >> is the highlighter, and C<with> can be left
out for the first argument.  Without it, the highlighter is the
default, C<pandoc>.

    use Text::ANSI::Highlight::IO;                  # pandoc
    use Text::ANSI::Highlight::IO 'gnu';            # sourcehighlight
    use Text::ANSI::Highlight::IO with => 'sky';    # skylighting

A file which is opened by C<open> is not read through it: only the
files of C<E<lt>E<gt>>, and those which are opened by
C<IO::Factotum::open_input>.

=head1 METHODS

=over 4

=item B<import>(I<arguments>)

Called by C<use>.  Give the highlighter to L<IO::Factotum>, and make
C<E<lt>E<gt>> read by it (C<IO::Factotum::tie_argv>).

A program which takes the highlighter from its options can load the
module without it, and call this later:

    use Text::ANSI::Highlight::IO ();
    ...
    Text::ANSI::Highlight::IO->import($name) if defined $name;

=item B<setup>(I<arguments>)

Give the highlighter to L<IO::Factotum>, and leave C<E<lt>E<gt>> as
it is.  For a program which opens its files by
C<IO::Factotum::open_input>.

=back

=head1 SEE ALSO

L<Text::ANSI::Highlight>, L<IO::Factotum>

L<ARGV::URL> makes C<E<lt>E<gt>> read URLs in the same way, by being
loaded.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
