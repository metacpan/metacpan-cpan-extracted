#!/usr/bin/perl
package Win32::SAPI5;
use strict;
use warnings;
use Win32::OLE;
our $VERSION = 0.05;
our (%CLSID, $AUTOLOAD);
BEGIN
{
 Win32::OLE->Initialize(Win32::OLE::COINIT_MULTITHREADED);

 %CLSID = ( 
             SpNotifyTranslator         => "{E2AE5372-5D40-11D2-960E-00C04F8EE628}",
             SpObjectTokenCategory      => "{A910187F-0C7A-45AC-92CC-59EDAFB77B53}",
             SpObjectToken              => "{EF411752-3736-4CB4-9C8C-8EF4CCB58EFE}",
             SpResourceManager          => "{96749373-3391-11D2-9EE3-00C04F797396}",
             SpStreamFormatConverter    => "{7013943A-E2EC-11D2-A086-00C04F8EF9B5}",
             SpMMAudioEnum              => "{AB1890A0-E91F-11D2-BB91-00C04F8EE6C0}",
             SpMMAudioIn                => "{CF3D2E50-53F2-11D2-960C-00C04F8EE628}",
             SpMMAudioOut               => "{A8C680EB-3D32-11D2-9EE7-00C04F797396}",
             SpRecPlayAudio             => "{FEE225FC-7AFD-45E9-95D0-5A318079D911}",
             SpStream                   => "{715D9C59-4442-11D2-9605-00C04F8EE628}",
             SpVoice                    => "{96749377-3391-11D2-9EE3-00C04F797396}",
             SpSharedRecoContext        => "{47206204-5ECA-11D2-960F-00C04F8EE628}",
             SpInprocRecognizer         => "{41B89B6B-9399-11D2-9623-00C04F8EE628}",
             SpSharedRecognizer         => "{3BEE4890-4FE9-4A37-8C1E-5E7E12791C1F}",
             SpLexicon                  => "{0655E396-25D0-11D3-9C26-00C04F8EF87C}",
             SpUnCompressedLexicon      => "{C9E37C15-DF92-4727-85D6-72E5EEB6995A}",
             SpCompressedLexicon        => "{90903716-2F42-11D3-9C26-00C04F8EF87C}",
             SpPhoneConverter           => "{9185F743-1143-4C28-86B5-BFF14F20E5C8}",
             SpNullPhoneConverter       => "{455F24E9-7396-4A16-9715-7C0FDBE3EFE3}",
             SpTextSelectionInformation => "{0F92030A-CBFD-4AB8-A164-FF5985547FF6}",
             SpPhraseInfoBuilder        => "{C23FC28D-C55F-4720-8B32-91F73C2BD5D1}",
             SpAudioFormat              => "{9EF96870-E160-4792-820D-48CF0649E4EC}",
             SpWaveFormatEx             => "{C79A574C-63BE-44b9-801F-283F87F898BE}",
             SpInProcRecoContext        => "{73AD6842-ACE0-45E8-A4DD-8795881A2C2A}",
             SpCustomStream             => "{8DBEF13F-1948-4aa8-8CF0-048EEBED95D8}",
             SpFileStream               => "{947812B3-2AE1-4644-BA86-9E90DED7EC91}",
             SpMemoryStream             => "{5FB7EF7D-DFF4-468a-B6B7-2FCBD188F994}",
 );
}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    (my $subclass = $proto) =~ s/.*:://;
    $self->{_object} = Win32::OLE->new($CLSID{$subclass}) || return undef;
    bless $self, $class;
    return $self;
}

sub AUTOLOAD
{
    my $self = shift;
    my @params = @_;
    (my $auto = $AUTOLOAD) =~ s/.*:://;
    return $self->{_object}->$auto(@params);
}

sub GetObject
{
    my $self = shift;
    return $self->{_object}
}

sub DESTROY
{
}

package Win32::SAPI5::SpVoice;
use base 'Win32::SAPI5';
use Win32::Locale;
use Locale::Country;
use Locale::Language;

