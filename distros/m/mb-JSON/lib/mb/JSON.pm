package mb::JSON;
######################################################################
#
# mb::JSON - a simple JSON parser for multibyte string
#
# http://search.cpan.org/dist/mb-JSON/
#
# Copyright (c) 2021, 2022 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
# use 5.008001; # Lancaster Consensus 2013 for toolchains

$VERSION = '0.03';
$VERSION = $VERSION;

use strict;

#---------------------------------------------------------------------
# UTF-8
my $utf8 = join '', qw{
    [\x00-\x7F\x80-\xBF\xC0-\xC1\xF5-\xFF]       |
    [\xC2-\xDF][\x80-\xBF]                       |
    [\xE0-\xE0][\xA0-\xBF][\x80-\xBF]            |
    [\xE1-\xEC][\x80-\xBF][\x80-\xBF]            |
    [\xED-\xED][\x80-\x9F][\x80-\xBF]            |
    [\xEE-\xEF][\x80-\xBF][\x80-\xBF]            |
    [\xF0-\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF] |
    [\xF4-\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF] |
    [\x00-\xFF]
};

#---------------------------------------------------------------------
# confess() for this module
sub confess {
    my $i = 0;
    my @confess = ();
    while (my($package,$filename,$line,$subroutine) = caller($i)) {
        push @confess, "[$i] $filename($line) $subroutine\n";
        $i++;
    }
    print STDERR "\n", @_, "\n";
    print STDERR CORE::reverse @confess;
    die;
}

