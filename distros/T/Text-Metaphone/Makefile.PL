#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;
my $mm_ver = ExtUtils::MakeMaker->VERSION;

eval {
    require Text::Metaphone;
};

unless ($@) { # Make sure we did find the module.
    print <<CHANGE_WARN if $Text::Metaphone::VERSION < 1.00;

NOTE:  There have been API changes between this version and any
older than version 1.00!  Also, the metaphone algorithm has been
modified.  Please read the Changes file if you are upgrading from
a version of Text::Metaphone older than 1.00.

CHANGE_WARN


    print <<FIX_WARN if($Text::Metaphone::VERSION >= 1.00 && $Text::Metaphone::VERSION <= 1.94);

NOTE: Bugs fixed in this version alter the way Text::Metaphone encodes
certain words.  If you have stored metaphone encodings using your
older version of T::M, please re-encode them with this new version.
Please read the Changes file for details.

FIX_WARN
}

use Config;
my $obj_ext = $Config{obj_ext};

WriteMakefile(
    NAME          => 'Text::Metaphone',
    VERSION_FROM  => 'Metaphone.pm',
    ABSTRACT_FROM => 'Metaphone.pm',
    AUTHOR        => 'Michael G Schwern <schwern@pobox.com>',
    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    PREREQ_PM     => {
        'Test::More'  => 0.47
    },

    C             => ['metaphone_c.c'],
    OBJECT        => "metaphone_c$obj_ext Metaphone$obj_ext",

    ($mm_ver <= 6.44 ? () : (META_MERGE => {
        requires  => {
            perl        =>      '5.6.0',
        },
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'https://metacpan.org/release/Text-Metaphone',
            bugtracker  =>      'https://github.com/schwern/Text-Metaphone/issues',
            repository  =>      'https://github.com/schwern/Text-Metaphone/',
        },
    }))
);

sub MY::postamble {
"
metaphone_c$obj_ext : metachar.h metaphone.h metaphone_c.c

"
}
