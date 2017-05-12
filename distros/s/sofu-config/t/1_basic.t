use utf8;
use Test::More tests => 18;
BEGIN { use_ok( 'Data::Sofu' ); }
BEGIN { require_ok( 'Config::Sofu' ); }
use Data::Sofu qw/readSofu getSofuComments writeBinarySofu/;
use Data::Dumper;
#unless (-e "test.sofu") {
#generating input file:
{
	open FH,">","test.sofu";
	print FH q(#Text:  Text file
Ruler = (
	"1"
	"2" #This is the second Value
	"3"
	UNDEF
	{
		SubSub= {
			Blubber = ("1" "2" (4 UNDEF 5 UNDEF) "3")
			Test = UNDEF #new Comment here
		}
	}
	(
		"meep"
	)
)
SubEntry = { #A map
	Foo = "meep"
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
          'SubEntry' => {
                         'Foo' => "meep"
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
                     undef,
                     {
                       'SubSub' => {
                                   'Blubber' => [
                                                '1',
                                                '2',
                                                [4,undef,5,undef],
                                                '3'
                                              ],
                                   'Test' => undef
                                 }
                     },
                     [
                       "meep"
                     ]
                   ]
        };

our %CONFIG;
eval {
	require Config::Sofu;
	Config::Sofu->import("test.sofu");
};

ok(not($@),"Importing Sofu");



is_deeply(\%CONFIG,$VAR1,"check loaded Sofu against current");

SKIP: {
        skip "Data::Sofu > 0.23 needed to test comments", 1 unless $Data::Sofu::VERSION ge "0.23";
	ok($Config::Sofu::Comment,"Loaded comments");
}
eval {
	Config::Sofu->save();
};
ok(not($@),"Saving Sofu");
my $v;
eval {
	$v = scalar readSofu("test.sofu");
};
ok(not($@),"reading saved .sofu again");
ok($v,"read data from saved .sofu");
is_deeply($v,\%CONFIG,"check read Sofu against its source");
SKIP: {
        skip "Data::Sofu > 0.23 needed to test comments", 1 unless $Data::Sofu::VERSION ge "0.23";
	ok(getSofuComments(),"Loaded comments");
}

SKIP: {
	skip "Data::Sofu > 0.28 needed to test binary", 4 unless $Data::Sofu::VERSION ge "0.28";
	eval {writeBinarySofu("test.bsofu",$VAR1,$Config::Sofu::Comment,"UTF-8",undef,undef);}; ok(not($@),"Writing binary testfile");
	eval {
		require Config::Sofu;
		Config::Sofu->import("test.sofu");
	};
	ok(not($@),"Importing BinarySofu");
	ok($Config::Sofu::Comment,"Loaded comments from binary");
	is_deeply(\%CONFIG,$VAR1,"check loaded binary Sofu against current");
	eval {
		Config::Sofu->save();
	};
	ok(not($@),"Saving binary Sofu");
	eval {
		$v = scalar readSofu("test.bsofu");
	};
	ok(not($@),"reading saved .bsofu again");
	is_deeply($v,\%CONFIG,"check read Sofu against its source");
	ok(getSofuComments(),"Loaded comments");

}
unlink "test.sofu";
unlink "test.bsofu";

