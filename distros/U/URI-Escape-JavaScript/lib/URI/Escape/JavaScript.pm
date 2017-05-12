package URI::Escape::JavaScript;

use strict;
use 5.8.1;
use warnings;
our $VERSION = '0.04';
use Encode qw(encode FB_PERLQQ);
use base qw(Exporter);
our @EXPORT    = qw(js_escape js_unescape);
our @EXPORT_OK = qw(escape unescape);

sub escape {
    my $string = shift;
    $string =~ s{([\x00-\x29\x2C\x3A-\x40\x5B-\x5E\x60\x7B-\x7F])}
                {'%' . uc(unpack('H2', $1))}eg; # XXX JavaScript compatible
    $string = encode('ascii', $string, sub { sprintf '%%u%04X', $_[0] });
    return $string;
}

sub unescape {
    my $escaped = shift;
    $escaped =~ s/%u([0-9a-f]{4})/chr(hex($1))/eig;
    $escaped =~ s/%([0-9a-f]{2})/chr(hex($1))/eig;
    return $escaped;
}

*js_escape   = \&escape;
*js_unescape = \&unescape;

1;
__END__

=head1 NAME

URI::Escape::JavaScript - A perl implementation of JavaScript's escape() and unescape() functions

=head1 SYNOPSIS

 use URI::Escape::JavaScript qw(escape unescape);
 
 $string  = "\x{3084}\x{306f}\x{308a}\x{539f}\x{56e0}\x{306f} Yapp(ry";
 $escaped = escape($string);
 
 $escaped = '%u30B5%u30D6%u30C6%u30AF%u5165%u308A%u305F%u3044%uFF01%uFF01';
 $string  = unescape($escaped);

 use URI::Escape::JavaScript;
 
 $string  = "\x{30c9}\x{30f3}\x{5f15}\x{304d}\x{3057}\x{305f}";
 $escaped = js_escape($string);
 
 $escaped = '%u3059%u305A%u304D%u308A%u3093%u305F%u308D%u3046';
 $string  = js_unescape($escaped);

=head1 DESCRIPTION

URI::Escape::JavaScript provides JavaScript's C<escape()> and C<unescape()> functions. It works simplar to homonymous functions of JavaScript.
L<URI::Escape> doesn't work for escaping and unescaping JavaScript like Unicode URI-escape (C<"%uXXXX">). But you can use this module to do those.

=head1 FUNCTIONS

=head2 escape()

C<escape()> works to escape a string to JavaScript's URI-escaped string.
The argument of this function must be a flagged UTF-8 string
(a.k.a. Perl's internal form).
This function is exportable (but will not be exported by default).
C<use> it with arguments of function names if you want
(It's for backward compatibility).

=head2 unescape()

C<unescape()> works to unescape JavaScript's URI-escaped string to original
string. It will return a flagged UTF-8 string (a.k.a. Perl's internal form).
This function is also exportable (but will not be exported by default).
C<use> it with arguments of function names if you want
(It's also for backward compatibility).

=head2 js_escape()

It's a synonym for C<escape()>. This function will be exported on your
namespace.

=head2 js_unescape()

It's a synonym for C<unescape()>. This function will be exported on your
namespace.

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<URI::Escape>, L<Encode>, L<Encode::JavaScript::UCS>

=cut
