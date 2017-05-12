package Text::Convert::PETSCII;

=head1 NAME

Text::Convert::PETSCII - ASCII/PETSCII text converter

=head1 SYNOPSIS

  use Text::Convert::PETSCII qw/:all/;

  # Convert an ASCII string to a PETSCII string:
  my $petscii_string = ascii_to_petscii($ascii_string);

  # Convert a PETSCII string to an ASCII string:
  my $ascii_string = petscii_to_ascii($petscii_string);

  # Convert CBM screen codes to a PETSCII string:
  my $petscii_string = screen_codes_to_petscii($screen_codes);

  # Convert a PETSCII string to CBM screen codes:
  my $screen_codes = petscii_to_screen_codes($petscii_string);

  # Set mode for writing PETSCII character's representation to a file handle:
  set_petscii_write_mode($write_mode);

  # Write PETSCII single character's textual representation to a file handle:
  write_petscii_char($file_handle, $petscii_char);

  # Validate whether given PETSCII string text may normally be printed out:
  my $is_printable = is_printable_petscii_string($petscii_string);

  # Validate whether given text may be considered a valid PETSCII string:
  my $is_valid = is_valid_petscii_string($text_string);

=head1 DESCRIPTION

This package provides two basic methods for converting text format between ASCII and PETSCII character sets. PETSCII stands for the "PET Standard Code of Information Interchange" and is also known as CBM ASCII. PETSCII character set has been widely used in Commodore Business Machines (CBM)'s 8-bit home computers, starting with the PET from 1977 and including the VIC-20, C64, CBM-II, Plus/4, C16, C116 and C128.

=head1 METHODS

=cut

use base qw(Exporter);
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'convert'} = [ qw(&ascii_to_petscii &petscii_to_ascii) ];
$EXPORT_TAGS{'display'} = [ qw(&set_petscii_write_mode &write_petscii_char) ];
$EXPORT_TAGS{'screen'} = [ qw(&screen_codes_to_petscii &petscii_to_screen_codes) ];
$EXPORT_TAGS{'validate'} = [ qw(&is_printable_petscii_string &is_valid_petscii_string) ];
$EXPORT_TAGS{'all'} = [ @{$EXPORT_TAGS{'convert'}}, @{$EXPORT_TAGS{'display'}}, @{$EXPORT_TAGS{'screen'}}, @{$EXPORT_TAGS{'validate'}} ];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.05';

use Carp qw/carp croak/;
use Data::Dumper;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our $WRITE_MODE = 'unshifted';

=head2 ascii_to_petscii

Convert an ASCII string to a PETSCII string:

  my $petscii_string = ascii_to_petscii($ascii_string);

Input data is handled as a stream of bytes. When original ASCII string contains any non-ASCII character, a relevant warning will be triggered, providing detailed information about invalid character's integer code and its position within the source string.

=cut

sub ascii_to_petscii {
    my ($str_ascii) = @_;
    my $str_petscii = '';
    my $position = 1;
    while ($str_ascii =~ s/^(.)(.*)$/$2/) {
        my $c = ord $1;
        my $code = $c & 0x7f;
        if ($c != $code) {
            carp sprintf qq{Invalid ASCII code at position %d of converted text string: "0x%02x" (convertible codes include bytes between 0x00 and 0x7f)}, $position, $c;
        }
        if ($code >= ord 'A' && $code <= ord 'Z') {
            $code += 32;
        } elsif ($code >= ord 'a' && $code <= ord 'z') {
            $code -= 32;
        }
        $str_petscii .= chr $code;
        $position++;
    }
    return $str_petscii;
}

=head2 petscii_to_ascii

Convert a PETSCII string to an ASCII string:

  my $ascii_string = petscii_to_ascii($petscii_string);

Input data is handled as a stream of bytes. Note that integer codes between 0x80 and 0xff despite of being valid PETSCII codes are not convertible into any ASCII equivalents, therefore they trigger a relevant warning, providing detailed information about invalid character's integer code and its position within the source string.

=cut

