#! /usr/local/bin/perl
#---------------------------------------------------------------------
# accounts.pl
# Copyright 2007 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Example of using the Accounts API
#---------------------------------------------------------------------

use strict;
use warnings;
use WebService::NFSN;

my ($user, $key) = @ARGV;

die "Usage: $0 USER API_KEY\n" unless defined $key;

my $nfsn = WebService::NFSN->new($user, $key);

print "Listing accounts for $user...\n\n";

eval {
  my $accounts = $nfsn->member->accounts;

  foreach my $account (@$accounts) {
    my $a = $nfsn->account($account);

    print  "Account ID: $account\n";
    printf "      Name: %s\n",   $a->friendlyName;
    printf "   Balance: \$%s\n", $a->balance;
    printf "      Cash: \$%s\n", $a->balanceCash;
    printf "    Credit: \$%s\n", $a->balanceCredit;
    printf "    Status: %s\n",   $a->status->{status};
    print  "\n";

##  # This would change the friendlyName back to the Account ID:
##  $a->friendlyName($account);

  } # end foreach $account
}; # end eval

# This is pointless, since we're just duplicating what would happen
# automatically if you removed the eval above.  But it demonstrates
# how to catch exceptions.
if ($@) {
  my $e = Exception::Class->caught('WebService::NFSN::NFSNError');
  unless ($e) { ref $@ ? $@->rethrow : die $@ }

  print STDERR $e->as_string;
  exit 1;
} # end if error thrown from eval
