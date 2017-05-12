# $Id: Makefile.PL,v 1.1 2005/07/27 15:06:14 pmh Exp $

use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::SerialFork',
    VERSION_FROM      => 'lib/Test/SerialFork.pm', # finds $VERSION
    PREREQ_PM         => {
      'Test::Builder' => 0,
    },
    ABSTRACT_FROM     => 'lib/Test/SerialFork.pm',
    AUTHOR            => 'Peter Haworth <pmh@cpan.org>',
);