sub petscii_to_ascii {
    my ($str_petscii) = @_;
    my $str_ascii = '';
    my $position = 1;
    while ($str_petscii =~ s/^(.)(.*)$/$2/) {
        my $c = ord $1;
        my $code = $c & 0x7f;
        if ($c != $code) {
            carp sprintf qq{Invalid PETSCII code at position %d of converted text string: "0x%02x" (convertible codes include bytes between 0x00 and 0x7f)}, $position, $c;
        }
        if ($code >= ord 'A' && $code <= ord 'Z') {
            $code += 32;
        } elsif ($code >= ord 'a' && $code <= ord 'z') {
            $code -= 32;
        } elsif ($code == 0x7f) {
            $code = 0x3f;
        }
        $str_ascii .= chr $code;
        $position++;
    }
    return $str_ascii;
}

=head2 screen_codes_to_petscii

Convert CBM screen codes to a PETSCII string:

  my $petscii_string = screen_codes_to_petscii($screen_codes);

Input screen codes are expected to be a scalar value that is handled as a stream of bytes. And so is a returned value.

=cut

sub screen_codes_to_petscii {
    my ($screen_codes) = @_;

    my $reverse_flag = 0;

    my $petscii_string;

    for my $screen_char (split //, $screen_codes) {

        my $screen_code = ord ($screen_char);

        # RVS ON:
        if ($screen_code & 0x80) {
            unless ($reverse_flag) {
                $reverse_flag = 1;
                $petscii_string .= chr (0x12);
            }
            $screen_code ^= 0x80;
        }
        # RVS OFF:
        else {
            if ($reverse_flag) {
                $reverse_flag = 0;
                $petscii_string .= chr (0x92);
            }
        }

        # $20 .. $3f ("SPACE ($20)" .. "?"):
        my $petscii_byte = $screen_code;
        # $00 .. $1f ("@" .. "left arrow"):
        if ($petscii_byte >= 0x00 && $petscii_byte < 0x20) {
            $petscii_byte += 0x40;
        }
        # $40 .. $5f ("horizontal line" .. "top-right triangle"):
        elsif ($petscii_byte >= 0x40 && $petscii_byte < 0x60) {
            $petscii_byte += 0x20;
        }
        # $60 .. $7f ("SPACE ($60)" .. "racing square"):
        elsif ($petscii_byte >= 0x60 && $petscii_byte < 0x80) {
            $petscii_byte += 0x40;
        }

        $petscii_string .= chr ($petscii_byte);
    }

    return $petscii_string;
}

=head2 petscii_to_screen_codes

Convert a PETSCII string to CBM screen codes:

  my $screen_codes = petscii_to_screen_codes($petscii_string);

Input PETSCII string is expected to be a scalar value that is handled as a stream of bytes. And so is a returned value.

=cut

sub petscii_to_screen_codes {
    my ($petscii_string) = @_;

    my $reverse_flag = 0x00;

    my $screen_codes;

    for my $petscii_char (split //, $petscii_string) {

        my $petscii_byte = ord ($petscii_char);

        # RVS ON:
        if ($petscii_byte == 0x12) {
            $reverse_flag = 0x80;
            next;
        }

        # RVS OFF:
        if ($petscii_byte == 0x92) {
            $reverse_flag = 0x00;
            next;
        }

        # $c0 .. $df are the same as $60 .. $7f
        if ($petscii_byte >= 0xc0 && $petscii_byte < 0xe0) {
            $petscii_byte -= 0x60;
        }
        # $e0 .. $fe are the same as $a0 .. $be
        elsif ($petscii_byte >= 0xe0 && $petscii_byte < 0xff) {
            $petscii_byte -= 0x40;
        }
        # $ff is the same as $7e
        elsif ($petscii_byte == 0xff) {
            $petscii_byte = 0x7e;
        }
        # $95 .. $9b are the same as $75 .. $7b
        elsif ($petscii_byte >= 0x95 && $petscii_byte < 0x9c) {
            $petscii_byte -= 0x20;
        }

        # Skip all non-printable characters:
        if ($petscii_byte >= 0x00 && $petscii_byte < 0x20 || $petscii_byte >= 0x80 && $petscii_byte < 0xa0) {
            next;
        }

        # $20 .. $3f ("SPACE ($20)" .. "?"):
        my $screen_code = $petscii_byte;
        # $40 .. $5f ("@" .. "left arrow"):
        if ($screen_code >= 0x40 && $screen_code < 0x60) {
            $screen_code -= 0x40;
        }
        # $60 .. $7f ("horizontal line" .. "top-right triangle"):
        elsif ($screen_code >= 0x60 && $screen_code < 0x80) {
            $screen_code -= 0x20;
        }
        # $a0 .. $bf ("SPACE ($A0)" .. "racing square"):
        elsif ($screen_code >= 0xa0 && $screen_code < 0xc0) {
            $screen_code -= 0x40;
        }

        $screen_codes .= chr ($screen_code | $reverse_flag);
    }

    return $screen_codes;
}

