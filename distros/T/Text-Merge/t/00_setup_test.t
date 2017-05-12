
require "t/test.pl";

print "1..12\n";

unlink 't/mline.txt' if -e 't/mline.txt';
$text = join("\n", 
		q|REF:Test1|,
		q|[[REF:Test1]]|,
		q|{This }REF:Test1{.}|,
		q|[[{This }REF:Test1{.}]]|,
		q|Some text before REF:Test1|,
		q|I love fire[[REF:Test1]]|,
		q|Some text before {this }REF:Test1{.}|,
		q|Some text before [[{this }REF:Test1{.}]]|,
		q|REF:Test1 Some text after is here.|,
		q|[[REF:Test1]]ites galore|,
		q|{This }REF:Test1{.}  Some text after.|,
		q|[[{This }REF:Test1{.}]]..some text after.|,
		q|Some text before REF:Test1.  Some text after.|,
		q|I love fire[[REF:Test1]]!!!|,
		q|Some text before {this }REF:Test1{.}  Some text after.|,
		q|Some text before [[{this }REF:Test1{.}]]..some text after.|,
		q|ACT:Mothers|,
		q|[[ACT:Mothers]]|,
		q|Some text before {this }ACT:Mothers{.}  Some text after.|,
		q|Some text before [[{this }ACT:Mothers{.}]]..some text after.|
		
	);
create_file('t/mline.txt', $text) && (print "ok\n") || (print "not ok\n");

unlink 't/mlineout.txt' if -e 't/mlineout.txt';
$text = join ("\n", 
		q|works|,
		q|works|,
		q|This works.|,
		q|This works.|,
		q|Some text before works|,
		q|I love fireworks|,
		q|Some text before this works.|,
		q|Some text before this works.|,
		q|works Some text after is here.|,
		q|worksites galore|,
		q|This works.  Some text after.|,
		q|This works...some text after.|,
		q|Some text before works.  Some text after.|,
		q|I love fireworks!!!|,
		q|Some text before this works.  Some text after.|,
		q|Some text before this works...some text after.|,
		q|apple pie|,
		q|apple pie|,
		q|Some text before this apple pie.  Some text after.|,
		q|Some text before this apple pie...some text after.|
	);
create_file('t/mlineout.txt', $text) && (print "ok\n") || (print "not ok\n");


