package Unicode::Peek;

## Validate the version of Perl

BEGIN { die 'Perl version 5.13.2 or greater is required' if ($] < 5.013002); }

use strict;
use warnings;

require Exporter;
use vars qw($VERSION @ISA @EXPORT_OK);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Unicode::Peek ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

our @EXPORT_OK = qw (
    ascii2hexEncode
    hex2ascciiDecode
    hexDumperOutput
    hexDumperInput
    );

## Version of Unicode::Peek module

our $VERSION = '0.08';
$VERSION = eval $VERSION;

## Load necessary modules
use utf8;
use Carp;
use feature 'say';
use Encode qw(decode encode);

binmode( STDOUT, ':utf8' ); # debuggin purposes

my @unicodes = ( 'UCS-2',
		 'UCS-2BE',
		 'UCS-2LE',
		 'UCS-4',
		 'UTF-7',
		 'utf8',
		 'utf-8-strict',
		 'UTF-8',
		 'UTF-16',
		 'UTF-16BE',
		 'UTF-16LE',
		 'UTF-32',
		 'UTF-32BE',
		 'UTF-32LE' );

sub _checkSubroutineParameters {
    croak "Please pass only two parameters '@_'"
	if scalar @_ != 2;

    croak "Unknown encoding format '$_[0]'"
	unless (grep { /$_[0]/ } @unicodes);

    return $_[0], $_[1];
}

sub _ascii2hex {
    return unpack("H*", $_[0]);
}

sub _hex2ascii {
    return pack("H*", $_[0]);
}

sub hexDumperOutput {
    my ( $unicodeFormat , $data ) = _checkSubroutineParameters(@_);
    my $hexString = ascii2hexEncode( $unicodeFormat , $data );
    # trim leading and trailing white space
    # split string every two characters
    # join the splitted characters with white space
    $hexString = join(' ', split(/(..)/, $hexString))
	=~ s/^\s+|\s+$//r =~ y/ / /rs;
    # insert new line character every 30 characters
    # return join("\n", unpack('(A30)*', $hexString));
    push my @aref, unpack('(A30)*', $hexString);
    return \@aref;
}

sub hexDumperInput {
    my ( $unicodeFormat , $arrayRef ) = _checkSubroutineParameters(@_);
    my $hexString = join('', split(/ /, join('', @$arrayRef)));
    return hex2ascciiDecode($unicodeFormat, $hexString);
}

sub ascii2hexEncode {
    my ( $unicodeFormat , $data ) = _checkSubroutineParameters(@_);
    my $octets = encode( $unicodeFormat , $data );
    return _ascii2hex( $octets );
}

sub hex2ascciiDecode {
    my ( $unicodeFormat , $data ) = _checkSubroutineParameters(@_);
    my $hex2ascciiString = _hex2ascii( $data );
    return decode( $unicodeFormat , $hex2ascciiString );
}

1;

__END__

=head1 NAME

    Unicode::Peek - Perl module supports different unicode(s) transformation formats
    to hex and vice versa.


=head1 VERSION

    Version 0.08


=head1 SYNOPSIS

    The Unicode::Peek - Perl module provides to the user the ability to encode/
    decode asccii strings in a variety of unicode transformations to hex and vice
    versa. The user is able to take a peek in the hex data and see the formatted
    output and also vise versa. The user can provided an array of data in a hex
    format and convert it back to ascii. Perl version 5.13.2 or greater is required.


=head1 ABSTRACT

    The module is able to encode/decode any kind of ascci character(s) for 14
    different formats (e.g. utf8, UCS-2 ...). It configured to produce also to
    Dump Hexadecimal output and process Hexadecimal input. This feature was added
    mainly for debbuging purposes.


=head1 SUBROUTINES/METHODS

    use Unicode::Peek ( 'ascii2hexEncode', 'hex2ascciiDecode',
                        'hexDumperOutput', 'hexDumperInput' );

    my $hexEncoded         = ascii2hexEncode($unicodeFormat, $ascciiCharacters);
    ...

    my $ascciiCharacters   = hex2ascciiDecode($unicodeFormat, $hexEncoded);
    ...

    my @hexFormattedOutput = hexDumperOutput($unicodeFormat, $ascciiCharacters);
    ...

    my $ascciiCharacters   = hexDumperInput($unicodeFormat, \@hexFormattedOutput);
    ...


=head1 DESCRIPTION

This module exports four methods (ascii2hexEncode, hex2ascciiDecode, hexDumperOutput
    and hexDumperInput). All methods support 14 different encoding and decoding formats.
cd    The module has been tested with multiple languages with complex characters, but not
    with all known languages in the planet. So far as many languages have been tested all
    characters where encoded / decoded correctly.


=head2 EXPORT

    None by default, but the module can also export all methods by simple declaring all:

    use Unicode::Peek ':all';


=head1 SUPPORTED UNICODE FORMATS

=over 4

=item * UCS-2

=item * UCS-2BE

=item * UCS-2LE

=item * UCS-4

=item * UTF-7

=item * utf8

=item * utf8-strict

=item * UTF-8

=item * UTF-16

=item * UTF-16BE

=item * UTF-16LE

=item * UTF-32

=item * UTF-32BE

=item * UTF-32LE

=back

=head1 EXAMPLE 1 (hexDumperOutput)

=encoding utf8