=head2 set_petscii_write_mode

Set mode for writing PETSCII character's textual representation to a file handle:

  set_petscii_write_mode('shifted');
  set_petscii_write_mode('unshifted');

There are two modes available. A "shifted" mode, also known as a "text" mode, refers to mode, in which lowercase letters occupy the range 0x41 .. 0x5a, and uppercase letters occupy the range 0xc1 .. 0xda. In "unshifted" mode, codes 0x60 .. 0x7f and 0xa0 .. 0xff are allocated to CBM-specific block graphics characters.

If not set explicitly, writing PETSCII char defaults to "unshifted" mode.

=cut

sub set_petscii_write_mode {
    my ($petscii_write_mode) = @_;
    if (not defined $petscii_write_mode) {
        carp q{Failed to set PETSCII write mode: no mode to set has been specified};
    }
    _petscii_write_mode($petscii_write_mode);
}

sub _petscii_write_mode {
    my ($petscii_write_mode) = @_;
    if (defined $petscii_write_mode) {
        unless (grep { $petscii_write_mode eq $_ } qw/shifted unshifted/) {
            carp sprintf q{Failed to set PETSCII write mode, invalid PETSCII write mode: "%s"}, $petscii_write_mode;
            return;
        }
        $WRITE_MODE = $petscii_write_mode;
    }
    return $WRITE_MODE;
}

=head2 write_petscii_char

Write PETSCII character's textual representation to a file handle:

  write_petscii_char($fh, $petscii_char);

C<$fh> is expected to be an opened file handle that PETSCII character's textual representation may be written to, and C<$petscii_char> is expected to either be an integer code (between 0x20 and 0x7f as well as between 0xa0 and 0xff, since control codes between 0x00 and 0x1f and between 0x80 and 0x9f are not printable by design) or a character byte (the actual single byte with PETSCII data to be processed, same rules for possible printable characters apply).

=cut

sub write_petscii_char {
    my ($fh, $chr_petscii) = @_;

    # Check if character provided is actually a character or a numerical index:
    my $screen_code = undef;
    if (_is_integer($chr_petscii)) {
        if ($chr_petscii < 0x20 or $chr_petscii > 0xff or ($chr_petscii >= 0x80 and $chr_petscii <= 0x9f)) {
            carp sprintf q{Value out of range: "0x%02x" (PETSCII character set supports printable characters in the range of 0x20 to 0x7f and 0xa0 to 0xff)}, $chr_petscii;
        }
        else {
            $screen_code = _petscii_to_screen_code($chr_petscii);
        }
    }
    elsif (_is_string($chr_petscii)) {
        if (length $chr_petscii == 0) {
            carp q{PETSCII character byte missing, nothing to be printed out};
        }
        elsif (length $chr_petscii > 1) {
            carp sprintf q{PETSCII character string too long: %d bytes (currently writing only a single character is supported)}, length $chr_petscii;
        }
        else {
            $screen_code = _petscii_to_screen_code(ord $chr_petscii);
        }
    }
    else {
        my $invalid_data = Data::Dumper->new([$chr_petscii])->Terse(1)->Indent(0)->Dump();
        carp qq{Not a valid PETSCII character to write: ${invalid_data} (expected integer code or character byte)};
    }

    # Print out character's textual representation based on the calculated screen code:
    if (defined $screen_code) {
        my $shifted_mode = _petscii_write_mode() eq 'shifted' ? 1 : 0;
        my @font_data = _get_font_data($screen_code, $shifted_mode);
        foreach my $font_line (@font_data) {
            for (my $i = 0; $i < 8; $i++) {
                my $font_pixel = $font_line & 0x80 ? 1 : 0;
                if ($font_pixel) {
                    print q{*};
                }
                else {
                    print q{-};
                }
                $font_line <<= 1;
            }
            print qq{\n};
        }
    }

    return;
}

