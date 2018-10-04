package XTerm::Util;

our $DATE = '2018-09-26'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @ISA       = qw();
our @EXPORT_OK = qw(
                       get_term_bgcolor
                       set_term_bgcolor
               );

our %SPEC;

$SPEC{get_term_bgcolor} = {
    v => 1.1,
    summary => 'Get terminal background color',
    description => <<'_',

Get the terminal's current background color, or undef if unavailable. This uses
the following xterm control sequence:

    \e]11;?\a

and a compatible terminal will issue back the same sequence but with the
question mark replaced by the RGB code, e.g.:

    \e]11;rgb:0000/0000/0000\a

I have tested this works on the following terminal software (and version) on
Linux:

    MATE Terminal (1.18.2)
    GNOME Terminal (3.18.3)
    Konsole (16.04.3)

And does not work with the following terminal software (and version) on Linux:

    LXTerminal (0.2.0)
    rxvt (2.7.10)

A 6-hexdigit RGB value will be returned, e.g.:

    000000
    310035

_
    args => {},
    result_naked => 1,
};
sub get_term_bgcolor {
    return undef unless -x "/bin/sh";

    require File::Temp;
    my ($fh1 , $fname1) = File::Temp::tempfile();
    my (undef, $fname2) = File::Temp::tempfile();

    my $script = q{#!/bin/sh
oldstty=$(stty -g)
stty raw -echo min 0 time 0
printf "\033]11;?\a"
sleep 0.00000001
read -r answer
result=${answer#*;}
stty $oldstty
echo $result >}.$fname2;

    print $fh1 $script;
    close $fh1;
    system {"/bin/sh"} "/bin/sh", $fname1;

    my $out = do {
        local $/;
        open my $fh2, "<", $fname2;
        scalar <$fh2>;
    };

    my $rgb;
    if ($out =~ m!rgb:([0-9A-Fa-f]{4})/([0-9A-Fa-f]{4})/([0-9A-Fa-f]{4})\a!) {
        $rgb = substr($1, 0, 2) . substr($2, 0, 2) . substr($3, 0, 2);
    }
    unlink $fname1, $fname2;
    $rgb;
}

$SPEC{set_term_bgcolor} = {
    v => 1.1,
    summary => 'Set terminal background color',
    description => <<'_',

Set terminal background color. This prints the following xterm control sequence
to STDOUT (or STDERR, if ~stderr~ is set to true:

    \e]11;#123456\a

where *123456* is the 6-hexdigit RGB color code.

_
    args_as => 'array',
    args => {
        rgb => {
            schema => 'color::rgb24*',
            req => 1,
            pos => 0,
        },
        stderr => {
            schema => 'true*',
            pos => 1,
        },

    },
    result_naked => 1,
};
sub set_term_bgcolor {
    my ($rgb, $stderr) = @_;
    $rgb =~ s/\A#?([0-9A-Fa-f]{6})\z/$1/
        or die "Invalid RGB code '$rgb'";

    local $| = 1;
    my $str = "\e]11;#$rgb\a";
    if ($stderr) {
        print STDERR $str;
    } else {
        print $str;
    }
    return;
}

1;
# ABSTRACT: Utility routines for xterm-compatible terminal (emulator)s

__END__

=pod

=encoding UTF-8

=head1 NAME

XTerm::Util - Utility routines for xterm-compatible terminal (emulator)s

=head1 VERSION

This document describes version 0.003 of XTerm::Util (from Perl distribution XTerm-Util), released on 2018-09-26.

=head1 SYNOPSIS

 use XTerm::Util qw(
     get_term_bgcolor
     set_term_bgcolor
 );

 # when you're on a black background
 say get_term_bgcolor(); # => "000000"

 # when you're on a dark purple background
 say get_term_bgcolor(); # => "310035"

 # set terminal background to dark blue
 set_term_bgcolor("00002b");

=head1 DESCRIPTION

Keywords: xterm, xterm-256color, terminal

=head1 FUNCTIONS


=head2 get_term_bgcolor

Usage:

 get_term_bgcolor() -> any

Get terminal background color.

Get the terminal's current background color, or undef if unavailable. This uses
the following xterm control sequence:

 \e]11;?\a

and a compatible terminal will issue back the same sequence but with the
question mark replaced by the RGB code, e.g.:

 \e]11;rgb:0000/0000/0000\a

I have tested this works on the following terminal software (and version) on
Linux:

 MATE Terminal (1.18.2)
 GNOME Terminal (3.18.3)
 Konsole (16.04.3)

And does not work with the following terminal software (and version) on Linux:

 LXTerminal (0.2.0)
 rxvt (2.7.10)

A 6-hexdigit RGB value will be returned, e.g.:

 000000
 310035

This function is not exported by default, but exportable.

No arguments.

Return value:  (any)


=head2 set_term_bgcolor

Usage:

 set_term_bgcolor($rgb, $stderr) -> any

Set terminal background color.

Set terminal background color. This prints the following xterm control sequence
to STDOUT (or STDERR, if ~stderr~ is set to true:

 \e]11;#123456\a

where I<123456> is the 6-hexdigit RGB color code.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$rgb>* => I<color::rgb24>

=item * B<$stderr> => I<true>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/XTerm-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-XTerm-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=XTerm-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Color::ANSI::Util>

XTerm control sequence:
L<http://invisible-island.net/xterm/ctlseqs/ctlseqs.html>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
