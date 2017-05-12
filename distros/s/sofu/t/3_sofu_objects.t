use utf8;
use Test::More tests => 219;
use Encode;
BEGIN {
	use_ok('Data::Sofu');
}
use Data::Sofu qw/loadSofu readSofu getSofu unpackSofu/; #We will need all of that.

#unless (-e "test.sofu") {
#generating input file:
{
	open FH,">:raw:encoding(UTF-16)","test.sofu";
	print FH q(#Text:  Text file
Ruler = (
	"1"
	"2" #This is the second Value
	"3"
	@Sub<20>Entry->Foo
	{
		SubSub= {
			Blubber = ("1" "2" (4 @-> 5 @->Sub<20>Entry->Foo) "3")
			Test = @->Ruler->4 #new Comment here
		}
	}
	(
		@->Sub<20>Entry->Foo
	)
)
Sub<20>Entry = { #A map
	Foo = "MeÄep!"
}# End of Map
Text = "Hello World"
List = (
""
0
UNDEF
3
)
Testing = (
	"  Text with leading whitepace, and with 2 trailing spaces  "
	"\n2.Line\\n3.Line\n"
	"\r"
	"Space \n Newline \n Space"
	"4Spaces    end"
)
);
	close FH;
}

#Prepearations done!
#
#print $dumptext,"\n";
my $tree=readSofu("test.sofu");
my $objects;
eval {
$objects = getSofu("test.sofu");
$objects->write("test2.sofu");
};
ok(not($@),"getSofu, writeSofu");
die($@) if $@;
ok($objects->isMap(),"Root is a Map");
ok($objects->hasComment(),"Root has a comment");
ok($objects->getComment()->[0] eq "Text:  Text file","Root has the right comment");
#Ruler
ok($objects->hasAttribute("Ruler"),"Root->Ruler");
ok($objects->object("Ruler")->isList(),"Root->Ruler is a List");
my $ruler = $objects->list("Ruler");
ok($ruler->hasElement(5),"Root->Ruler.len = 5");
ok($ruler->hasValue(0),"Root->Ruler->0 is a Value");
ok($ruler->value(0)->toString() eq 1,"Root->Ruler->0 is 1");
ok($ruler->hasValue(1),"Root->Ruler->1 is a Value");
ok($ruler->value(1)->toString() eq 2,"Root->Ruler->1 is 2");
ok($ruler->value(1)->hasComment(),"Root->Ruler->1 has a Comment");
ok($ruler->value(1)->getComment()->[0] eq "This is the second Value","Root->Ruler->1 has the right Comment");
ok($ruler->hasValue(2),"Root->Ruler->2 is a Value");
ok($ruler->value(2)->toString() eq 3,"Root->Ruler->2 is 3");
#ok($ruler->object(3)->isReference(),"Root->Ruler->3 is a Reference");
ok($ruler->hasValue(3),"Root->Ruler->3 is a Value");
ok($ruler->value(3)->toString() eq "Me\x{c4}ep!","Root->Ruler->3 is \"Me\x{c4}ep!\"");
ok($ruler->hasMap(4),"Root->Ruler->4 is a Map");
my $rmap = $ruler->map(4);
ok($rmap->hasMap("SubSub"),"Root->Ruler->4->SubSub is a Map");
my $subsub = $rmap->map("SubSub");
ok($subsub->hasList("Blubber"),"Root->Ruler->4->SubSub->Blubber is a List");
my $blubber=$subsub->list("Blubber");
ok($blubber->hasValue(0),"Root->Ruler->4->SubSub->Blubber->0 is a Value");
ok($blubber->value(0)->toString() eq 1,"Root->Ruler->4->SubSub->Blubber->0 is 1");
ok($blubber->hasValue(1),"Root->Ruler->4->SubSub->Blubber->1 is a Value");
ok($blubber->value(1)->toString() eq 2,"Root->Ruler->4->SubSub->Blubber->1 is 2");
ok($blubber->hasList(2),"Root->Ruler->4->SubSub->Blubber->2 is a List");
my $blist = $blubber->list(2);
ok($blist->hasValue(0),"Root->Ruler->4->SubSub->Blubber->2->0 is a Value");
ok($blist->value(0)->toString() eq 4,"Root->Ruler->4->SubSub->Blubber->2->0 is 4");
ok($blist->object(1)->isReference(),"Root->Ruler->4->SubSub->Blubber->2->1 is a Reference");
ok($blist->object(1)->follow() eq $objects,"Root->Ruler->4->SubSub->Blubber->2->1 is the same as \$objects");
ok($blist->hasMap(1),"Root->Ruler->4->SubSub->Blubber->2->1 is also a Map");
ok($blist->hasValue(2),"Root->Ruler->4->SubSub->Blubber->2->2 is a Value");
ok($blist->value(2)->toString() eq 5,"Root->Ruler->4->SubSub->Blubber->2->2 is 5");
ok($blist->hasValue(3),"Root->Ruler->4->SubSub->Blubber->2->3 is a Value");
#ok($blist->object(3)->isReference(),"Root->Ruler->4->SubSub->Blubber->2->3 is a Reference");
ok($blist->value(3)->toString() eq "Me\x{c4}ep!","Root->Ruler->4->SubSub->Blubber->2->3 is \"Me\x{c4}ep!\"");
ok($blubber->hasValue(3),"Root->Ruler->4->SubSub->Blubber->3 is a Value");
ok($blubber->value(3)->toString() eq 3,"Root->Ruler->4->SubSub->Blubber->3 is 3");
ok($subsub->hasMap("Test"),"Root->Ruler->4->SubSub->Test is a Map");
ok($subsub->object("Test")->hasComment(),"Root->Ruler->4->SubSub->Test has a comment");
ok($subsub->object("Test")->getComment()->[0] eq "new Comment here","Root->Ruler->4->SubSub->Test has the right comment");
ok($subsub->map("Test") eq $rmap,"Root->Ruler->4->SubSub->Test is Root->Ruler->4");
ok($ruler->hasList(5),"Root->Ruler->5 is a List");
my $rlist=$ruler->list(5);
#ok($rlist->object(0)->isReference(),"Root->Ruler->5->0 is a Reference")
ok($rlist->hasValue(0),"Root->Ruler->5->0 is a Value");
ok($rlist->value(0)->toString() eq "Me\x{c4}ep!","Root->Ruler->5->0 is \"Me\x{c4}ep!\"");

