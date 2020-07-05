#!perl

use strict;
use warnings;

use Win32::Mechanize::NotepadPlusPlus ':all';

my $keep = notepad->getLangType();

for my $t ( sort ( keys ( %LANGTYPE ) ) ) {
    my $n = notepad->getLanguageName($LANGTYPE{$t});
    my $d = notepad->getLanguageDesc($LANGTYPE{$t});
    printf "%-35s %-35s %-35s\n", $t, $n, $d;

    notepad->setLangType($LANGTYPE{$t});
    for my $s ( split "\n", editor->propertyNames() ) {
        my $v = editor->getProperty($s);
        printf "\t'%-32s' :%i: %-32s %s\n" , $s, editor->propertyType($s), '"' . $v . '"', editor->describeProperty($s);
    }
    print "\n";
}

notepad->setLangType($keep);
