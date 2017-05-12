# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 16 };

use Text::Templet;

ok(1);

use vars qw( $tv $c );

$tv = "Test Variable";

sub sub1() {return 'Sub 1 Returns';}
sub switch1() {return 'C2';}

ok(Templet('Hello, World!'),'Hello, World!');
ok(Templet('$tv'),$tv);
ok(Templet('Begin $tv End'),"Begin $tv End");
ok(Templet('<% &$_outf($tv); "" %>'),$tv);
ok(Templet('Begin <% &$_outf($tv); "" %> End'),"Begin $tv End");
ok(Templet('<% "SKIP" %>This test has failed<%SKIP%>'),'');
ok(Templet('Begin <% "SKIP" %>This test has failed<%SKIP%> End'),'Begin  End');
ok(Templet('<% $c = 0; %><%I1%>$c <% "I1" if ++$c < 10 %>'),'0 1 2 3 4 5 6 7 8 9 ');
ok(Templet('Begin <% $c = 0; %><%I1%>$c <% "I1" if ++$c < 10 %> End'),'Begin 0 1 2 3 4 5 6 7 8 9  End');
ok(Templet('<% &$_outf(sub1()); "" %>'),'Sub 1 Returns');
ok(Templet('Begin <% &$_outf(&sub1()); "" %> End'),'Begin Sub 1 Returns End');
ok(Templet('<% &switch1() %><%C1%>Choice 1<%"END_SWITCH1"%><%C2%>Choice2<%END_SWITCH1%>'),'Choice2');
ok(Templet('Begin <% &switch1() %><%C1%>Choice 1<%"END_SWITCH1"%><%C2%>Choice2<%END_SWITCH1%> End'),'Begin Choice2 End');
ok(Templet('Begin <%*SKIP%> This is skipped <%SKIP%> End'),'Begin  End');
ok(Templet('Begin <% "*SECTION2" %>This is skipped<%*SECTION2%>This is included<%SECTION2%> End'),'Begin This is included End');