#Sub<20>Entry
ok($objects->hasMap("Sub Entry"),"Ruler->Sub<20>Entry is a Map");
ok($objects->map("Sub Entry")->hasComment(),"Ruler->Sub<20>Entry has a comment");
ok($objects->map("Sub Entry")->getComment()->[0] eq "A map","Ruler->Sub<20>Entry has the first comment right");
ok($objects->map("Sub Entry")->getComment()->[1] eq " End of Map","Ruler->Sub<20>Entry has the second comment right");
ok($objects->map("Sub Entry")->hasValue("Foo") ,"Ruler->Sub<20>Entry->Foo is a Map");
ok($objects->map("Sub Entry")->value("Foo")->toString() eq "Me\x{c4}ep!" ,"Ruler->Sub<20>Entry->Foo is \"Me\x{c4}ep!\"");

#List
ok($objects->hasList("List"),"Root->List");
ok($objects->list("List")->isList(),"Root->List is a List");
ok($objects->list("List")->hasValue(0),"Root->List->0 is a Value");
ok($objects->list("List")->hasValue(1),"Root->List->1 is a Value");
ok(!$objects->list("List")->object(2)->isDefined(),"Root->List->2 is not defined");
ok($objects->list("List")->hasValue(3),"Root->List->3 is a Value");
ok($objects->list("List")->value(0)->toString() eq "","Root->List->0 is ''");
ok($objects->list("List")->value(1)->toString() eq "0","Root->List->1 is '0'");
ok($objects->list("List")->value(3)->toString() eq 3,"Root->List->3 is 3");

#Testing

ok($objects->hasList("Testing"),"Root->Testing");
ok($objects->list("Testing")->isList(),"Root->Testing is a List");
ok($objects->list("Testing")->hasValue(0),"Root->Testing->0 is a Value");
ok($objects->list("Testing")->hasValue(1),"Root->Testing->1 is a Value");
ok($objects->list("Testing")->hasValue(2),"Root->Testing->2 is a Value");
ok($objects->list("Testing")->hasValue(3),"Root->Testing->3 is a Value");
ok($objects->list("Testing")->hasValue(4),"Root->Testing->4 is a Value");
ok($objects->list("Testing")->value(0)->toString() eq '  Text with leading whitepace, and with 2 trailing spaces  ',"Root->List->0 is right");
ok($objects->list("Testing")->value(1)->toString() eq "\n2.Line\n3.Line\n","Root->List->1 is right");
ok($objects->list("Testing")->value(2)->toString() eq "\r","Root->List->2 is right");
ok($objects->list("Testing")->value(3)->toString() eq "Space \n Newline \n Space","Root->List->3 is right");
ok($objects->list("Testing")->value(4)->toString() eq "4Spaces    end","Root->List->4 is right");