=head2 is_printable_petscii_string

Validate whether given PETSCII string text may normally be printed out:

  my $is_printable = is_printable_petscii_string($petscii_string);

Returns true value upon successful validation, and false otherwise. False value will also be immediately returned when text string that is given as an argument is not a PETSCII string at all.

=cut

sub is_printable_petscii_string {
    my ($text_string) = @_;

    return 0 unless is_valid_petscii_string($text_string);

    return 1 if length $text_string == 0;

    unless ($text_string =~ m/^[^\x20-\x7f\xa0-\xff]*$/g) {
        return 1;
    }

    return 0;
}

=head2 is_valid_petscii_string

Validate whether given text may be considered a valid PETSCII string:

  my $is_valid = is_valid_petscii_string($text_string);

Returns true value upon successful validation, and false otherwise.

=cut

sub is_valid_petscii_string {
    my ($text_string) = @_;

    return 0 unless defined $text_string;
    return 0 if ref $text_string;

    return 1 if length $text_string == 0;

    unless ($text_string =~ m/^[^\x00-\xff]*$/g) {
        return 1;
    }

    return 0;
}

# TODO: Consider adding this method to the public interface of current package:
sub _petscii_to_screen_code {
    my ($num_petscii) = @_;
    if ($num_petscii < 0x20 or $num_petscii > 0xff or ($num_petscii >= 0x80 and $num_petscii <= 0x9f)) {
        croak sprintf q{Invalid PETSCII integer code: "0x%02x" (PETSCII character set supports printable characters in the range of 0x20 to 0x7f and 0xa0 to 0xff)}, $num_petscii;
    }
    my $screen_code = $num_petscii;
    if ($num_petscii >= 64 && $num_petscii <= 95) {
        $screen_code -= 64;
    }
    elsif ($num_petscii >= 96 && $num_petscii <= 127) {
        $screen_code -= 32;
    }
    elsif ($num_petscii >= 160 && $num_petscii <= 191) {
        $screen_code -= 64;
    }
    elsif ($num_petscii >= 192 && $num_petscii <= 223) {
        $screen_code -= 128;
    }
    elsif ($num_petscii >= 224 && $num_petscii <= 254) {
        $screen_code -= 128;
    }
    elsif ($num_petscii == 255) {
        $screen_code -= 161;
    }
    return $screen_code;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

No method is exported into the caller's namespace by default.

Selected methods may be exported into the caller's namespace explicitly by using the following tags in the import list:

=over

=item *
C<convert> tag adds L</ascii_to_petscii> and L</petscii_to_ascii> subroutines to the list of symbols to be imported into the caller's namespace

=item *
C<display> tag adds L</set_petscii_write_mode> and L</write_petscii_char> subroutines to the list of symbols to be imported into the caller's namespace

=item *
C<screen> tag adds L</screen_codes_to_petscii> and </petscii_to_screen_codes> subroutines to the list of symbols to be imported into the caller's namespace

=item *
C<validate> tag adds L</is_printable_petscii_string> and </is_valid_petscii_string> subroutines to the list of symbols to be imported into the caller's namespace

=item *
C<all> tag adds all subroutines listed by C<convert>, C<display>, C<screen>, and C<validate> tags to the list of exported symbols

=back

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.05 (2013-03-08)

=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2013 by Pawel Krol <pawelkrol@cpan.org>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;
