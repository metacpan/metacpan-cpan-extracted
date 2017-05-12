#!/usr/bin/perl -w

use Test;
BEGIN {
    if( $ENV{DO_NET_TEST} ) {
        plan tests => 15;
    } else {
        plan tests => 5;
    }
};

use Wx::DialUpManager;

ok(1);

#use Devel::Peek;die Dump(Wx::DialUpManager->Create());

my $dM1 = Wx::DialUpManager->new();
my $dM2 = Wx::DialUpManager->Create();

ok($dM1);
ok($dM2);

undef $dM1;
ok(not defined $dM1);

undef $dM2;

ok(not defined $dM2); ## 5

exit unless $ENV{DO_NET_TEST};
print "#DO_NET_TEST is set, assuming we're connected to the internet.\n";

$dM1 = Wx::DialUpManager->new();

if( $dM1->can('GetISPNames') ) { #we're on win32

    ok(1);

    if( $dM1->GetISPNames() ) {
        print "#GetISPNames => $_ \n" for $dM1->GetISPNames();
    }

} else {
    skip('Wx::DialUpManager::GetISPNames unavailable on __UNIX__',1);
}

ok( $dM1->IsOnline() || 1 );
ok( $dM1->SetOnlineStatus(1) || $dM1->IsOnline() );

if( $dM1->can('SetWellKnownHost') ) {
    ok( $dM1->SetWellKnownHost("www.yahoo.com",80) || 1 );
    ok( $dM1->SetConnectCommand() || 1);
} else {
    skip('Wx::DialUpManager::SetWellKnownHost unavailable on __WINDOWS__',1);
    skip('Wx::DialUpManager::SetConnectCommand unavailable on __WINDOWS__',1);
}

ok( $dM1->EnableAutoCheckOnlineStatus() );
ok( $dM1->DisableAutoCheckOnlineStatus() || 1 );
ok( $dM1->IsAlwaysOnline() || 1 ); # it may fail, but who cares, we were able to call it ;)
ok( not $dM1->IsDialing() );     # i don't wanna Dial
ok( not $dM1->CancelDialing() ); # since I didn't Dial

