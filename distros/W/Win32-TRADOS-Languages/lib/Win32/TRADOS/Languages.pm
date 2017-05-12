package Win32::TRADOS::Languages;

use strict;
use warnings;

use Win32::RunAsAdmin;
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>1 );
use Locale::Language;
use Carp;

=head1 NAME

Win32::TRADOS::Languages - Simplifies working with TRADOS Registry values

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our %languages = (
  '00' => 'DV',
  '01' => 'CY',
  '02' => 'Syriac',
  '03' => 'Northern Sotho',
  '04' => '--',
  '05' => '--',
  '06' => '--',
  '07' => 'NE',
  '08' => '--',
  '09' => '--',
  '0A' => '--',
  '0B' => '--',
  '0C' => 'QU',
  '0D' => '--',
  '0E' => '--',
  '0F' => '--',
  '10' => 'BN',
  '11' => 'PA',
  '12' => 'GU',
  '13' => 'OR',
  '14' => 'ST', # Southern Sotho
  '15' => 'SE',
  '16' => 'KA',
  '17' => 'HI',
  '18' => 'AS',
  '19' => 'MR',
  '1A' => 'SA',
  '1B' => 'Konkani',
  '1C' => 'TA',
  '1D' => 'TE',
  '1E' => 'KN',
  '1F' => 'ML',
  '40' => 'NB',
  '41' => 'PL',
  '42' => 'PT',
  '43' => 'RM',
  '44' => 'IT',
  '45' => 'JA',
  '46' => 'KO',
  '47' => 'NL',
  '48' => 'SQ',
  '49' => 'SV',
  '4A' => 'TH',
  '4B' => 'TR',
  '4C' => 'RO',
  '4D' => 'RU',
  '4E' => 'HR',  # Also Serbian and Bosnian.
  '4F' => 'SK',
  '50' => 'ZH',
  '51' => 'CS',
  '52' => 'DA',
  '53' => 'DE',
  '54' => '--',
  '55' => 'AR',
  '56' => 'BG',
  '57' => 'CA',
  '58' => 'FR',
  '59' => 'HE',
  '5A' => 'HU',
  '5B' => 'IS',
  '5C' => 'EL',
  '5D' => 'EN',
  '5E' => 'ES',
  '5F' => 'FI',
  '60' => 'FO',
  '61' => 'MT',
  '62' => 'GA',
  '63' => 'MS',
  '64' => '--',
  '65' => 'XH',
  '66' => 'ZU',
  '67' => 'AF',
  '68' => 'UZ',
  '69' => 'TT',
  '6A' => 'MN',
  '6B' => 'GL',
  '6C' => 'KK',
  '6D' => 'SW',
  '6E' => 'TL',
  '6F' => 'KY',
  '70' => 'SL',
  '71' => 'ET',
  '72' => 'LV',
  '73' => 'LT',
  '74' => 'UR',
  '75' => 'ID',
  '76' => 'UK',
  '77' => 'BE',
  '78' => 'AZ',
  '79' => 'EU',
  '7A' => 'Sorbian',
  '7B' => 'MK',
  '7C' => 'MI',
  '7D' => 'FA',
  '7E' => 'VI',
  '7F' => 'HY',
);


=head1 SYNOPSIS

TRADOS 2007 is a fantastically useful tool for the professional translator that is used on Windows.
Somewhere back in its history, it was decided to permit the Freelancer version of the tool to install
only five languages at once, and that has remained a technical limitation of the tool - the official
recommendation of SDL (the current owners of the software) is to de-install and re-install the entire
package if the five installed languages need to be changed. (To be fair, I wouldn't want to provide
the technical support for any other method, either.)

However, they are all encoded in a single Registry key; this module contains a table of values for
the numeric codes used in that key with their ISO codes, and also some simple tools for reading and
writing the key. This saves a lot of time in de-installing and re-installing the package for those
of us who work with more than five languages.

A command-line script ttx-lang is also included that exposes the functionality to the command line
in a convenient manner.

=head1 METHODS

=head2 get_idng

Reads the value of the Registry key in question. Doesn't require elevated privileges, as it
obtains only read access to the Registry to do this. Croaks if it can't find the key.

=cut