sub GetInstalledLanguages
{
    my $self = shift;
    my %r;
    my $tokens = $self->GetVoices;
    for (my $i = 0; $i < $tokens->Count; $i++)
    {
        my ($lang, undef) = split(/;/,$tokens->Item($i)->GetAttribute('Language'));
        if ($lang)
        {
            $lang = Win32::Locale::get_language(hex("0x$lang"));
            my ($t1, $t2) = split(/-/,$lang);
            my $key = code2language($t1);
            $key.= " (".code2country($t2).")" if defined code2country($t2);
            $r{$key}++;
        }
        else
        {
            $r{'unknown'}++
        }
    }
    return keys %r;
}

sub GetInstalledVoices
{
    my $self = shift;
    my $language = shift;
    $language = '' if $language eq 'unknown';
    my @r;
    my $tokens = $self->GetVoices;
    for (my $i = 0; $i < $tokens->Count; $i++)
    {
        my ($lang, undef) = split(/;/,$tokens->Item($i)->GetAttribute('Language'));
        $lang = Win32::Locale::get_language(hex("0x$lang"));
        if ($lang)
        {
            my ($t1, $t2) = split(/-/,$lang);
            my $key = code2language($t1);
            $key.= " (".code2country($t2).")" if defined code2country($t2);
            push @r, ($tokens->Item($i)->GetDescription||$tokens->Item($i)->GetAttribute('Name')) if $language eq $key;
        }
        else
        {
            push @r, ($tokens->Item($i)->GetDescription||$tokens->Item($i)->GetAttribute('Name')) unless $language;
        }
    }
    return @r;
}

sub Language2LanguageID
{
    my $self = shift;
    my $language = shift;
    $language = '' if $language eq 'unknown';
    return '0' unless $language;
    my $tokens = $self->GetVoices;
    for (my $i = 0; $i < $tokens->Count; $i++)
    {
        my ($langid, undef) = split(/;/,$tokens->Item($i)->GetAttribute('Language'));
        my $lang = Win32::Locale::get_language(hex("0x$langid"));
        my ($t1, $t2) = split(/-/,$lang);
        my $key = code2language($t1);
        $key.= " (".code2country($t2).")" if code2country($t2);
        return hex("0x$langid") if $language eq $key;
    }
}

sub Voice2ModeID
{
    my $self = shift;
    my $voice = shift;
    my $tokens = $self->GetVoices;
    for (my $i = 0; $i < $tokens->Count; $i++)
    {
        if ($voice eq ($tokens->Item($i)->GetDescription||$tokens->Item($i)->GetAttribute('Name')))
        {
            return $tokens->Item($i)->Id
        }
    }
}

package Win32::SAPI5::SpNotifyTranslator;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpObjectTokenCategory;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpObjectToken;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpResourceManager;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpStreamFormatConverter;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpMMAudioEnum;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpMMAudioIn;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpMMAudioOut;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpRecPlayAudio;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpStream;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpSharedRecoContext;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpInprocRecognizer;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpSharedRecognizer;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpLexicon;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpUnCompressedLexicon;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpCompressedLexicon;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpPhoneConverter;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpNullPhoneConverter;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpTextSelectionInformation;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpPhraseInfoBuilder;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpAudioFormat;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpWaveFormatEx;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpInProcRecoContext;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpCustomStream;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpFileStream;
use base 'Win32::SAPI5';

package Win32::SAPI5::SpMemoryStream;
use base 'Win32::SAPI5';


=pod

=head1 NAME

Win32::SAPI5 - Perl interface to the Microsoft Speech API 5.1

