NAME
    Text::Unicode::Equivalents - synthesize canonically equivalent strings

SYNOPSIS
    use Text::Unicode::Equivalents qw( all_strings);
 
    $aref = all_strings ($string);
    map {print "$_\n"} @{$aref};

DESCRIPTION
    all_string($s)
        Given an arbitrary string, "all_strings()" returns a reference to an
        unsorted array of all unique strings that are canonically equivalent
        to the argument.

BUGS
    Uses Unicode::Normalize. On some systems (e.g. ActiveState 5.6.1)
    Unicode::Normalize is aware only of Unicode 3.0 and thus de/compositions
    introduced since Unicode 3.0 will not be used.

AUTHOR
    Bob Hallissy  <BHALLISSY@cpan.org>

COPYRIGHT
    Copyright(C) 2003-2011, SIL International. 

    This package is published under the terms of the Perl Artistic License.