These examples bellow is for demonstration purposes, randomly choosen Chinese as a testing
    language. We will use the L<Data::Dumper|https://perldoc.perl.org/Data/Dumper.html> module to print the formated hex output. Necessary is also the L<utf8|https://perldoc.perl.org/utf8.html> 
    for the stdout (convert the internal representation of a Perl scalar to/from UTF-8.)

    #!/usr/bin/perl
    use utf8;
    use strict;
    use warnings;
    use Data::Dumper;

    use Unicode::Peek qw( hexDumperOutput );

    my $lanquage = 'Chinese';

    my $str = '這是一個測試';

    my @flags = ( 'UCS-2',
                  'UCS-2BE',
                  'UCS-2LE',
                  'UCS-4',
                  'UTF-7',
                  'utf8',
                  'UTF-8',
                  'utf-8-strict',
                  'UTF-16',
                  'UTF-16BE',
                  'UTF-16LE',
                  'UTF-32',
                  'UTF-32BE',
                  'UTF-32LE' );

    while ( defined ( my $flag = shift @flags ) ) {
        print Dumper hexDumperOutput($flag, $str);
    };

=head1 EXAMPLE 2 (hexDumperInput)

    #!/usr/bin/perl
    use utf8;
    use strict;
    use warnings;
    use Data::Dumper;
    use feature 'say';

    use Unicode::Peek qw( hexDumperOutput hexDumperInput );

    my $lanquage = 'Chinese';

    my $str = '這是一個測試';

    my @flags = ( 'UCS-2',
                  'UCS-2BE',
                  'UCS-2LE',
                  'UCS-4',
                  'UTF-7',
                  'utf8',
                  'UTF-8',
                  'utf-8-strict',
                  'UTF-16',
                  'UTF-16BE',
                  'UTF-16LE',
                  'UTF-32',
                  'UTF-32BE',
                  'UTF-32LE' );

    while ( defined ( my $flag = shift @flags ) ) {
        my $hexDumper = hexDumperOutput($flag, $str);
        print Dumper $hexDumper;
        say hexDumperInput($flag, $hexDumper);
    };


=head1 EXAMPLE 3 (hex2ascciiDecode ascii2hexEncode)

    #!/usr/bin/perl
    use utf8;
    use strict;
    use warnings;
    use feature 'say';

    use Unicode::Peek qw( hex2ascciiDecode ascii2hexEncode );

    my $lanquage = 'Chinese';

    my $str = '這是一個測試';

    my @flags = ( 'UCS-2',
                  'UCS-2BE',
                  'UCS-2LE',
                  'UCS-4',
                  'UTF-7',
                  'utf8',
                  'UTF-8',
                  'utf-8-strict',
                  'UTF-16',
                  'UTF-16BE',
                  'UTF-16LE',
                  'UTF-32',
                  'UTF-32BE',
                  'UTF-32LE' );

     while ( defined ( my $flag = shift @flags ) ) {
         my $hexEncoded = ascii2hexEncode($flag, $str);
         say hex2ascciiDecode($flag, $hexEncoded);
     };


=head1 DEPENDENCIES

The module is implemented by using 'utf8' and 'Encode', both modules are
    mandatory as prerequisites and required to be pre-installed.


=head1 AUTHOR

    Athanasios Garyfalos, E<lt>garyfalos@cpan.org<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-unicode-peek at rt.cpan.org>, or through
    the web interface at L<Report Bug(s)|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Unicode-Peek>.  I will be notified, and then you'll
    automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

    You can find documentation for the module with the perldoc command.

    perldoc Unicode::Peek


=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<Request Tracker|http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unicode-Peek>


=item * AnnoCPAN: Annotated CPAN documentation

L<Annotated CPAN documentation|http://annocpan.org/dist/Unicode-Peek>


=item * CPAN Ratings

L<CPAN Ratings|http://cpanratings.perl.org/d/Unicode-Peek>


=item * Search CPAN

L<Unicode-Peek|http://search.cpan.org/dist/Unicode-Peek>


=back

=head1 SEE ALSO

perl, L<utf8|https://perldoc.perl.org/utf8.html>, L<UTF-8 vs. utf8 vs. UTF8|https://perldoc.perl.org/Encode.html#UTF-8-vs.-utf8-vs.-UTF8> and L<Data::Peek|http://search.cpan.org/~hmbrand/Data-Peek/Peek.pm>


=head1 REPOSITORY

L<Perl5-Unicode-Peek|https://github.com/thanos1983/Perl5-Unicode-Peek>


This library is free software; you can redistribute it and/or modify it under
    the same terms as Perl itself.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Athanasios Garyfalos.

This library is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


Any use, modification, and distribution of the Standard or Modified
    Versions is governed by this Artistic License. By using, modifying or
    distributing the Package, you accept this license. Do not use, modify,
    or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
    by someone other than you, you are nevertheless required to ensure that
    your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
    mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
    patent license to make, have made, use, offer to sell, sell, import and
    otherwise transfer the Package with respect to any patent claims
    licensable by the Copyright Holder that are necessarily infringed by the
    Package. If you institute patent litigation (including a cross-claim or
    counterclaim) against any party alleging that the Package constitutes
    direct or contributory patent infringement, then this Artistic License
    to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
    AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
    THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
    PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
    YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
    CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
    CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
    EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=head1 CHANGE LOG

    $Log: Peek.pm,v $
    Revision 0.08  2017/09/27 15:51:21 (UCT) Thanos

=cut