=head1 SYNOPSIS

    use Win32::SAPI5;
    
    my $object = Win32::SAPI5::SpVoice->new();
    my $object = Win32::SAPI5::SpNotifyTranslator->new();
    my $object = Win32::SAPI5::SpObjectTokenCategory->new();
    my $object = Win32::SAPI5::SpObjectToken->new();
    my $object = Win32::SAPI5::SpResourceManager->new();
    my $object = Win32::SAPI5::SpStreamFormatConverter->new();
    my $object = Win32::SAPI5::SpMMAudioEnum->new();
    my $object = Win32::SAPI5::SpMMAudioIn->new();
    my $object = Win32::SAPI5::SpMMAudioOut->new();
    my $object = Win32::SAPI5::SpRecPlayAudio->new();
    my $object = Win32::SAPI5::SpStream->new();
    my $object = Win32::SAPI5::SpSharedRecoContext->new();
    my $object = Win32::SAPI5::SpInprocRecognizer->new();
    my $object = Win32::SAPI5::SpSharedRecognizer->new();
    my $object = Win32::SAPI5::SpLexicon->new();
    my $object = Win32::SAPI5::SpUnCompressedLexicon->new();
    my $object = Win32::SAPI5::SpCompressedLexicon->new();
    my $object = Win32::SAPI5::SpPhoneConverter->new();
    my $object = Win32::SAPI5::SpNullPhoneConverter->new();
    my $object = Win32::SAPI5::SpTextSelectionInformation->new();
    my $object = Win32::SAPI5::SpPhraseInfoBuilder->new();
    my $object = Win32::SAPI5::SpAudioFormat->new();
    my $object = Win32::SAPI5::SpWaveFormatEx->new();
    my $object = Win32::SAPI5::SpInProcRecoContext->new();
    my $object = Win32::SAPI5::SpCustomStream->new();
    my $object = Win32::SAPI5::SpFileStream->new();
    my $object = Win32::SAPI5::SpMemoryStream->new();

=head1 DESCRIPTION

This module is a simple interface to the Microsoft Speech API 5.1
There are interfaces to all classes that this API consists of. The constructors return
Win32::OLE objects, on which you can call all methods and get/set all
properties.

This documentation won't offer the complete documentation for it, just
download the Microsoft Speech API 5.1 SDK and read the part of the 
documentation that covers 'Automation' (since we're using the Automation Object interface.

=head1 PREREQUISITES

The Microsoft Speech API 5.1. It can be downloaded for free from 
http://www.microsoft.com/speech (go to the 'old versions' and 
find the 5.1 version)

=head1 USAGE

See the Microsoft Speech API 5.1 documentation that comes with the SDK, except
for the following utility methods available for Win32::SAPI5::SpVoice:

=head2 Win32::SAPI5::*

=over 4

=item new

This is the constructor for each and every Win32::SAPI5 subclass. It does not take any parameters

=item GetObject

All classes support the GetObject method, which will return the actual
Win32::OLE object. This can be useful when you need to pass the object itself
as a parameter to a method of another object.

for example:

  # setup Microsoft Speech API
  my $stream = Win32::SAPI5::SpFileStream->new();
  $stream->Open($wav, 3, 0); # 3 = SSFMCreateForWrite

  my $voice = Win32::SAPI5::SpVoice->new();
  $voice->SetProperty(AudioOutputStream => $stream->GetObject);

=back

=head2 Win32::SAPI5::SpVoice

To be somewhat compatible with Win32::SAPI4::VoiceText, I've added the
utilitymethods that exist there to Win32::SAPI5::SpVoice, to be able to
apply the same code to this API.

=over 4

=item GetInstalledLanguages

This method returns a list of all installed languages with their
countryname. It may look like ('Dutch (Netherlands)', 'Dutch (Belgium)',
'English (United States)', 'Portuguese (Brazil)'). Some speechengines
might not return a languageID. In this
case 'unknown' is returned.

=item GetInstalledVoices

This method takes a language as returned by GetInstalledLanguages and returns
a list of all installed voices with their language.
It may look like ('Adult female (Dutch)', 'Microsoft Sam (US English)')

=item Language2LanguageID

This method takes a language as returned by GetInstalledLanguages and
returns the corresponding LanguageID that SpVoice knows. This also
converts the 'unknown' that might be returned by GetInstalledLanguages
back to a 0.

=item Voice2ModeID

This method takes a voice as returned by GetInstalledVoices and
returns the corresponding ModeID that SpVoice knows.

=back

=head1 SUPPORT

The Microsoft SAPI 5.1 SDK is supported on news://microsoft.public.speech_tech.sdk
You can email the author for support on this module.

=head1 AUTHOR

	Jouke Visser
	jouke@cpan.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

Copyright (c) 2004 Jouke Visser. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1), Microsoft Speech API 5.1 documentation.

=cut

1;