#And the whole stuff again

eval {
$objects = getSofu("test2.sofu");
};
ok(not($@),"getSofu of written sofu");
die($@) if $@;
ok($objects->isMap(),"Root is a Map");
ok($objects->hasComment(),"Root has a comment");
ok($objects->getComment()->[0] eq "Text:  Text file","Root has the right comment");
#Ruler
ok($objects->hasAttribute("Ruler"),"Root->Ruler");
ok($objects->object("Ruler")->isList(),"Root->Ruler is a List");
$ruler = $objects->list("Ruler");
ok($ruler->hasElement(5),"Root->Ruler.len = 5");
ok($ruler->hasValue(0),"Root->Ruler->0 is a Value");
ok($ruler->value(0)->toString() eq 1,"Root->Ruler->0 is 1");
ok($ruler->hasValue(1),"Root->Ruler->1 is a Value");
ok($ruler->value(1)->toString() eq 2,"Root->Ruler->1 is 2");
ok($ruler->value(1)->hasComment(),"Root->Ruler->1 has a Comment");
ok($ruler->value(1)->getComment()->[0] eq "This is the second Value","Root->Ruler->1 has the right Comment");
ok($ruler->hasValue(2),"Root->Ruler->2 is a Value");
ok($ruler->value(2)->toString() eq 3,"Root->Ruler->2 is 3");
#ok($ruler->object(3)->isReference(),"Root->Ruler->3 is a Reference");
ok($ruler->hasValue(3),"Root->Ruler->3 is a Value");
ok($ruler->value(3)->toString() eq "Me\x{c4}ep!","Root->Ruler->3 is \"Me\x{c4}ep!\"");
ok($ruler->hasMap(4),"Root->Ruler->4 is a Map");
$rmap = $ruler->map(4);
ok($rmap->hasMap("SubSub"),"Root->Ruler->4->SubSub is a Map");
$subsub = $rmap->map("SubSub");
ok($subsub->hasList("Blubber"),"Root->Ruler->4->SubSub->Blubber is a List");
$blubber=$subsub->list("Blubber");
ok($blubber->hasValue(0),"Root->Ruler->4->SubSub->Blubber->0 is a Value");
ok($blubber->value(0)->toString() eq 1,"Root->Ruler->4->SubSub->Blubber->0 is 1");
ok($blubber->hasValue(1),"Root->Ruler->4->SubSub->Blubber->1 is a Value");
ok($blubber->value(1)->toString() eq 2,"Root->Ruler->4->SubSub->Blubber->1 is 2");
ok($blubber->hasList(2),"Root->Ruler->4->SubSub->Blubber->2 is a List");
$blist = $blubber->list(2);
ok($blist->hasValue(0),"Root->Ruler->4->SubSub->Blubber->2->0 is a Value");
ok($blist->value(0)->toString() eq 4,"Root->Ruler->4->SubSub->Blubber->2->0 is 4");
ok($blist->object(1)->isReference(),"Root->Ruler->4->SubSub->Blubber->2->1 is a Reference");
ok($blist->object(1)->follow() eq $objects,"Root->Ruler->4->SubSub->Blubber->2->1 is the same as \$objects");
ok($blist->hasMap(1),"Root->Ruler->4->SubSub->Blubber->2->1 is also a Map");
ok($blist->hasValue(2),"Root->Ruler->4->SubSub->Blubber->2->2 is a Value");
ok($blist->value(2)->toString() eq 5,"Root->Ruler->4->SubSub->Blubber->2->2 is 5");
ok($blist->hasValue(3),"Root->Ruler->4->SubSub->Blubber->2->3 is a Value");
#ok($blist->object(3)->isReference(),"Root->Ruler->4->SubSub->Blubber->2->3 is a Reference");
ok($blist->value(3)->toString() eq "Me\x{c4}ep!","Root->Ruler->4->SubSub->Blubber->2->3 is \"Me\x{c4}ep!\"");
ok($blubber->hasValue(3),"Root->Ruler->4->SubSub->Blubber->3 is a Value");
ok($blubber->value(3)->toString() eq 3,"Root->Ruler->4->SubSub->Blubber->3 is 3");
ok($subsub->hasMap("Test"),"Root->Ruler->4->SubSub->Test is a Map");
ok($subsub->object("Test")->hasComment(),"Root->Ruler->4->SubSub->Test has a comment");
ok($subsub->object("Test")->getComment()->[0] eq "new Comment here","Root->Ruler->4->SubSub->Test has the right comment");
ok($subsub->map("Test") eq $rmap,"Root->Ruler->4->SubSub->Test is Root->Ruler->4");
ok($ruler->hasList(5),"Root->Ruler->5 is a List");
$rlist=$ruler->list(5);
#ok($rlist->object(0)->isReference(),"Root->Ruler->5->0 is a Reference")
ok($rlist->hasValue(0),"Root->Ruler->5->0 is a Value");
ok($rlist->value(0)->toString() eq "Me\x{c4}ep!","Root->Ruler->5->0 is \"Me\x{c4}ep!\"");

