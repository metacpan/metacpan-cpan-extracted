package Win32::MSAgent;
use strict;
use warnings;
our $VERSION = 0.07;
use Win32::OLE;
use Win32::SAPI4;
use File::Find::Rule;
use File::Basename;
our (%CLSID, $AUTOLOAD);

BEGIN
{
    Win32::OLE->Initialize(Win32::OLE::COINIT_MULTITHREADED);

    %CLSID = ( MSAgent               => 'Agent.Control.2');
}

sub new
{
    my $proto = shift;
    my $char  = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{_object} = Win32::OLE->new($CLSID{MSAgent}) || return undef;
    bless $self, $class;

    $self->{_object}->SetProperty('Connected', 1);
    if ($char)
    {
        $self->Characters->Load($char, "$char.acs");
    }
    return $self;
}

sub AUTOLOAD
{
    my $self = shift;
    my @params = @_;
    (my $auto = $AUTOLOAD) =~ s/.*:://;
    return $self->{_object}->$auto(@params);
}

sub DESTROY
{
}

sub GetInstalledLanguages
{
    my $self = shift;
    $self->{_vt} ||= Win32::SAPI4::VoiceText->new();
    return grep {$_ ne 'unknown'} $self->{_vt}->GetInstalledLanguages;
}

sub GetInstalledVoices
{
    my $self = shift;
    my $language = shift;
    $self->{_vt} ||= Win32::SAPI4::VoiceText->new();
    return $self->{_vt}->GetInstalledVoices($language);
}

sub Language2LanguageID
{
    my $self = shift;
    my $language = shift;
    $self->{_vt} ||= Win32::SAPI4::VoiceText->new();
    return $self->{_vt}->Language2LanguageID($language);
}

sub Voice2ModeID
{
    my $self = shift;
    my $voice = shift;
    $self->{_vt} ||= Win32::SAPI4::VoiceText->new();
    return $self->{_vt}->Voice2ModeID($voice);
}

sub GetInstalledCharacters
{
    my $self = shift;
    # Find installed characters on this system
    my $systemroot = $ENV{SYSTEMROOT} || $ENV{WINDIR} || 'C:\WINDOWS';
    return map{if (lc(substr($_, -4)) eq '.acs') { ucfirst(lc(substr(basename($_), 0, -4))) }} File::Find::Rule->file->name(qr/\.acs/i)->in("$systemroot\\msagent\\chars");
}

=pod

=head1 NAME

Win32::MSAgent - Interface module for the Microsoft Agent

=head1 SYNOPSIS

    use Win32::MSAgent;
    my $agent = Win32::MSAgent->new('Genie');

    my $char = $agent->Characters('Genie');
    $char->SoundEffectsOn(1);
    $char->Show();

    $char->MoveTo(300,300);
    sleep(5);

    my $olenum = $c->AnimationNames();
    my $names = Win32::OLE::Enum->new($olenum);
    my @animations = $names->All();
    
    foreach my $animation (@animations)
    {
        my $request = $char->Play($animation);
        $char->Speak($animation);
        my $i = 0;
        while (($request->Status == 2) || ($request->Status == 4))
        { $char->Stop($request) if $i >10; sleep(1);  $i++}
    }

=head1 DESCRIPTION

Win32::MSAgent allows you to use the Microsoft Agent 2.0 OLE control in your
perl scripts. From the Microsoft Website: "With the Microsoft Agent set of 
software services, developers can easily enhance the user interface of their 
applications and Web pages with interactive personalities in the form of animated 
characters. These characters can move freely within the computer display, speak 
aloud (and by displaying text onscreen), and even listen for spoken voice commands."

Since the MS Agent itself is only available on MS Windows platforms, this module
will only work on those.

See the included demo.pl for some sample code.

=head1 PREREQUISITES

In order to use the MSAgent in your scripts, you need to download and install some
components. They can all be downloaded for free from http://www.microsoft.com/msagent/devdownloads.htm
for more information on installation of the neccesary components, visit http://www.pvoice.org/msagent.htm

=over 4

=item 1. Microsoft Agent Core Components

=item 2. Localized Language Components 

=item 3. MS Agent Character files (.acs files)

=item 4. Text To Speech engine for your language

=item 5. SAPI 4.0 runtime

=back

Optionally you can install the Speech Recognition Engines and the Speech Control Panel. The Speech
Recognition part of MS Agent is not supported in this version of Win32::MSAgent

=head1 USAGE

See the Microsoft Agent API reference for a complete description of all objects, properties and methods.
This module has some extra methods, which are described below.

=over 4

=item $agent = Win32::MSAgent->new([charactername])

The constructor optionally takes the name of the character to load. It 
loads the MS Agent OLE control, connects to it, and if the character name
is supplied, it loads that character in the Characters object already.
It returns the Win32::MSAgent object itself.

=item GetInstalledLanguages

This method returns a list of all installed languages with their
countryname. It may look like ('Dutch (Netherlands)', 'Dutch (Belgium)',
'English (United States)', 'Portuguese (Brazil)'). Some speechengines
(notably the Fluency TTS engines) don't return a languageID. In this
case this language is ignored, because the Microsoft Agent needs a languageID
to be able to work.

=item GetInstalledVoices

This method takes a language as returned by GetInstalledLanguages and returns
a list of all installed voices with their language.
It may look like ('Adult female (Dutch)', 'Microsoft Sam (US English)')

=item Language2LanguageID

This method takes a language as returned by GetInstalledLanguages and
returns the corresponding LanguageID that Win32::SAPI knows. This also
converts the 'unknown' that might be returned by GetInstalledLanguages
back to a 0.

=item Voice2ModeID

This method takes a voice as returned by GetInstalledVoices and
returns the corresponding ModeID that Win32::SAPI4 knows.

=item GetInstalledCharacters

This method checks the harddrive (at default locations) for the existance
of Agent Characters and returns their names in an array.

=back

=head1 BUGS

None AFAIK...

=head1 CAVEATS

Since version 0.6 the module is for a large part incompatible with previous
versions. Please check your code before deploying this version!

=head1 SUPPORT

The MS Agent itself is supported on MS' public newsgroup news://microsoft.public.msagent
You can email the author for support on this module.

=head1 AUTHOR

	Jouke Visser
	jouke@cpan.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

Copyright (c) 2002-2004 Jouke Visser. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

"Yet Another True Value";

__END__
