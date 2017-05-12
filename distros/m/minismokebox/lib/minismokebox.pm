package minismokebox;
$minismokebox::VERSION = '0.66';
#ABSTRACT: a small lightweight SmokeBox

use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

minismokebox - a small lightweight SmokeBox

=head1 VERSION

version 0.66

=head1 SYNOPSIS

 minismokebox [options]

 Options:
   --debug	     - display all the output from tests as they are run;
   --help	     - Display program usage;
   --version	     - Display program version;
   --perl PERL	     - specify the perl executable to use for testing;
   --indices	     - Reload indices before proceeding with testing;
   --recent	     - Explictly smoke recent uploads, usually the default;
   --jobs FILE	     - Specify a file with modules to be smoked;
   --backend BACKEND - specify a SmokeBox backend to use;
   --author PATTERN  - specify a CPAN ID to search for modules to smoke;
   --package PATTERN - specify a search pattern to match against distributions;
   --random          - specify a random selection of dists to smoke;
   --phalanx	     - smoke the Phalanx 100 distributions;
   --reverse	     - specify that RECENT uploads are smoked in reverse order;
   --url URI	     - The URI of a CPAN mirror to use, default is CPAN Testers FTP;
   --home DIR       - Set a fake HOME directory for spawned smokers to use;
   --nolog          - Set to disable stdout/stderr logging in jobs;
   --rss            - set to use the rss recent file instead of the default;
   --noepoch        - set to disable only smoking the most recent uploads;
   --perlenv        - set to enable PERL5LIB being passed to smoker process;

=head1 DESCRIPTION

C<minismokebox> is a lightweight version of SmokeBox that performs CPAN testing on a single
C<perl> installation.

It is usually installed into a separate C<perl> installation than the C<perl> which is being
tested, the system C<perl> for instance.

   /usr/bin/minismokebox --perl /home/cpan/sandbox/perl-5.10.0/bin/perl

The above command will run C<minismokebox> which will obtain a list of recently uploaded distributions
to CPAN and then proceed to C<smoke> each of these distributions against the indicated C<perl>.

C<minismokebox> supports a number of different CPAN Tester frameworks ( in L<POE::Component::SmokeBox>
parlance a C<backend> ), currently, L<CPANPLUS::YACSmoke>, L<CPAN::Reporter> and L<CPAN::YACSmoke>.

   /usr/bin/minismokebox --perl /home/cpan/sandbox/perl-5.10.0/bin/perl # uses default 'CPANPLUS::YACSmoke'

   /usr/bin/minismokebox --perl /home/cpan/sandbox/perl-5.10.0/bin/perl --backend CPAN::Reporter

   /usr/bin/minismokebox --perl /home/cpan/sandbox/perl-5.10.0/bin/perl --backend CPAN::YACSmoke

C<minismokebox> will C<check> that the selected backend exists in the indicated C<perl> before proceeding
with the C<smoke> phase. This is very simple check and does not test whether the smoke environment is
properly configured to send test reports, etc. Consult the applicable documentation for instructions on
how to configure the testing environment. ( See the links below in L</"SEE ALSO"> ).

=head1 WARNING

There are risks associated with CPAN smoke testing. You are effectively downloading and executing arbitary
code on your system.

Here are some tips to mitigate the risks:

=over

=item Use a C<sandbox> account

Don't run smoke tests as C<root> or other priviledged user. Create a separate user account to smoke test
under. For the even more paranoid you can give the C<HOME> directory for this user account a separate
filesystem.

=item Use a virtualised system

Virtualise your testing environment with Xen, Vmware, VirtualBox, etc. If the system does get hosed you can
recover it from a snapshot backup very quickly.

=item Chown the C<perl> installation to C<root>

Making sure that the user who is running the smoke testing can't write to the C<perl> installation is a very good
plan. There have been incidents in the past where a recalcitrant module has managed to trash smoke test
environments.

=item Monitor your C<TEMP> file area

Keep an eye on the C</tmp> directory, a lot of test-suites leave droppings behind.

=back

=head1 COMMAND LINE OPTIONS

Command line options override options given in the L</"CONFIGURATION FILE">

=over

=item C<--debug>

