use utf8;
use Test::More tests => 11;
BEGIN { use_ok( 'Data::Sofu' ); }
use Encode;

use Data::Sofu qw/readSofu writeSofu getSofuComments packSofu unpackSofu/; #We will need all of that.

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
	"\n2.Line\n3.Line\n"
	"\r"
	"Space \n Newline \n Space"
	"4Spaces    end"
)
);
	close FH;
}
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
#print Data::Dumper->Dump([scalar readSofu("test.sofu")]) and die;
#die $dumptext,Data::Dumper->Dump([scalar readSofu("test.sofu")]);
#This one is different because the reference to the root element is another root object, so the root tree get's copied!
#Prepearations done!
#print $dumptext,"\n";

is_deeply(scalar readSofu("test.sofu"),$VAR1,"readSofu (scalar context)");
is_deeply(scalar readSofu("test.sofu"),$VAR1,"readSofu (list context)");
#readSofu seems OK:
#Testing fo Comments, valid will be tested during write and read again!
ok(getSofuComments(),"Sofu Comments");
eval {
	writeSofu("test2.sofu",$VAR1,getSofuComments());
};
ok(not($@),"Writing with writeSofu, getSofuComments");
die $@ if $@;
#Read the written Sofu Object again:
is_deeply(scalar readSofu("test2.sofu"),$VAR1,"reading written Sofu again");
#Writing to String and reading it again.
my $string = "";

eval {
	writeSofu(\$string,$VAR1,getSofuComments());
};
ok((not($@) and $string),"Writing with writeSofu, getSofuComments to scalarref");
die $@ if $@;
#die Data::Dumper->Dump([$string,scalar readSofu(\$string)]);
is_deeply(scalar readSofu(\$string),$VAR1,"reading Sofu from Scalarref");
my $packed="";
eval {
	$packed = packSofu($VAR1,getSofuComments());
};
ok((not($@) and $packed),"packSofu");
is_deeply(scalar unpackSofu($packed),$VAR1,"unpackSofu of the packed data");
is_deeply(scalar readSofu(\$packed),$VAR1,"readSofu of the packed data");

unlink "test.sofu";
unlink "test2.sofu";