#Sub<20>Entry
ok($objects->hasMap("Sub Entry"),"Ruler->Sub<20>Entry is a Map");
ok($objects->map("Sub Entry")->hasComment(),"Ruler->Sub<20>Entry has a comment");
ok($objects->map("Sub Entry")->getComment()->[0] eq "A map","Ruler->Sub<20>Entry has the first comment right");
ok($objects->map("Sub Entry")->getComment()->[1] eq " End of Map","Ruler->Sub<20>Entry has the second comment right");
ok($objects->map("Sub Entry")->hasValue("Foo") ,"Ruler->Sub<20>Entry->Foo is a Map");
ok($objects->map("Sub Entry")->value("Foo")->toString() eq "Me\x{c4}ep!" ,"Ruler->Sub<20>Entry->Foo is \"Me\x{c4}ep!\"");

#List
ok($objects->hasList("List"),"Root->List");
ok($objects->list("List")->isList(),"Root->List is a List");
ok($objects->list("List")->hasValue(0),"Root->List->0 is a Value");
ok($objects->list("List")->hasValue(1),"Root->List->1 is a Value");
ok(!$objects->list("List")->object(2)->isDefined(),"Root->List->2 is not defined");
ok($objects->list("List")->hasValue(3),"Root->List->3 is a Value");
ok($objects->list("List")->value(0)->toString() eq "","Root->List->0 is ''");
ok($objects->list("List")->value(1)->toString() eq "0","Root->List->1 is '0'");
ok($objects->list("List")->value(3)->toString() eq 3,"Root->List->3 is 3");

#Testing

ok($objects->hasList("Testing"),"Root->Testing");
ok($objects->list("Testing")->isList(),"Root->Testing is a List");
ok($objects->list("Testing")->hasValue(0),"Root->Testing->0 is a Value");
ok($objects->list("Testing")->hasValue(1),"Root->Testing->1 is a Value");
ok($objects->list("Testing")->hasValue(2),"Root->Testing->2 is a Value");
ok($objects->list("Testing")->hasValue(3),"Root->Testing->3 is a Value");
ok($objects->list("Testing")->hasValue(4),"Root->Testing->4 is a Value");
ok($objects->list("Testing")->value(0)->toString() eq '  Text with leading whitepace, and with 2 trailing spaces  ',"Root->List->0 is right");
ok($objects->list("Testing")->value(1)->toString() eq "\n2.Line\n3.Line\n","Root->List->1 is right");
ok($objects->list("Testing")->value(2)->toString() eq "\r","Root->List->2 is right");
ok($objects->list("Testing")->value(3)->toString() eq "Space \n Newline \n Space","Root->List->3 is right");
ok($objects->list("Testing")->value(4)->toString() eq "4Spaces    end","Root->List->4 is right");



