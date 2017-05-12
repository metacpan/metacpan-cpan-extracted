use strict;
use warnings;
use Test::More tests => 1;
use URI::http::Dump;
use URI::http;
use YAML;

use feature ':5.10';

my $yaml = '---
___CANONICAL_SRC___: http://www.chryslerbrandcertified.com:82/dispatch.do?_1=&_2=&_3=&_4=&_scrollPos=&endPosition=&make=All&model=All&navigateResults=2&sortCriteria=default&st=1%7C351C26BEFD30011A156021D056C90100%7CDodge%24PreOwnedSearchResultsList%2460368%7Ctrue%7C%23%23%23%23%23false%230.0%230.0%7C%7C%7C%7C25%7CAll%7CAll%7Cfalse%7Cdefault%7Ctrue%7C%7C%7C%7C%7C%7C%7C%7C%7C&startPosition=&yearRange
___HOST___: www.chryslerbrandcertified.com
___PATH___: /dispatch.do
___PORT___: 82
___SCHEME___: http
___QUERY___:
  - _1: \'\'
  - _2: \'\'
  - _3: \'\'
  - _4: \'\'
  - _scrollPos: \'\'
  - endPosition: \'\'
  - make: All
  - model: All
  - navigateResults: 2
  - sortCriteria: default
  - st: \'1|351C26BEFD30011A156021D056C90100|Dodge$PreOwnedSearchResultsList$60368|true|#####false#0.0#0.0||||25|All|All|false|default|true|||||||||\'
  - startPosition: \'\'
  - yearRange: \'\'
';

my $hash = YAML::Load( $yaml );

my $uri1 = URI::http::Dump->new( $hash );

my $uri2 = URI::http::Dump->new('http://www.chryslerbrandcertified.com:82/dispatch.do?_1=&_2=&_3=&_4=&_scrollPos=&endPosition=&make=All&model=All&navigateResults=2&sortCriteria=default&st=1%7C351C26BEFD30011A156021D056C90100%7CDodge%24PreOwnedSearchResultsList%2460368%7Ctrue%7C%23%23%23%23%23false%230.0%230.0%7C%7C%7C%7C25%7CAll%7CAll%7Cfalse%7Cdefault%7Ctrue%7C%7C%7C%7C%7C%7C%7C%7C%7C&startPosition=&yearRange=');

ok ( $uri1->eq( $uri2 ), 'YAML Load');