sub get_idng {
    my $key_not_found = 0;
    my $LMkey = Win32::TieRegistry->Open ('HKEY_LOCAL_MACHINE', {Access=>Win32::TieRegistry::KEY_READ()});
    $LMkey->Delimiter('/');
    my $LMachine = {};
    $LMkey->Tie($LMachine);
    
    my $key = $LMachine->{'SOFTWARE/Wow6432Node/TRADOS'} or $key_not_found = 1;
    if ($key_not_found) {
        $key_not_found = 0;
        $key = $LMachine->{'/SOFTWARE/TRADOS'} or $key_not_found = 1;
    }
    if ($key_not_found) {
        croak "TRADOS 2007 does not appear to be installed on your machine (can't find Registry key)";
    }

    $key->{'Shared/IDNG//'} or croak "TRADOS 2007 appears to be installed, but your Registry is configured in an unexpected way.";
}

=head2 set_idng ($idng)

Sets the IDNG key to the value supplied. Requires elevated privileges. Croaks if it doesn't have them.

=cut

sub set_idng {
    my $idng = shift;
    my $LMkey = Win32::TieRegistry->Open ('HKEY_LOCAL_MACHINE', {Access=>Win32::TieRegistry::KEY_READ()|Win32::TieRegistry::KEY_WRITE()})
       or croak "Not running with elevated privileges";
    $LMkey->Delimiter('/');
    my $LMachine = {};
    $LMkey->Tie($LMachine);
    
    my $key_not_found = 0;
    my $key = $LMachine->{'SOFTWARE/Wow6432Node/TRADOS'} or $key_not_found = 1;
    if ($key_not_found) {
        $key_not_found = 0;
        $key = $LMachine->{'/SOFTWARE/TRADOS'} or $key_not_found = 1;
    }

    $key->{'Shared/IDNG//'} = $idng;
}

=head2 get_languages ($idng)

Given an IDNG value, extracts the numeric language codes from it. Returns a list of the languages encoded.
Croaks if the IDNG doesn't look like an IDNG key.

=cut

sub get_languages {
    my $idng = shift;
    if (not $idng =~ /{(.*-.*-.*-.*-00)(.*)}/) {
        croak "Unexpected IDNG value $idng encountered";
    }
    my ($prefix, $meat) = ($1, $2);
    unpack("(A2)*", $meat);
}

=head2 set_languages ($idng, @values)

Given an IDNG value and one to five language codes, builds and returns a new IDNG key.
Croaks if the IDNG key given doesn't look like an IDNG key.

=cut

sub set_languages {
    my $idng = shift;
    if (not $idng =~ /{(.*-.*-.*-.*-00)(.*)}/) {
        croak "Unexpected IDNG value $idng encountered";
    }
    my ($prefix, $meat) = ($1, $2);
    sprintf ("{$prefix%s}", join ('', @_));
}

=head2 idng2iso, idng2lang

Given a TRADOS numeric language code, C<idng2iso> looks up its ISO equivalent in the table of values.
C<idng2lang> also calls C<code2language> to convert that ISO code into the name of the language.
Has a little more logic to build values that are more appropriate to the TRADOS language list.

=cut

sub idng2iso {
    my $language = shift;
    $languages{$language} || "-- ($language)";
}

sub idng2lang {
    my $iso = idng2iso(shift);
    my $ln = code2language($iso);
    $ln = "Croatian/Serbian/Bosnian" if $iso eq 'HR';
    $ln;
}

=head2 iso2idng, lang2idng

Given an ISO code, C<iso2idng> looks for it in the table of numeric values. Returns C<undef>
if it can't find it there. C<lang2idng> calls C<language2code> first, and also includes some
other logic: returns '84' ("invalid language") for an undefined language or '--', passes
hex codes through unaffected, and converts ISO codes directly if they're passed.
This is your best bet to make sense of user input.

=cut

sub iso2idng {
    my $language = lc(shift);
    foreach my $n (keys %languages) {
        if (lc($languages{$n}) eq $language) {
            return $n;
        }
    }
    return undef;
}

sub lang2idng {
    my $language = shift;
    return '84' if not defined $language;
    return '84' if $language eq '--';
    if ($language =~ /^[0-9][0-9A-F]$/) {
        $language =~ tr/a-z/A-Z/;
        return $language;
    }
    my $ln = language2code ($language);
    $language = $ln if $ln;
    $language =~ tr/a-z/A-Z/;
    $language = 'HR' if $language eq 'SR' or $language eq 'BS';
    iso2idng ($language);
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-trados-languages at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-TRADOS-Languages>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::TRADOS::Languages


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-TRADOS-Languages>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-TRADOS-Languages>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-TRADOS-Languages>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-TRADOS-Languages/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
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


=cut

1; # End of Win32::TRADOS::Languages
