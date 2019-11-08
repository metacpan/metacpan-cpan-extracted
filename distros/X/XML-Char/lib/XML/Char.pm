package XML::Char;

use utf8;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

use parent qw(DynaLoader);

use Exporter 'import';
our @EXPORT_OK = qw(
);

__PACKAGE__->bootstrap;

sub valid {
    my ($self, $value);
    if (@_ < 2) {
        $self = __PACKAGE__;
        $value = shift @_;
    }
    else {
        $self  = shift @_;
        $value = shift @_;
    }

    die 'bad usage'
        if not eval { $self->can('valid') };

    # undef is valid
    return 1
        if not defined $value;

    return _valid_xml_string($value);
}

1;

__END__

=encoding UTF-8

=head1 NAME

XML::Char - validate characters for XML

=head1 SYNOPSIS

    use XML::Char;
    if (not XML::Char->valid("bell ".chr(7))) {
        die 'no way to store this string directly to XML';
    }

    use utf8;
    use XML::Char;
    if (XML::Char->valid("UTF8 je pořádný peklo")) {
        print "fuf, we are fine\n";
    }

=head1 DESCRIPTION

For me it was kind of a surprised to learn that C<char(0)> is a valid UTF-8
character. All of the 0-0x7F are...

    Emo: well it's not because that they are valid utf-8 characters that you have to expect XML to accept them

Well of course not, now I know :-)

L<http://www.w3.org/TR/REC-xml/#charsets> defines which characters XML processors MUST accept:

    [2]   	Char	   ::=   	#x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
    /* any Unicode character, excluding the surrogate blocks, FFFE, and FFFF. */

This module validates if a given string meets this criteria. In addition
the string has to be a Perl UTF-8 string (C<is_utf8_string()> - see L<perlapi/Unicode-Support>).

=head2 valid($value)

Returns true or false if C<$value> consists of valid UTF-8 XML characters.

=head1 LINKS

L<How can I strip invalid XML characters from strings in Perl?|https://stackoverflow.com/questions/1016910/how-can-i-strip-invalid-xml-characters-from-strings-in-perl>

L<Extensible Markup Language (XML) 1.0|http://www.w3.org/TR/REC-xml/#charsets>

L<Extensible Markup Language (XML) 1.1|https://www.w3.org/TR/xml11/#charsets>

=head1 AUTHOR

Jozef Kutej

Aristotle Pagaltzis - completely rewrote the initial Char.XS to handle the SvUTF8 flag

=head1 COPYRIGHT

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

