#!/usr/bin/perl
use strict;
use warnings;
use Win32::MSAgent;

my $agent = Win32::MSAgent->new();

my @chars = $agent->GetInstalledCharacters();
print "I did not find any Microsoft Agent Character files on your system\n" unless @chars;
my $char = $chars[0];
print "I found character $char\n";
my $c;

$agent->Characters->Load($char, "$char.acs");
$c = $agent->Characters($char);
$c->Show();
$c->MoveTo(300,300);
sleep(5);

# If you want speech output, you have to set the $c->Voice('language', 'Voice') here
# But since I don't know what you installed, I'm doing nothing here
my $olenum = $c->AnimationNames();
my $names = Win32::OLE::Enum->new($olenum);
my @animations = $names->All();

foreach my $animation (@animations)
{
    my $request = $c->Play($animation);
    $c->Speak($animation);
    my $i = 0;
    while ((defined $request) &&($request->Status == 2) || ($request->Status == 4))
    { $c->Stop($request) if $i >10; sleep(1);  $i++}
}
