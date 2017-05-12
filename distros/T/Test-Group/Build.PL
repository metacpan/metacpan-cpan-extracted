# Build.PL, (C) IDEALX 2005 (See README for license details)

# This script automatically builds a "Build" file in the current
# directory (using an in-house subclass to Module::Build), which in
# turn builds the Test-Group package.
#
# If you don't have Module::Build installed, use the following instead:
#     perl Makefile.PL
#     make
#     make test
#     make install

use 5.004;

use strict;
use warnings;
use Module::Build;


my $builder = Module::Build->new
    ( module_name         => 'Test::Group',
      license             => 'perl',
      dist_author         => [ 'Nick Cleaton <ncleaton@cpan.org>',
                               'Dominique Quatravaux <domq@cpan.org>' ],
      dist_version_from   => 'lib/Test/Group.pm',
      requires            =>
      {
       'Exporter'     => 0,
       'Test::Simple' => 0.59,  # Test::Builder->create() needed
       'Test::Builder' => 0,
       'Test::Cmd' => 0,
       'File::Spec' => 0,
       'IO::File' => 0,
       'Carp' => 0,
      },
      build_requires     =>
      {
       'Test::More' => 0,
       'File::Slurp' => 0,
       'File::Temp' => 0,
       'File::Spec::Functions' => 0,
      },
    add_to_cleanup      => [ 'Test-Group-*' ],
## The Makefile.PL is now managed by hand:
#    create_makefile_pl  => 'traditional',
);

# Fixes an @INC ordering problem dug up by CPAN testers, that causes
# Module::Build's version detection algorithm to fail; see
# http://www.nntp.perl.org/group/perl.cpan.testers/2007/02/msg422771.html
if ( (! ($builder->prereq_failures &&
         $builder->prereq_failures->{requires}->{"Test::Simple"})) &&
     (`$^X -MTest::Builder -e "print 'ok' if Test::Builder->can('create');"`
      !~ m/ok/) ) {
    die <<"MESSAGE";

ERROR IN PREREQUISITES
There appears to be several versions of Test::Builder installed on your
system, and I am not picking up the most recent one; Test::Group will not
work in this situation.

Please uninstall the oldest version of Test::Builder on your system,
or otherwise rearrange the modules so that a recent version of
Test::Builder comes first in \@INC (@INC)

MESSAGE
}

$builder->create_build_script();

1;
