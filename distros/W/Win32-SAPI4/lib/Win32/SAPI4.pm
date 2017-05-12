#!/usr/bin/perl
package Win32::SAPI4;
use strict;
use warnings;
use Win32::OLE;
our $VERSION     = 0.08;
our (%CLSID, $AUTOLOAD);
BEGIN
{
    Win32::OLE->Initialize(Win32::OLE::COINIT_MULTITHREADED);

    %CLSID = ( VoiceText               => '{2398E32F-5C6E-11D1-8C65-0060081841DE}',
               VoiceCommand            => '{66523042-35FE-11D1-8C4D-0060081841DE}',
               VoiceDictation          => '{582C2191-4016-11D1-8C55-0060081841DE}',
               VoiceTelephony          => '{FC9E740F-6058-11D1-8C66-0060081841DE}',
               DirectSpeechRecognition => '{4E3D9D1F-0C63-11D1-8BFB-0060081841DE}',
               DirectSpeechSynthesis   => '{EEE78591-FE22-11D0-8BEF-0060081841DE}'                   
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
    return $self->{_object};
}

sub DESTROY
{
}

package Win32::SAPI4::VoiceText;
use Win32::Locale;
use Locale::Country;
use Locale::Language;
use base 'Win32::SAPI4';

sub GetInstalledLanguages
{
    my $self = shift;
    my %r;
    for (my $i=1; $i <= $self->{_object}->CountEngines; $i++)
    {
        my $lang = Win32::Locale::get_language($self->{_object}->LanguageID($i));
        if ($lang)
        {
            my ($t1, $t2) = split(/-/,$lang);
            my $key = code2language($t1);
            $key.= " (".code2country($t2).")" if code2country($t2);
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
    for (my $i=1; $i <= $self->{_object}->CountEngines; $i++)
    {
        my $lang = Win32::Locale::get_language($self->{_object}->LanguageID($i));
        if ($lang)
        {
            my ($t1, $t2) = split(/-/,$lang);
            my $key = code2language($t1);
            $key.= " (".code2country($t2).")" if code2country($t2);
            push @r, $self->{_object}->ModeName($i) if $language eq $key;
        }
        else
        {
            push @r, $self->{_object}->ModeName($i) unless $language;
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
    for (my $i=1; $i <= $self->{_object}->CountEngines; $i++)
    {
        my $lang = Win32::Locale::get_language($self->{_object}->LanguageID($i));
        my ($t1, $t2) = split(/-/,$lang);
        my $key = code2language($t1);
        $key.= " (".code2country($t2).")" if code2country($t2);
        return $self->{_object}->LanguageID($i) if $language eq $key;
    }
}

sub Voice2ModeID
{
    my $self = shift;
    my $voice = shift;
    for (my $i=1; $i <= $self->{_object}->CountEngines; $i++)
    {
        return $self->{_object}->ModeID($i) if $voice eq $self->{_object}->ModeName($i);
    }
}


package Win32::SAPI4::VoiceCommand;
use base 'Win32::SAPI4';

package Win32::SAPI4::VoiceDictation;
use base 'Win32::SAPI4';

package Win32::SAPI4::VoiceTelephony;
use base 'Win32::SAPI4';

package Win32::SAPI4::DirectSpeechRecognition;
use base 'Win32::SAPI4';

package Win32::SAPI4::DirectSpeechSynthesis;
use base 'Win32::SAPI4';

=pod

=head1 NAME

Win32::SAPI4 - Perl interface to the Microsoft Speech API 4.0

=head1 SYNOPSIS

    use Win32::SAPI4;
    
    my $vt   = Win32::SAPI4::VoiceText->new();
    my $dss  = Win32::SAPI4::DirectSpeechSynthesis->new();
    my $dsr  = Win32::SAPI4::DirectSpeechRecognition->new();
    my $vtel = Win32::SAPI4::VoiceTelephony->new();    
    my $vd   = Win32::SAPI4::VoiceDictation->new();
    my $vc   = Win32::SAPI4::VoiceCommand->new();

=head1 DESCRIPTION

This module is a simple interface to the Microsoft Speech API 4.0.
It just offers 6 constructors to the different parts of this API, along with a few utility
methods for the VoiceText class.
This documentation won't offer the complete documentation for it, just
download the Microsoft Speech API 4.0 SDK and read the Visual Basic
documentation. It's all there, except for the few convenience methods I
added to Win32::SAPI::VoiceText.

=head1 PREREQUISITES

The Microsoft Speech API 4.0. It can be downloaded for free from 
http://www.microsoft.com/speech (go to the 'old versions' and 
find the 4.0 version)

=head1 USAGE

See the Microsoft Speech API 4.0 Visual Basic documentation for 
all methods, properties and events available, except the following:

=head2 Win32::SAPI4::*

=over 4

=item new

This is the constructor for each and every subclass. It doesn't take any parameters

=item GetObject

All classes support the GetObject method which returns the actual Win32::OLE
object. This may be useful when you need to pass the object as a parameter
to another class' methods.

=back

=head2 Win32::SAPI4::VoiceText

=over 4

=item GetInstalledLanguages

This method returns a list of all installed languages with their
countryname. It may look like ('Dutch (Netherlands)', 'Dutch (Belgium)',
'English (United States)', 'Portuguese (Brazil)'). Some speechengines
(notably the Fluency TTS engines) don't return a languageID. In this
case 'unknown' is returned.

=item GetInstalledVoices

This method takes a language as returned by GetInstalledLanguages and returns
a list of all installed voices with their language.
It may look like ('Adult female (Dutch)', 'Microsoft Sam (US English)')

=item Language2LanguageID

This method takes a language as returned by GetInstalledLanguages and
returns the corresponding LanguageID that VoiceText knows. This also
converts the 'unknown' that might be returned by GetInstalledLanguages
back to a 0.

=item Voice2ModeID

This method takes a voice as returned by GetInstalledVoices and
returns the corresponding ModeID that VoiceText knows.

=back

=head1 SUPPORT

The Microsoft SAPI 4.0 SDK is supported on news://microsoft.public.speech_tech.sdk
You can email the author for support on this module.

=head1 AUTHOR

	Jouke Visser
	jouke@cpan.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

Copyright (c) 2003-2004 Jouke Visser. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1), Microsoft Speech API 4 documentation.

=cut

1;