unlink 't/input.txt' if -e 't/input.txt';
create_file('t/input.txt',
q|REF:Test1
[[REF:Test1]]
{This }REF:Test1{.}
[[{This }REF:Test1{.}]]
Some text before REF:Test1
I love fire[[REF:Test1]]
Some text before {this }REF:Test1{.}
Some text before [[{this }REF:Test1{.}]]
REF:Test1 Some text after is here.
[[REF:Test1]]ites galore
{This }REF:Test1{.}  Some text after.
[[{This }REF:Test1{.}]]..some text after.
Some text before REF:Test1.  Some text after.
I love fire[[REF:Test1]]!!!
Some text before {this }REF:Test1{.}  Some text after.
Some text before [[{this }REF:Test1{.}]]..some text after.
ACT:Mothers
[[ACT:Mothers]]
{This }ACT:Mothers{.}
[[{This }ACT:Mothers{.}]]
Some text before ACT:Mothers
I love fire[[ACT:Mothers]]
Some text before {this }ACT:Mothers{.}
Some text before [[{this }ACT:Mothers{.}]]
ACT:Mothers Some text after is here.
[[ACT:Mothers]]ites galore
{This }ACT:Mothers{.}  Some text after.
[[{This }ACT:Mothers{.}]]..some text after.
Some text before ACT:Mothers.  Some text after.
I love fire[[ACT:Mothers]]!!!
Some text before {this }ACT:Mothers{.}  Some text after.
Some text before [[{this }ACT:Mothers{.}]]..some text after.
IF:Test1{this works}
IF:Null{this doesn't work}
[[IF:Test1{this works}]]
[[IF:Null{this doesn't work}]]
text before IF:Test1{this works}
text before IF:Null{this doesn't work}
text before...[[IF:Test1{this works}]]
text before...[[IF:Null{this doesn't work}]]
IF:Test1{this works} text after
IF:Null{this doesn't work}text after
[[IF:Test1{this works}]] text after
[[IF:Null{this doesn't work}]]...text after
text before IF:Test1{this works} text after
text before IF:Null{this doesn't work}text after
text before...[[IF:Test1{this works}]]...text after
text before...[[IF:Null{this doesn't work}]]text after
NEG:Null{this works}
NEG:Test1{this doesn't work}
[[NEG:Null{this works}]]
[[NEG:Test1{this doesn't work}]]
text before NEG:Null{this works}
text before NEG:Test1{this doesn't work}
text before...[[NEG:Null{this works}]]
text before...[[NEG:Test1{this doesn't work}]]
NEG:Null{this works} text after
NEG:Test1{this doesn't work}text after
[[NEG:Null{this works}]] text after
[[NEG:Test1{this doesn't work}]]...text after
text before NEG:Null{this works} text after
text before NEG:Test1{this doesn't work}text after
text before...[[NEG:Null{this works}]]...text after
text before...[[NEG:Test1{this doesn't work}]]text after
REF:TestCase:upper
REF:TestCase:lower
REF:TestName:lower:proper
REF:TestFloat:int
REF:TestFloat:percent
REF:TestFloat:int:percent
$REF:TestFloat:dollars
REF:TestDate:abbr
REF:TestDate:short
REF:TestDate:time
REF:TestDate:24h
REF:TestDate:dateonly
REF:TestDate:date
REF:TestDate:ext
REF:TestDate:unix
REF:TestEscape:escape
REF:TestEscape:escape:unescape
REF:TestName:lower:proper:indent5
REF:TestParagraph:paragraph30
REF:TestParagraph:paragraph35:indent5
|) && (print "ok\n") || (print "not ok\n");


unlink 't/delimin.txt' if -e 't/delimin.txt';
create_file('t/delimin.txt',
q|REF:Test1
<[REF:Test1]>
{This }REF:Test1{.}
<[{This }REF:Test1{.}]>
Some text before REF:Test1
I love fire<[REF:Test1]>
Some text before {this }REF:Test1{.}
Some text before <[{this }REF:Test1{.}]>
REF:Test1 Some text after is here.
<[REF:Test1]>ites galore
{This }REF:Test1{.}  Some text after.
<[{This }REF:Test1{.}]>..some text after.
Some text before REF:Test1.  Some text after.
I love fire<[REF:Test1]>!!!
Some text before {this }REF:Test1{.}  Some text after.
Some text before <[{this }REF:Test1{.}]>..some text after.
ACT:Mothers
<[ACT:Mothers]>
{This }ACT:Mothers{.}
<[{This }ACT:Mothers{.}]>
Some text before ACT:Mothers
I love fire<[ACT:Mothers]>
Some text before {this }ACT:Mothers{.}
Some text before <[{this }ACT:Mothers{.}]>
ACT:Mothers Some text after is here.
<[ACT:Mothers]>ites galore
{This }ACT:Mothers{.}  Some text after.
<[{This }ACT:Mothers{.}]>..some text after.
Some text before ACT:Mothers.  Some text after.
I love fire<[ACT:Mothers]>!!!
Some text before {this }ACT:Mothers{.}  Some text after.
Some text before <[{this }ACT:Mothers{.}]>..some text after.
IF:Test1{this works}
IF:Null{this doesn't work}
<[IF:Test1{this works}]>
<[IF:Null{this doesn't work}]>
text before IF:Test1{this works}
text before IF:Null{this doesn't work}
text before...<[IF:Test1{this works}]>
text before...<[IF:Null{this doesn't work}]>
IF:Test1{this works} text after
IF:Null{this doesn't work}text after
<[IF:Test1{this works}]> text after
<[IF:Null{this doesn't work}]>...text after
text before IF:Test1{this works} text after
text before IF:Null{this doesn't work}text after
text before...<[IF:Test1{this works}]>...text after
text before...<[IF:Null{this doesn't work}]>text after
NEG:Null{this works}
NEG:Test1{this doesn't work}
<[NEG:Null{this works}]>
<[NEG:Test1{this doesn't work}]>
text before NEG:Null{this works}
text before NEG:Test1{this doesn't work}
text before...<[NEG:Null{this works}]>
text before...<[NEG:Test1{this doesn't work}]>
NEG:Null{this works} text after
NEG:Test1{this doesn't work}text after
<[NEG:Null{this works}]> text after
<[NEG:Test1{this doesn't work}]>...text after
text before NEG:Null{this works} text after
text before NEG:Test1{this doesn't work}text after
text before...<[NEG:Null{this works}]>...text after
text before...<[NEG:Test1{this doesn't work}]>text after
REF:TestCase:upper
REF:TestCase:lower
REF:TestName:lower:proper
REF:TestFloat:int
REF:TestFloat:percent
REF:TestFloat:int:percent
$REF:TestFloat:dollars
REF:TestDate:abbr
REF:TestDate:short
REF:TestDate:time
REF:TestDate:24h
REF:TestDate:dateonly
REF:TestDate:date
REF:TestDate:ext
REF:TestDate:unix
REF:TestEscape:escape
REF:TestEscape:escape:unescape
REF:TestName:lower:proper:indent5
REF:TestParagraph:paragraph30
REF:TestParagraph:paragraph35:indent5
|) && (print "ok\n") || (print "not ok\n");

unlink 't/listin.txt' if -e 't/listin.txt';
create_file('t/listin.txt',
q|
Test of complete list: 

REF:FruitList:list_teststyle


Test of empty list:

REF:EmptyList:list_teststyle


Test of null list:

REF:Null:list_teststyle
|) && (print "ok\n") || (print "not ok\n");


unlink 't/listres.txt' if -e 't/listres.txt';
create_file('t/listres.txt',
q|
Test of complete list: 

======================
    FRUIT BASKET
======================

The apple is a round, red fruit that is medium in size.

---------------------- 

The pear is a oblong, green fruit that is medium in size.

---------------------- 

The grape is a round, purple fruit that is small in size.

---------------------- 

The pumpkin is a round, orange fruit that is large in size.

======================



Test of empty list:

This list is empty.



Test of null list:


|) && (print "ok\n") || (print "not ok\n");


unlink 't/tablein.txt' if -e 't/tablein.txt';
create_file('t/tablein.txt', 
q|
Test of complete table: 

REF:FruitList:table2_testtable


Test of empty table:

REF:EmptyList:table2_testtable


Test of null table:

REF:Null:table2_testtable
|) && (print "ok\n") || (print "not ok\n");


unlink 't/tableres.txt' if -e 't/tableres.txt';
create_file('t/tableres.txt',
q|
Test of complete table: 

<TABLE BORDER=1>
<TR><TD COLSPAN="2" ALIGN=CENTER><B>Header</B></TD></TR>


<TR><TD><FONT FACE="Arial,Helvetica" SIZE="-2">The apple is a 
						round, red fruit that is medium in size.</FONT></TD>

<TD><FONT FACE="Arial,Helvetica" SIZE="-2">The pear is a 
						oblong, green fruit that is medium in size.</FONT></TD>

</TR>
<TR><TD><FONT FACE="Arial,Helvetica" SIZE="-2">The grape is a 
						round, purple fruit that is small in size.</FONT></TD>

<TD><FONT FACE="Arial,Helvetica" SIZE="-2">The pumpkin is a 
						round, orange fruit that is large in size.</FONT></TD>

</TR>

</TABLE>




Test of empty table:


<TABLE><TR><TD>This is an empty table.</TD></TR></TABLE>




Test of null table:


|) && (print "ok\n") || (print "not ok\n");


unlink 't/tablein2.txt' if -e 't/tablein2.txt';
create_file('t/tablein2.txt',
q|
Test of complete table: 

REF:FruitList:table3_testtable


Test of empty table:

REF:EmptyList:table3_testtable


Test of null table:

REF:Null:table3_testtable
|) && (print "ok\n") || (print "not ok\n");


unlink 't/tablres2.txt' if -e 't/tablres2.txt';
create_file('t/tablres2.txt',
q|
Test of complete table: 

<TABLE BORDER=1>
<TR><TD COLSPAN="3" ALIGN=CENTER><B>Header</B></TD></TR>


<TR><TD><FONT FACE="Arial,Helvetica" SIZE="-2">The apple is a 
						round, red fruit that is medium in size.</FONT></TD>

<TD><FONT FACE="Arial,Helvetica" SIZE="-2">The pear is a 
						oblong, green fruit that is medium in size.</FONT></TD>

<TD><FONT FACE="Arial,Helvetica" SIZE="-2">The grape is a 
						round, purple fruit that is small in size.</FONT></TD>

</TR>
<TR><TD><FONT FACE="Arial,Helvetica" SIZE="-2">The pumpkin is a 
						round, orange fruit that is large in size.</FONT></TD>

<TD COLSPAN="2">&nbps;<I>filler</I>&nbsp;</TD>
</TR>

</TABLE>




Test of empty table:


<TABLE><TR><TD>This is an empty table.</TD></TR></TABLE>




Test of null table:


|) && (print "ok\n") || (print "not ok\n");


unlink 't/recurse.txt' if -e 't/recurse.txt';
create_file('t/recurse.txt',
q|
This is the recursion test:
REF:ItemList:list_recurse1|) && (print "ok\n") || (print "not ok\n");


unlink 't/recres2.txt' if -e 't/recres2.txt';
create_file('t/recres2.txt',
q|
This is the recursion test:
---recusion test header file---


Recursive Test:
	ID: 2
	---recursion 2 test header file---


Recursive Test:
	---recusion test header file---


Recursive Test:
	ID: 2
	---recursion 2 test header file---


Recursive Test:
	---recusion test header file---


Recursive Test:
	ID: 2
	---recursion 2 test header file---


Recursive Test:
	

---recursion 2 test footer file---


---------------------- 


Recursive Test:
	ID: 3
	This list is empty.


---recursion test footer file---


---recursion 2 test footer file---


---------------------- 


Recursive Test:
	ID: 3
	This list is empty.


---recursion test footer file---


---recursion 2 test footer file---


---------------------- 


Recursive Test:
	ID: 3
	This list is empty.


---recursion test footer file---
|) && (print "ok\n") || (print "not ok\n");

exit;