eval {
$objects = loadSofu("test.sofu");
};
ok(not($@),"loadSofu");
die($@) if $@;
ok($objects->isMap(),"Root is a Map");
ok($objects->hasComment(),"Root has a comment");
ok($objects->getComment()->[0] eq "Text:  Text file","Root has the right comment");
#Ruler
ok($objects->hasAttribute("Ruler"),"Root->Ruler");
ok($objects->object("Ruler")->isList(),"Root->Ruler is a List");
$ruler = $objects->list("Ruler");
ok($ruler->hasElement(5),"Root->Ruler.len = 5");
ok($ruler->hasValue(0),"Root->Ruler->0 is a Value");
ok($ruler->value(0)->toString() eq 1,"Root->Ruler->0 is 1");
ok($ruler->hasValue(1),"Root->Ruler->1 is a Value");
ok($ruler->value(1)->toString() eq 2,"Root->Ruler->1 is 2");
ok($ruler->value(1)->hasComment(),"Root->Ruler->1 has a Comment");
ok($ruler->value(1)->getComment()->[0] eq "This is the second Value","Root->Ruler->1 has the right Comment");
ok($ruler->hasValue(2),"Root->Ruler->2 is a Value");
ok($ruler->value(2)->toString() eq 3,"Root->Ruler->2 is 3");
ok($ruler->object(3)->isReference(),"Root->Ruler->3 is a Reference");
ok($ruler->hasValue(3),"Root->Ruler->3 is a Value");
ok($ruler->value(3)->toString() eq "Me\x{c4}ep!","Root->Ruler->3 is \"Me\x{c4}ep!\"");
ok($ruler->hasMap(4),"Root->Ruler->4 is a Map");
$rmap = $ruler->map(4);
ok($rmap->hasMap("SubSub"),"Root->Ruler->4->SubSub is a Map");
$subsub = $rmap->map("SubSub");
ok($subsub->hasList("Blubber"),"Root->Ruler->4->SubSub->Blubber is a List");
$blubber=$subsub->list("Blubber");
ok($blubber->hasValue(0),"Root->Ruler->4->SubSub->Blubber->0 is a Value");
ok($blubber->value(0)->toString() eq 1,"Root->Ruler->4->SubSub->Blubber->0 is 1");
ok($blubber->hasValue(1),"Root->Ruler->4->SubSub->Blubber->1 is a Value");
ok($blubber->value(1)->toString() eq 2,"Root->Ruler->4->SubSub->Blubber->1 is 2");
ok($blubber->hasList(2),"Root->Ruler->4->SubSub->Blubber->2 is a List");
$blist = $blubber->list(2);
ok($blist->hasValue(0),"Root->Ruler->4->SubSub->Blubber->2->0 is a Value");
ok($blist->value(0)->toString() eq 4,"Root->Ruler->4->SubSub->Blubber->2->0 is 4");
ok($blist->object(1)->isReference(),"Root->Ruler->4->SubSub->Blubber->2->1 is a Reference");
ok($blist->object(1)->follow() eq $objects,"Root->Ruler->4->SubSub->Blubber->2->1 is the same as \$objects");
ok($blist->hasMap(1),"Root->Ruler->4->SubSub->Blubber->2->1 is also a Map");
ok($blist->hasValue(2),"Root->Ruler->4->SubSub->Blubber->2->2 is a Value");
ok($blist->value(2)->toString() eq 5,"Root->Ruler->4->SubSub->Blubber->2->2 is 5");
ok($blist->hasValue(3),"Root->Ruler->4->SubSub->Blubber->2->3 is a Value");
ok($blist->object(3)->isReference(),"Root->Ruler->4->SubSub->Blubber->2->3 is a Reference");
ok($blist->value(3)->toString() eq "Me\x{c4}ep!","Root->Ruler->4->SubSub->Blubber->2->3 is \"Me\x{c4}ep!\"");
ok($blubber->hasValue(3),"Root->Ruler->4->SubSub->Blubber->3 is a Value");
ok($blubber->value(3)->toString() eq 3,"Root->Ruler->4->SubSub->Blubber->3 is 3");
ok($subsub->hasMap("Test"),"Root->Ruler->4->SubSub->Test is a Map");
ok($subsub->object("Test")->hasComment(),"Root->Ruler->4->SubSub->Test has a comment");
ok($subsub->object("Test")->getComment()->[0] eq "new Comment here","Root->Ruler->4->SubSub->Test has the right comment");
ok($subsub->map("Test") eq $rmap,"Root->Ruler->4->SubSub->Test is Root->Ruler->4");
ok($ruler->hasList(5),"Root->Ruler->5 is a List");
$rlist=$ruler->list(5);
ok($rlist->object(0)->isReference(),"Root->Ruler->5->0 is a Reference");
ok($rlist->hasValue(0),"Root->Ruler->5->0 is a Value");
ok($rlist->value(0)->toString() eq "Me\x{c4}ep!","Root->Ruler->5->0 is \"Me\x{c4}ep!\"");

