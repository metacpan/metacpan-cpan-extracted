##==============================================================================
## 1.t - basic testing for Text::Conjunct
##==============================================================================
## $Id: Text-Conjunct.t,v 1.0 2004/05/23 05:44:28 kevin Exp $
##==============================================================================
use Test;
BEGIN { plan tests => 6 };
use Text::Conjunct;
ok(1);

ok(conjunct("and", "a") eq 'a');
ok(conjunct('and', 'a', 'b') eq 'a and b');
ok(conjunct('and', 'a', 'b', 'c') eq 'a, b, and c');
ok(conjunct('and', 'a', 'b', 'c', 'd') eq 'a, b, c, and d');

$Text::Conjunct::SERIAL_COMMA = 0;
ok(conjunct('and', 'a', 'b', 'c', 'd') eq 'a, b, c and d');
