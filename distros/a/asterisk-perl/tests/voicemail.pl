#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::Voicemail;

use Data::Dumper;

my $vm = new Asterisk::Voicemail;

$vm->readconfig();
$vm->spooldirectory('/tmp/vm');
print "Spool directory: " . $vm->spooldirectory() . "\n";


#($pass, $fn, $email) = $vm->vmbox('1234');
#print "VM $pass $fn $email\n";
#print Dumper $vm;
$vm->createdefaultmailbox('9999');
$vm->createdefaultmailbox('1234');

print $vm->validmailbox('9999') . "\n";
print $vm->validmailbox('1234') . "\n";
print $vm->validmailbox('5555') . "\n";

print "COUNT: " . $vm->msgcount('1234','INBOX') . "\n";
print  $vm->msgcountstr('1234','INBOX') . "\n";
