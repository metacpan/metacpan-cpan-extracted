package VCS::CMSynergy::Helper;

# Copyright (c) 2001-2015 argumentum GmbH
# See COPYRIGHT section in VCS/CMSynergy.pod for usage and distribution rights.

use strict;
use warnings;

=head1 NAME

VCS::CMSynergy::Helper - ancillary convenience functions

=head1 SYNOPSIS

  my $ccm_opts = VCS::CMSynergy::Helper::GetOptions;

=head2 GetOptions

This function extracts a set of common options from C<@ARGV> and converts
them to the corresponding options for L<VCS::CMSynergy/new>.
All options and arguments in C<@ARGV> that it doesn't know about
are left untouched.

It may be used to make all your Synergy scripts accept a
uniform set of options:

  use Getopt::Long;
  use Pod::Usage;
  use VCS::CMSynergy;
  use VCS::CMSynergy::Helper;
  ...

  # extract Synergy options from @ARGV
  my $ccm_opts = VCS::CMSynergy::Helper::GetOptions or pod2usage();

  # process other options in @ARGV
  GetOptions(...) or pod2usage();

  # start Synergy session
  my $ccm = VCS::CMSynergy->new(
      %$ccm_opts,
      RaiseError => 1,
      PrintError => 0);
  ...

The following options are recognized:

=over 4

=item C<-D>, C<--database>

absolute database path; this option corresponds to option C<database>
for C<VCS::CMSynergy/start>

=item C<-S>, C<--server>

server URL; this option corresponds to option C<server> for
for C<VCS::CMSynergy/start>

=item C<-U>, C<--user>

user; this option corresponds to option C<user>
for C<VCS::CMSynergy/start>

=item C<-P>, C<--password>

user's password; this option corresponds to option C<password> for
for C<VCS::CMSynergy/start>

=back

C<GetOptions> returns a reference to a hash of options suitable
for passing to L<VCS::CMSynergy/new>.  If no C<--database> is specified

  CCM_ADDR => $ENV{CCM_ADDR}

is added to the hash.

If any error is encountered during option processing
the error is signalled using C<warn()> and C<undef> is returned.

Note that all recognized single letter options are in uppercase so that
scripts using C<VCS::CMSynergy::Helper::GetOptions> still
can use all lowercase letters for their own options.

Here's the short description of recognized options that you
can cut and paste into your script's POD:

  Synergy Options:

  -D PATH | --database PATH       database path
  -S URL | --server URL           server URL
  -U NAME | --user NAME           user name
  -P STRING | --password STRING   user's password

=cut

use Getopt::Long ();

sub GetOptions
{
    my $saved_config = Getopt::Long::Configure("passthrough");

    my %opts;
    Getopt::Long::GetOptions(\%opts,
        'database|D=s',
        'server|S=s',
        'user|U=s',
        'password|P=s') or return;

    Getopt::Long::Configure($saved_config);

    $opts{CCM_ADDR} = $ENV{CCM_ADDR} unless defined $opts{database};

    return \%opts;
}

1;
