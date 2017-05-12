#!/usr/bin/perl

# examples/lookup.pl
#  Look up a user
#
# $Id: 03live.t 6960 2009-05-08 03:31:28Z FREQUENCY@cpan.org $

use Getopt::Long;
use Pod::Usage;

=head1 NAME

lookup.pl - Simple program to look up a user

=head1 SYNOPSIS

lookup.pl [options]

 Options:
  --help          Displays a brief help message
  --first[=NAME]  Look up a given first name
  --last[=NAME]   Look up a given last name

Both C<first> and C<last> are optional parameters, but at least one must
be specified. You can use them together, though.

=cut

my $help = 0;
my $first, $last;
GetOptions(
  'help|?'  => \$help,
  'first=s' => \$first,
  'last=s'  => \$last
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(1) unless (defined $first or defined $last);

use WebService::UWO::Directory::Student;
my $dir = WebService::UWO::Directory::Student->new;

# Normal lookup functionality
my $res = $dir->lookup({
  first => $first,
  last  => $last,
});

if (!$res) {
  print "Could not find any results for the given names\n";
  exit;
}

foreach my $user (@{$res}) {
  printf "Given name: %s\n", $user->{given_name};
  printf "Surname:    %s\n", $user->{last_name};
  printf "Email:      %s\n", $user->{email};
  printf "Faculty:    %s\n\n", $user->{faculty};
}

=head1 CAVEATS

This doesn't support e-mail lookups, though the module itself does. I was
too lazy to write a file showing that functionality.
