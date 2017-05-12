use strict;

package main;

use Test;
use Data::Dumper;

use Text::Query;

plan test => 2;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;

#
# Can you believe this ? Data::Dumper 2.101 in perl 5.6 is not the same
# as Data::Dumper 2.101 on CPAN. Christ.
#
my($v56) = ($] >= 5.006) ? 1 : 0;

{
    my($question);
    my($query) = Text::Query->new('blurk',
				  -build => 'Text::Query::BuildSQLMifluz',
				  -fields_searched => 'field1',
				  );
    my($expect) = $v56 ? "['literal','field1','10']" : "['literal','field1',10]";
    $question = "10";
    $query->prepare($question);
    ok(Dumper($query->{'matchexp'}), $expect, "prepare $question");

    $expect = $v56 ? "['or','field1',['mandatory','field1',['literal','field1','10']],['forbiden','field1',['literal','field1','20']],['literal','field1','30']]" : "['or','field1',['mandatory','field1',['literal','field1',10]],['forbiden','field1',['literal','field1',20]],['literal','field1',30]]";
    $question = "+10 -20 30";
    $query->prepare($question);
    ok(Dumper($query->{'matchexp'}), $expect, "prepare $question");
    
}

# Local Variables: ***
# mode: perl ***
# End: ***
