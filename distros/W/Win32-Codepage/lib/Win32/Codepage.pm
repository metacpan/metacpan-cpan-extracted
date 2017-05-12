package Win32::Codepage;

use warnings;
use strict;
use Win32::Locale;

our $VERSION = '1.00';

my $CODEPAGE_REGISTRY_KEY = 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Nls/CodePage';
my $LANGUAGE_REGISTRY_KEY = 'HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Nls/Language';

=head1 NAME

Win32::Codepage - get Win32 codepage information

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

    use Win32::Codepage;
    print "Current language: " . Win32::Codepage::get_codepage() . "\n";  # e.g. "en-us"
    print "Install language: " . Win32::Codepage::get_install_codepage() . "\n";
    
    use Encode qw(encode);
    my $w32encoding = Win32::Codepage::get_encoding();  # e.g. "cp1252"
    my $encoding = $w32encoding ? Encode::resolve_alias($w32encoding) : '';
    print $encoding ? encode($string, $encoding) : $string;

=head1 DESCRIPTION

This module is intended as a companion to Win32::Locale.  That module
offers information about user prefs for language and locale.  However,
Windows has a separate setting for how files and filenames are encoded
by default, which is specified by the "codepage" (a legacy term from
DOS days).  It is possible to be on a computer whose language, date,
currency, etc are set to English, but the file contents and filesystem
names default to SHIFT-JIS (Japanese) encoding.

This module offers information about that codepage, which allows your
Perl code to know what encoding to expect for file names and file
contents.

On Windows XP, you can change the current codepage from the default
via Control Panel > Regional and Language Settings > Advanced tab.  If
you change it to, say, Japanese and then reboot, the default codepage
will be cp932, which is Microsoft's version of SHIFT-JIS.  This will
allow non-Unicode Windows applications (like ActiveState Perl) to read
filenames that contain Japanese characters.  If you have files named
with Japanese characters but your codepage is set to cp1252
(Microsoft's version of ISO-latin-1), then the foreign characters
in the filename appear as C<?> to Perl.

If there's a better way around this than messing with codepages,
PLEASE LET ME KNOW!  I hate that I ever had to write this module...

=head1 SEE ALSO

L<Win32::Locale>

I tried to contact the author of that module to get him to
extend his distribution to include the codepage functionality, but I
received no response for seven months.  So, I created this module.
See the RT ticket: L<http://rt.cpan.org/Ticket/Display.html?id=11739>

=head1 FUNCTIONS

=over

=item get_codepage

Returns the language name for the current codepage language.  For
example C<en-us> or C<ja>.  Returns false if the codepage language
cannot be identified.

If this function is passed an argument (not recommended), then it
returns the language name for the specified language ID instead of the
system language ID.

=cut

sub get_codepage
{
   my $lang = $Win32::Locale::MSLocale2LangTag{ $_[0] || get_ms_codepage() || '' };
   return unless $lang;
   return $lang;
}

=item get_install_codepage

Returns the language name for the installed codepage language.  This
is the same as get_codepage(), but refers to the codepage that was the
default when Windows was first installed.

=cut

sub get_install_codepage
{
   my $lang = $Win32::Locale::MSLocale2LangTag{ $_[0] || get_ms_install_codepage() || '' };
   return unless $lang;
   return $lang;
}

=item get_encoding

Returns an encoding name usable with Encode.pm based on the current
codepage.  For example, C<cp1252> for iso-8859-1 (latin-1) or C<cp932>
for Shift-JIS Japanese.  Returns false if an encoding cannot be
identified.

Note: this only returns encoding names that start with C<cp>.

=cut

sub get_encoding
{
   my $key = _get_codepage_reg_key() || return;
   my $codepage = $key->GetValue("ACP") || $key->GetValue("OEMCP");
   return unless $codepage && $codepage =~ m/^[0-9a-fA-F]+$/s;
   return "cp".lc($codepage);
}

=item get_ms_codepage

Returns the numeric language ID for the current codepage language.
For example C<0x0409> for en-us or C<0x0411> for ja.  Returns false if
the codepage cannot be identified.

=cut

sub get_ms_codepage
{
   my $key = _get_lang_reg_key() || return;
   my $codepage = $key->GetValue("Default");
   return unless $codepage && $codepage =~ m/^[0-9a-fA-F]+$/s;
   return hex($codepage);  # from hex string to number
}

=item get_ms_install_codepage

Returns the numeric language ID for the installed codepage language.  This
is the same as get_ms_codepage(), but refers to the codepage that was the
default when Windows was first installed.

=cut

sub get_ms_install_codepage
{
   my $key = _get_lang_reg_key() || return;
   my $codepage = $key->GetValue("InstallLanguage");
   return unless $codepage && $codepage =~ m/^[0-9a-fA-F]+$/s;
   return hex($codepage);  # from hex string to number
}

# Returns the Windows registry entry for codepages
sub _get_codepage_reg_key
{
   my $codekey;
   local $SIG{__DIE__} = 'DEFAULT';
   eval {
      use Win32::TieRegistry ();
      $codekey = Win32::TieRegistry->new($CODEPAGE_REGISTRY_KEY,
                                         { Delimiter => "/" }
                                        );
   };
   return $codekey;
}

# Returns the Windows registry entry for languages
sub _get_lang_reg_key
{
   my $langkey;
   local $SIG{__DIE__} = 'DEFAULT';
   eval {
      use Win32::TieRegistry ();
      $langkey = Win32::TieRegistry->new($LANGUAGE_REGISTRY_KEY,
                                         { Delimiter => "/" }
                                        );
   };
   return $langkey;
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media, Inc. I<cpan@clotho.com>

Primary developer: Chris Dolan
