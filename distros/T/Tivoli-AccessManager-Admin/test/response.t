#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:Response.pm
use strict;
use warnings;

use Test::More tests => 33;
use Term::ReadKey;
use Data::Dumper;
BEGIN {
    use_ok 'Tivoli::AccessManager::Admin';
}

my $resp = Tivoli::AccessManager::Admin::Response->new;
my (@foo,@bar,$baz);

isa_ok( $resp , 'Tivoli::AccessManager::Admin::Response' );


print "\nTESTING is* functions\n";
is( $resp->set_isok(0), 0, "Set isok" );
is( $resp->isok, 0 , "Testing isok");
is( $resp->set_iswarning(1), 1, "Setting iswarning" );
is( $resp->iswarning, 1, "Is a warning" );
is( $resp->set_iserror(1), 1, "Setting iserror" );
is( $resp->iserror, 1, "Is an error" );

# clean up after all that.
$resp = Tivoli::AccessManager::Admin::Response->new;

print "\nTESTING message\n";

is( $resp->messages, undef, "No messages yet");

is( $resp->set_message("foo baby"), 1, "Setting one message" );
is( $resp->messages, "foo baby", "Got it back" );

@foo = qw/bar baz blah/;
ok( $resp->set_message( @foo ), "Setting multiple messages" );
@bar = $resp->messages;
unshift @foo, 'foo baby';
is_deeply( \@bar,\@foo, "Got them all back" );
is( $resp->messages, $foo[0], "Getting top one back");

print "\nTESTING codes\n";
is( $resp->codes, 0, "What code" );

print "\nTESTING values\n";
is( $resp->set_value("Bwahahahaha"), 1, "Set the value" );
is( scalar($resp->value), "Bwahahahaha", "Got the value back" );
@foo = $resp->value;
is_deeply( \@foo, [], "Could not extract a list value from it");

$resp->set_isok(0);
is( scalar($resp->value), undef, "Couldn't get a value when isok is false");

@foo = qw/evil maniacal laughter/;
$resp->set_isok(1);
$resp->set_value("Bwahahahahaha",\@foo);
@bar = $resp->value;
is_deeply(\@bar,\@foo, "Set an array value");
is( scalar($resp->value),"Bwahahahahaha", "Preserved the scalar value");

@foo = qw/a b/;
$resp->set_value(@foo);
@bar = $resp->value;
is_deeply(\@bar,\@foo, "Set just an array value");
is( scalar($resp->value), 2, "Got the array count back");

$resp->set_value(\@foo);
@bar = $resp->value;
is_deeply(\@bar,\@foo, "Set just an array via reference");
is( scalar($resp->value), scalar(@foo), "Got the array count back");

$resp = Tivoli::AccessManager::Admin::Response->new;
is(scalar($resp->value),undef,"Couldn't get a value that wasn't set");

print "\nTESTING 'used' responses\n";

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $tam = Tivoli::AccessManager::Admin->new( password => $pswd);
$resp = $tam->accexpdate();

@foo = $resp->codes;
print "@foo\n";

is( $resp->iswarning, 0, "No warnings" );
is( $resp->iserror, 0, "No errors" );
is( $resp->isinfo, 0, "No info" );

$resp->set_message("Silly");
is( $resp->messages, 'Silly', 'Valid message');

$resp->set_value();
$resp->set_isok(0);
is($resp->isok,0, "isok working");

$resp = Tivoli::AccessManager::Admin::User->create( $tam, 
				  name => 'silly',
				  dn   => 'cn=silly,ou=dne,o=nowhere,c=us',
				  cn   => 'silly',
				  sn   => 'sillier',
				  password => 'pa$$w0rd' );
is( $resp->isok, 0, "Error from API works" );
is( $resp->iserror, 1, "No errors" );

@foo = $resp->codes;
$baz = $resp->codes;
