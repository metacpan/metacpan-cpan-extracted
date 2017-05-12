#!perl
#
# Greek UTF-8 examples
# 

use strict;
use warnings;
use utf8;

use lib 't/lib';
use Text::Levenshtein::TestUtils qw/ run_data_tests /;

run_data_tests();

__DATA__
ἀγαθός
ἀγάπη
4
--
ἀγορά
ἀγκών
3
--
ἄγχω
ἄγω
1
--
ἀθήρα
ἀθλητής
5
--
αἴγαγρος
αἴγαγρος
0
--
ἄλληλον
ἄλλος
3
--
βάθος
βαθύς
2
--
δέκα
δέλτα
2
--
ἕτερος
ἔτυμος
3
--
κακός
καλός
1
--