Turns on all output from the L<POE::Component::SmokeBox::Backend> as distributions are smoked.

=item C<--help>

Displays program usage and exits.

=item C<--version>

Displays the program version and exits.

=item C<--perl PERL>

The path to a C<perl> executable to run the smoke testing against. If this isn't specified C<minismokebox> will
use C<$^X> to determine the current C<perl> and use that.

=item C<--backend BACKEND>

Specify a particular L<POE::Component::SmokeBox::Backend> to use for smoking. This can be L<CPANPLUS::YACSmoke>,
L<CPAN::YACSmoke> or L<CPAN::Reporter>. The default if this isn't specified is L<CPANPLUS::YACSmoke>.

=item C<--indices>

Indicates that C<minismokebox> should reindex the particular backend before proceeding with the smoke testing.

=item C<--url URI>

The URI of a CPAN Mirror that C<minismokebox> will use to obtain the recent uploads from or perform C<package>,
C<author> and C<phalanx> searches against. For consistency this should really match the CPAN Mirror configured in
the applicable backend you are using.

=item C<--home DIR>

The path to a directory that will become the C<HOME> environment variable in spawned smoke processes. It will be
created if it does not exist.

=item C<--nolog>

If enabled the C<STDOUT> and C<STDERR> of job output will not be logged.

=back

The following options control where C<minismokebox> obtains a list of distributions to smoke. If none of these are
specified the default behaviour is C<--recent>. These options are cumulative. For example:

  minismokebox --perl /home/cpan/perl-5.10.0/bin/perl --recent --package '^POE' --author '^BI' --phalanx

This would smoke a list of recent uploads, all distributions that begin with C<POE>, the distributions for each
CPAN author whose CPAN ID begins with C<BI> and a list of the Phalanx 100 distributions.

=over

=item C<--recent>

Explicitly tell C<minismokebox> to smoke the recent uploads to CPAN. This is the default action if none of the following
actions are given.

=item C<--rss>

Enabling this option will tell C<minismokebox> to use the C<modules/01modules.mtime.rss> file instead of the default
C<RECENT> file to discover recent CPAN uploads.

=item C<--noepoch>

Enabling this option will disable the use of C<RECENT-1x.yaml> files to determine the very most recent uploads
to smoke.

=item C<--perlenv>

Normally C<minismokebox> ( via L<POE::Component::SmokeBox::Backend> ) will C<sanctify> the smoker process'
environment variables to remove various C<perl> related variables. Enabling this option will pass C<PERL5LIB>
environment variable to the smoker process if it is defined. This could have weird side-effects, use with caution.

=item C<--reverse>

If specified C<minismokebox> will smoke recent uploads in reverse order.

=item C<--jobs FILE>

Indicate a file where C<minismokebox> should get a list of distributions to smoke from, eg.

  C/CH/CHROMATIC/Acme-Incorporated-1.00.tar.gz
  B/BI/BINGOS/POE-Component-IRC-5.12.tar.gz

=item C<--package PATTERN>

Specify a string representing a package search to find distributions to smoke. The pattern is a regular expression and is
applied to the package or distribution name plus version number ( the so called distvname, see L<CPAN::DistnameInfo> ), eg.

  --package '^POE'  # find all distributions that begin with POE
  --package 'IRC'   # find all IRC related distributions
  --package '0.01'  # find all distributions that are version 0.01
  --package '_\d+$' # find all development releases

=item C<--author PATTERN>

Specify a string representing an author search to find distributions to smoke. The pattern is a regular expression and is
applied to the CPAN ID of CPAN authors. eg.

  --author '^BINGOS$' # find all distributions that belong to BINGOS
  --author '^BI'      # find all distributions that belong to authors beginning with BI
  --author '^B'	      # find all distributions for the 'B' authors

=item C<--phalanx>

Specify that you want to smoke the Phalanx '100' distributions, L<http://qa.perl.org/phalanx>.

=item C<--random>

Specify that you want to smoke a random selection of 100 distributions from the CPAN indexes.

=back

=head1 CONFIGURATION FILE