#Sub<20>Entry
ok($objects->hasMap("Sub Entry"),"Ruler->Sub<20>Entry is a Map");
ok($objects->map("Sub Entry")->hasComment(),"Ruler->Sub<20>Entry has a comment");
ok($objects->map("Sub Entry")->getComment()->[0] eq "A map","Ruler->Sub<20>Entry has the first comment right");
ok($objects->map("Sub Entry")->getComment()->[1] eq " End of Map","Ruler->Sub<20>Entry has the second comment right");
ok($objects->map("Sub Entry")->hasValue("Foo") ,"Ruler->Sub<20>Entry->Foo is a Map");
ok($objects->map("Sub Entry")->value("Foo")->toString() eq "Me\x{c4}ep!" ,"Ruler->Sub<20>Entry->Foo is \"Me\x{c4}ep!\"");

#List
ok($objects->hasList("List"),"Root->List");
ok($objects->list("List")->isList(),"Root->List is a List");
ok($objects->list("List")->hasValue(0),"Root->List->0 is a Value");
ok($objects->list("List")->hasValue(1),"Root->List->1 is a Value");
ok(!$objects->list("List")->object(2)->isDefined(),"Root->List->2 is not defined");
ok($objects->list("List")->hasValue(3),"Root->List->3 is a Value");
ok($objects->list("List")->value(0)->toString() eq "","Root->List->0 is ''");
ok($objects->list("List")->value(1)->toString() eq "0","Root->List->1 is '0'");
ok($objects->list("List")->value(3)->toString() eq 3,"Root->List->3 is 3");

#Testing

ok($objects->hasList("Testing"),"Root->Testing");
ok($objects->list("Testing")->isList(),"Root->Testing is a List");
ok($objects->list("Testing")->hasValue(0),"Root->Testing->0 is a Value");
ok($objects->list("Testing")->hasValue(1),"Root->Testing->1 is a Value");
ok($objects->list("Testing")->hasValue(2),"Root->Testing->2 is a Value");
ok($objects->list("Testing")->hasValue(3),"Root->Testing->3 is a Value");
ok($objects->list("Testing")->hasValue(4),"Root->Testing->4 is a Value");
ok($objects->list("Testing")->value(0)->toString() eq '  Text with leading whitepace, and with 2 trailing spaces  ',"Root->List->0 is right");
ok($objects->list("Testing")->value(1)->toString() eq "\n2.Line\n3.Line\n","Root->List->1 is right");
ok($objects->list("Testing")->value(2)->toString() eq "\r","Root->List->2 is right");
ok($objects->list("Testing")->value(3)->toString() eq "Space \n Newline \n Space","Root->List->3 is right");
ok($objects->list("Testing")->value(4)->toString() eq "4Spaces    end","Root->List->4 is right");

my $VAR1 = {
          'List' => [
                    '',
                    '0',
                    undef,
                    '3'
                  ],
          'Sub Entry' => {
                         'Foo' => decode('ISO-8859-1', "Me\x{c4}ep!")
                       },
          'Testing' => [
                       '  Text with leading whitepace, and with 2 trailing spaces  ',
                       "\n2.Line\n3.Line\n",
                       "\r",
                       "Space \n Newline \n Space",
                       '4Spaces    end'
                     ],
          'Text' => 'Hello World',
          'Ruler' => [
                     '1',
                     '2',
                     '3',
                     decode('ISO-8859-1', "Me\x{c4}ep!"),
                     {
                       'SubSub' => {
                                   'Blubber' => [
                                                '1',
                                                '2',
                                                undef,
                                                '3'
                                              ],
                                   'Test' => undef
                                 }
                     },
                     [
                       decode('ISO-8859-1', "Me\x{c4}ep!")
                     ]
                   ]
        };
$VAR1->{Ruler}->[4]->{SubSub}->{Blubber}->[2]=[
                                                  '4',
                                                  $VAR1,
                                                  '5',
                                                  decode('ISO-8859-1', "Me\x{c4}ep!")
                                                ];
$VAR1->{Ruler}->[4]->{SubSub}->{Test}=$VAR1->{'Ruler'}[4];

my $string = "";

eval {
	$objects->write(\$string);
};
ok((not($@) and $string),"Writing Objects to scalarref");
die $@ if $@;
#die Data::Dumper->Dump([$string,scalar readSofu(\$string)]);
is_deeply(scalar readSofu(\$string),$VAR1,"reading Sofu from Scalarref");
my $packed="";
eval {
	$packed = $objects->pack()
};
ok((not($@) and $packed),"packing Objects");
is_deeply(scalar unpackSofu($packed),$VAR1,"unpackSofu of the packed data");
is_deeply(scalar readSofu(\$packed),$VAR1,"readSofu of the packed data");

unlink "test.sofu";
unlink "test2.sofu";
