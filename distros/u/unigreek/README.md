##synopsis
  This module converts between an ascii-representation of polytonic Greek
  (i.e. old Greek) and the utf8-representation.

  The ascii-representation is taken from typegreek.com (http://www.typegreek.com), a web-based
  application, made by Randy Hoyt, that converts Roman lettercombination to Greek in utf8-format.
#example
Convert from the ascii-representation to utf8. Make sure the binary of the standard output is set to 'utf8'.
```
use utf8;
use UniGreek qw(from_unigreek);

binmode STDOUT,":utf8";
my $unigreek = "Mh=nin a)/eide qea/";
print UniGreek::from_unigreek($unigreek)."\n";
```
Convert from the utf8-representation to unigreek
```
use utf8;
use UniGreek qw(to_unigreek);

my $utf8 = "Μῆνιν ἄειδε θεά";
print UniGreek::to_unigreek($utf8)."\n";
``` 
##preinstallation
  make sure you have Module::Build installed
##installation
  perl Build.PL && ./Build test && ./Build installdeps && ./Build install