A number of the above options may be specified in a configuration file, C<minismokebox>, that is stored in the C<.smokebox>
directory. See L</"ENVIRONMENT"> for where the C<.smokebox> directory is located and how to effect its location.

Command line options will override options from the configuration file.

The configuration file is parsed using L<Config::Tiny>.

A subset of the command line options can be specified in the configuration file:

=over

=item C<debug>

Set to a true value to turn on all output from the L<POE::Component::SmokeBox::Backend> as distributions are smoked.

  debug=1

=item C<indices>

Set to a true value to indicate that C<minismokebox> should reindex the particular backend before proceeding
with the smoke testing.

  indices=1

=item C<recent>

Set to a true value to explicitly tell C<minismokebox> to smoke recent uploads to CPAN.

  recent=1

=item C<random>

Set to a true value to specify that you want to smoke a random selection of 100 distributions from the CPAN indexes.

  random=1

=item C<rss>

Enabling this option will tell C<minismokebox> to use the C<modules/01modules.mtime.rss> file instead of the default
C<RECENT> file to discover recent CPAN uploads.

  rss=1

=item C<noepoch>

Enabling this option will disable the use of C<RECENT-1x.yaml> files to determine the very most recent uploads
to smoke.

  noepoch=1

=item C<perlenv>

Normally C<minismokebox> ( via L<POE::Component::SmokeBox::Backend> ) will C<sanctify> the smoker process'
environment variables to remove various C<perl> related variables. Enabling this option will pass C<PERL5LIB>
environment variable to the smoker process if it is defined. This could have weird side-effects, use with caution.

  perlenv=1

=item C<perl>

Specify the path to the C<perl> executable to use for smoke testing.

  perl=/home/cpan/rel/perl-5.10.0/bin/perl

=item C<backend>

Specify the L<POE::Component::SmokeBox::Backend> to use for smoke testing

  backend=CPAN::Reporter

=item C<url>

The URI of a CPAN Mirror that C<minismokebox> will use to obtain the recent uploads from or perform C<package>,
C<author> and C<phalanx> searches against. For consistency this should really match the CPAN Mirror configured in
the applicable backend you are using.

  url=http://www.cpan.org/

=item C<home>

The path to a directory that will become the C<HOME> environment variable in spawned smoke processes. It will be
created if it does not exist.

=item C<ENVIRONMENT>

This is C<section> within the configuration file. Any key/values specified will be passed as environment
variables to the process that is created by L<POE::Component::SmokeBox::Backend>.

  [ENVIRONMENT]
  PERL5LIB=/some/random/directory/path:/oh/and/another

=back

=head1 ENVIRONMENT

C<minismokebox> uses the C<.smokebox> directory to locate the configuration file, C<minismokebox>.

This is usually located in the current user's home directory. Setting the environment variable C<PERL5_SMOKEBOX_DIR> will
effect where the C<.smokebox> directory is located.

L<POE::Component::SmokeBox::Backend> will C<santify> the environment of the smoker process of various variables
using L<Env::Sanctify>:

      '^POE_',
      '^PERL5_SMOKEBOX',
      '^HARNESS_',
      '^(PERL5LIB|TAP_VERSION|TEST_VERBOSE)$',
      '^AUTHOR_TESTING$',
      '^PERL_TEST',

See L</"CONFIGURATION FILE"> for a way of propogating environment variables to the smoker process.

This behaviour can also be overriden for the C<PERL5LIB> variable only by using the C<--perlenv> or C<perlenv>
configuration file option. See above for details.

=head1 KUDOS

Thanks go to Ricardo SIGNES for L<CPAN::Mini> which inspired the design of this script/module.

=head1 SEE ALSO

L<http://www.cpantesters.org/> - CPAN Testers: Index

L<http://wiki.cpantesters.org/>	- CPAN Testers Wiki

L<http://stats.cpantesters.org/> - CPAN Testers Statistics

L<http://lists.cpan.org/showlist.cgi?name=cpan-testers-discuss> - CPAN Testers Discussion Mailing List

L<CPAN::Testers>

L<CPANPLUS::YACSmoke>

L<CPAN::Reporter>

L<CPAN::Reporter::Smoker>

L<CPAN::YACSmoke>

L<POE::Component::SmokeBox>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