#---------------------------------------------------------------------
# parse JSON data
sub mb::JSON::parse {
    local $_ = @_ ? $_[0] : $_;
    my $U0 = ($] =~ /^5\.006/) ? 'U0' : '';
    my $parsed = '';
    while (not /\G \z/xmsgc) {

        # beginning of JSON's string --> beginning of Perl's string
        if (/\G (") /xmsgc) {
            $parsed .= $1;

            while (1) {

                #-------------------------------------------------------------------------------
                # end of JSON's string then ":" --> Perl's hash key
                #-------------------------------------------------------------------------------
                # An object structure is represented as a pair of curly brackets
                # surrounding zero or more name/value pairs (or members).  A name is a
                # string.  A single colon comes after each name, separating the name
                # from the value.  A single comma separates a value from a following
                # name.  The names within an object SHOULD be unique.
                #-------------------------------------------------------------------------------

                if (/\G ( " \s* ) : /xmsgc) {
                    $parsed .= "$1,";
                    last;
                }

                # end of JSON's string --> end of Perl's string
                elsif (/\G (") /xmsgc) {
                    $parsed .= $1;
                    last;
                }

                #-------------------------------------------------------------------------------
                # UTF-16 surrogate pair
                #-------------------------------------------------------------------------------
                # To escape an extended character that is not in the Basic Multilingual
                # Plane, the character is represented as a 12-character sequence,
                # encoding the UTF-16 surrogate pair.  So, for example, a string
                # containing only the G clef character (U+1D11E) may be represented as
                # "\uD834\uDD1E".
                #
                # TIPS: in Perl, \u in a "string" means ucfirst(), so must be \\u
                # TIPS: Don't use /i modifier, because \U is not \u
                #-------------------------------------------------------------------------------

                elsif (/\G \\u ([Dd][89ABab][0-9A-Fa-f][0-9A-Fa-f]) \\u ([Dd][CDEFcdef][0-9A-Fa-f][0-9A-Fa-f]) /xmsgc) {
                    my $high_surrogate = hex $1;
                    my $low_surrogate  = hex $2;
                    my $unicode = 0x10000 + ($high_surrogate - 0xD800) * 0x400 + ($low_surrogate - 0xDC00);
                    if (0) { }
                    elsif ($unicode < 0x110000) { $parsed .= pack($U0.'C*', $unicode>>18|0xF0, $unicode>>12&0x3F|0x80, $unicode>>6&0x3F|0x80, $unicode&0x3F|0x80) }
                    else { confess qq{@{[__FILE__]}: \\u{$1} is out of Unicode (0x0000 to 0xFFFF)}; }
                }

                #-------------------------------------------------------------------------------
                # any BMP UTF-16 codepoint
                #-------------------------------------------------------------------------------
                # If the character is in the Basic Multilingual Plane (U+0000 through U+FFFF),
                # then it may be represented as a six-character sequence: a reverse solidus,
                # followed by the lowercase letter u, followed by four hexadecimal digits that
                # encode the character's code point.  The hexadecimal letters A through F can
                # be uppercase or lowercase.
                #-------------------------------------------------------------------------------

                elsif (/\G \\u ([0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) /xmsgc) {
                    my $unicode = hex $1;
                    if (0) { }
                    elsif ($unicode <     0x80) { $parsed .= pack($U0.'C*',                                                                   $unicode          ) }
                    elsif ($unicode <    0x800) { $parsed .= pack($U0.'C*',                                            $unicode>>6     |0xC0, $unicode&0x3F|0x80) }
                    elsif ($unicode <  0x10000) { $parsed .= pack($U0.'C*',                    $unicode>>12     |0xE0, $unicode>>6&0x3F|0x80, $unicode&0x3F|0x80) }
                    else { confess qq{@{[__FILE__]}: \\u{$1} is out of Unicode (0x0000 to 0xFFFF)}; }
                }

                #-------------------------------------------------------------------------------
                # two-character sequence escape representations
                #-------------------------------------------------------------------------------
                # Alternatively, there are two-character sequence escape representations
                # of some popular characters.  So, for example, a string containing only
                # a single reverse solidus character may be represented more compactly
                # as "\\".
                # 
                #   \"    quotation mark     U+0022
                #   \\    reverse solidus    U+005C
                #   \/    solidus            U+002F
                #   \b    backspace          U+0008
                #   \f    form feed          U+000C
                #   \n    line feed          U+000A
                #   \r    carriage return    U+000D
                #   \t    tab                U+0009
                #-------------------------------------------------------------------------------

                elsif (m{\G (\\["\\/bfnrt]) }xmsgc) {
                    $parsed .= $1;
                }

                # escape $ and @ to avoid interpolation on eval() of Perl
                elsif (/\G ([\$\@]) /xmsgc) {
                    $parsed .= "\\$1";
                }

                # other all UTF-8 codepoints
                elsif (/\G ($utf8) /xmsgc) {
                    $parsed .= $1;
                }

                # panic inside "string"
                else {
                    confess sprintf(<<END, substr($_,pos));
@{[__FILE__]}: JSON data makes panic; (maybe @{[__FILE__]} has bug(s))
%s
END
                }
            }
        }

        # JSON's "null" --> Perl's "undef"
        elsif (/\G null \b/xmsgc) {
            $parsed .= 'undef';
        }

        # JSON's boolean "true" --> Perl's "1"
        elsif (/\G true \b/xmsgc) {
            $parsed .= '!!1';
        }

        # JSON's boolean "false" --> Perl's "0"
        elsif (/\G false \b/xmsgc) {
            $parsed .= '!!0';
        }

        # other all UTF-8 codepoints
        elsif (/\G ($utf8) /xmsgc) {
            $parsed .= $1;
        }

        # panic outside "string"
        else {
            confess sprintf(<<END, substr($_,pos));
@{[__FILE__]}: JSON data makes panic; (maybe @{[__FILE__]} has bug(s))
%s
END
        }
    }

    # return as Perl data without UTF-8 flag
    return eval $parsed;
}

1;

__END__

=pod

=head1 NAME

mb::JSON - a simple JSON parser for multibyte string

=head1 SYNOPSIS

    use mb::JSON;

    $perldata = mb::JSON::parse($_);
    $perldata = mb::JSON::parse();

  supported perl versions:
    perl version 5.005_03 to newest perl

=head1 INSTALLATION BY MAKE

To install this software by make, type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 INSTALLATION WITHOUT MAKE (for DOS-like system)

To install this software without make, type the following:

   pmake.bat test
   pmake.bat install

=head1 DESCRIPTION

  This software consists of only single file and has few functions,
  so it is easy to use and easy to understand.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

 The JavaScript Object Notation (JSON) Data Interchange Format
 https://www.rfc-editor.org/rfc/rfc8259.txt

 UTF-8, a transformation format of ISO 10646
 https://www.rfc-editor.org/rfc/rfc3629.txt

 JSON - JSON (JavaScript Object Notation) encoder/decoder
 https://metacpan.org/dist/JSON

 mb - run Perl script in MBCS encoding (not only CJK ;-)
 https://metacpan.org/dist/mb

 mb::Encode - provides MBCS encoder and decoder
 https://metacpan.org/dist/mb-Encode

 UTF8::R2 - makes UTF-8 scripting easy for enterprise use or LTS
 https://metacpan.org/dist/UTF8-R2

=cut
