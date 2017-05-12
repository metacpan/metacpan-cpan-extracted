BEGIN {
  if ($] < 5.006_001) {
    warn "\nSorry, at least Perl 5.6.1 is required for this module!\n\n";
    exit;
  }
}

use ExtUtils::MakeMaker;
use Config;

$|=0;

my %meta = (
    NAME => 'XML::CompactTree',
    ABSTRACT  => 'Fast parser of XML document into nested arrays',
    AUTHOR => 'Petr Pajas <pajas@matfyz.cz>',
    VERSION_FROM   => 'CompactTree.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::LibXML' => 1.68,
    },
);

WriteMakefile( %meta );

