package Text::ANSI::Printf;

our $VERSION = "2.05";

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&ansi_printf &ansi_sprintf);

sub ansi_printf  { &printf (@_) }
sub ansi_sprintf { &sprintf(@_) }

use Text::Conceal;
use Text::ANSI::Fold::Util qw(ansi_width);

our $REORDER = 0;

sub sprintf {
    my($format, @args) = @_;
    my $conceal = Text::Conceal->new(
	except    => $format,
	max       => int @args,
	test      => qr/[\e\b\P{ASCII}]/,
	length    => \&ansi_width,
	ordered   => ! $REORDER,
	duplicate => !!$REORDER,
	);
    $conceal->encode(@args) if $conceal;
    my $s = CORE::sprintf $format, @args;
    $conceal->decode($s)    if $conceal;
    $s;
}

sub printf {
    my $fh = ref($_[0]) =~ /^(?:GLOB|IO::)/ ? shift : select;
    $fh->print(&sprintf(@_));
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Printf - printf function for string with ANSI sequence

=head1 VERSION

Version 2.05

=head1 SYNOPSIS

    use Text::ANSI::Printf;
    Text::ANSI::Printf::printf FORMAT, LIST
    Text::ANSI::Printf::sprintf FORMAT, LIST

    use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
    ansi_printf FORMAT, LIST
    ansi_sprintf FORMAT, LIST

    $ ansiprintf format args ...

=head1 DESCRIPTION

B<Text::ANSI::Printf> is a almost-printf-compatible library with a
capability of handling:

    - ANSI terminal sequences
    - Multi-byte wide characters
    - Combining characters
    - Backspaces

You can give any string including these data as an argument for
C<printf> and C<sprintf> functions.  Each field width is calculated
based on its visible appearance.

For example,

    printf "| %-5s | %-5s | %-5s |\n", "Red", "Green", "Blue";

this code produces the output like:

    | Red   | Green | Blue  |

However, if the arguments are colored by ANSI sequence,

    printf("| %-5s | %-5s | %-5s |\n",
           "\e[31mRed\e[m", "\e[32mGreen\e[m", "\e[34mBlue\e[m");

this code produces undesirable result:

    | Red | Green | Blue |

This is still better because it is readable, but if the result is
shorter than the original string, for example, "%.3s", the result will
be disastrous.

C<ansi_printf> can be used to properly format colored text.

    use Text::ANSI::Printf 'ansi_printf';
    ansi_printf("| %-5s | %-5s | %-5s |\n",
           "\e[31mRed\e[m", "\e[32mGreen\e[m", "\e[34mBlue\e[m");

It does not matter if the result is shorter than the original text.
Next code produces C<[R] [G] [B]> in proper color.

    ansi_printf("[%.1s] [%.1s] [%.1s]\n",
           "\e[31mRed\e[m", "\e[32mGreen\e[m", "\e[34mBlue\e[m");

=head1 ARGUMENT REORDERING

The original C<printf> function has the ability to specify the
arguments to be targeted by the position specifier, but by default
this module assumes that the arguments will appear in the given order,
so you will not get the expected result. If you wish to use it, set
the package variable C<$REORDER> to 1.

    $Text::ANSI::Printf::REORDER = 1;

By doing so, the order in which arguments appear can be changed and
the same argument can be processed even if it appears more than once.

If you want to enable this feature only in specific cases, create a
wrapper function and declare C<$Text::ANSI::Printf::REORDER> as local
in it.

This behavior is experimental and may change in the future.

=head1 FUNCTIONS

=over 4

=item printf FORMAT, LIST

=item sprintf FORMAT, LIST

=item ansi_printf FORMAT, LIST

=item ansi_sprintf FORMAT, LIST

Use just like Perl's I<printf> and I<sprintf> functions
except that I<printf> does not take FILEHANDLE.

=back

=head1 IMPLEMENTATION NOTES

This module uses L<Text::Conceal> and L<Text::ANSI::Fold::Util>
internally.

=head1 CLI TOOLS

This package contains the L<ansiprintf(1)> command as a wrapper for
this module. By using this command from the command line interface,
you can check the functionality of L<Text::ANSI::Printf>.  See
L<ansiprintf(1)> or `perldoc ansiprintf`.

=head1 SEE ALSO

L<App::ansiprintf>

L<Term::ANSIColor::Concise>,
L<https://github.com/tecolicom/Term-ANSIColor-Concise>

L<Text::Conceal>,
L<https://github.com/kaz-utashiro/Text-Conceal>

L<Text::ANSI::Fold::Util>,
L<https://github.com/tecolicom/Text-ANSI-Fold-Util>

L<Text::ANSI::Printf>,
L<https://github.com/tecolicom/Text-ANSI-Printf>

L<App::ansicolumn>,
L<https://github.com/tecolicom/App-ansicolumn>

L<App::ansiecho>,
L<https://github.com/tecolicom/App-ansiecho>

L<https://en.wikipedia.org/wiki/ANSI_escape_code>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  printf ansi sprintf
