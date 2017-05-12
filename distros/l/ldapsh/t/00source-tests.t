#!perl
# vim: syntax=perl

#BEGIN {
#  require "t/common.pl";
#}


use strict;

print "1..4\n";

use Net::LDAP::Config;

sub ook {
	my ($a,$b) = @_;
	unless ($a eq $b) {
		print "not ";
	}

	print "ok ";
}
sub ok {
    my ($condition, $name) = @_;
  
    my $message = $condition ? "ok " : "not ok ";
    #$message .= ++$number;
    $message .= " # $name" if defined $name;
    print $message, "\n";
    return $condition;
}
my $infile   = "examples/ldapsh_profile";

my $config = Net::LDAP::Config->new('config' => $infile, "source" => "default");

ok($config->config eq $infile, "file eq $infile");
ok($config->source eq "default", "source eq default");
ok($config->base eq "dc=domain,dc=com", "base eq dc=domain,dc=com");
ok($config->ssl eq "prefer", "ssl eq prefer");
