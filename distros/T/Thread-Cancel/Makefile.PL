# Module makefile for Thread::Cancel (using ExtUtils::MakeMaker)

require 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;

# Construct make file
WriteMakefile(
    'NAME'          => 'Thread::Cancel',
    'AUTHOR'        => 'Jerry D. Hedden <jdhedden AT cpan DOT org>',
    'VERSION_FROM'  => 'lib/Thread/Cancel.pm',
    'ABSTRACT_FROM' => 'lib/Thread/Cancel.pm',
    'PREREQ_PM'     => {
        'threads'         => 1.39,
        'threads::shared' => 0,
        'Test::More'      => 0.50,
    },

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);

# Additional 'make' targets
sub MY::postamble
{
    return <<'_EXTRAS_';
fixfiles:
	@dos2unix `cat MANIFEST`
	@$(CHMOD) 644 `cat MANIFEST`
	@$(CHMOD) 755 examples/*.pl
_EXTRAS_
}

# EOF
