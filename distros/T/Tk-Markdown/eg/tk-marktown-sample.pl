#!perl

use strict;
use warnings;
use utf8;
use v5.16;
use FindBin qw/$Bin/;
use lib $Bin . '/../lib';
use Tk;
use Tk::Markdown;

my $mw = Tk::MainWindow->new(-title => 'Tk::Markdown sample');

my $mdt = $mw->Markdown->pack(-fill => 'both', -expand => 1);

my $markdown = q~# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

* list 1
** list 2
*** list 3
**** list 4
***** list 5
****** list 6

    Source shown in monofont
    another line of source code here
~;

$mdt->insert('0.0', $markdown);

$mw->MainLoop;

exit(0);
