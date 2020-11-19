package Text::ANSI::Printf;

our $VERSION = "2.01";

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&ansi_printf &ansi_sprintf);

sub ansi_printf  { &printf (@_) }
sub ansi_sprintf { &sprintf(@_) }

use Text::Conceal;
use Text::ANSI::Fold::Util qw(ansi_width);

sub sprintf {
    my($format, @args) = @_;
    my $conceal = Text::Conceal->new(
	except => $format,
	test   => qr/[\e\b\P{ASCII}]/,
	length => \&ansi_width,
	max    => int @args,
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

Version 2.01

=head1 SYNOPSIS

    use Text::ANSI::Printf;
    Text::ANSI::Printf::printf FORMAT, LIST
    Text::ANSI::Printf::sprintf FORMAT, LIST

    use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
    ansi_printf FORMAT, LIST
    ansi_sprintf FORMAT, LIST

=head1 DESCRIPTION

B<Text::ANSI::Printf> is a almost-printf-compatible library with a
capability of handling:

    - ANSI terminal sequences
    - Multi-byte wide characters
    - Backspaces

=head1 FUNCTIONS

=over 4

=item printf FORMAT, LIST

=item sprintf FORMAT, LIST

=item ansi_printf FORMAT, LIST

=item ansi_sprintf FORMAT, LIST

Use just like perl's I<printf> and I<sprintf> functions
except that I<printf> does not take FILEHANDLE.

=back

=head1 IMPLEMENTATION NOTES

This module uses L<Text::Conceal> and L<Text::ANSI::Fold::Util>
internally.

=head1 SEE ALSO

L<Text::Conceal>,
L<https://github.com/kaz-utashiro/Text-Conceal>

L<Text::ANSI::Fold::Util>,
L<https://github.com/kaz-utashiro/Text-ANSI-Fold-Util>

L<Text::ANSI::Printf>,
L<https://github.com/kaz-utashiro/Text-ANSI-Printf>

L<App::ansicolumn>,
L<https://github.com/kaz-utashiro/App-ansicolumn>

L<https://en.wikipedia.org/wiki/ANSI_escape_code>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  printf ansi sprintf
