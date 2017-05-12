use Test;
BEGIN {
    eval {
        require XML::Handler::YAWriter;
    };
    if ($@) {
        print "1..0 # Skipping test on this platform\n";
        $skip = 1;
    }
    else {
        plan tests => 4;
    }
}
use XML::Generator::Win32OLETypeLib;
unless ($skip) {

ok(1);

my $handler = XML::Handler::YAWriter->new(AsString => 1,
	Pretty => {
		CatchEmptyElement => 1,
		# PrettyWhiteIndent => 1,
		# PrettyWhiteNewline => 1,
	},
	);

ok($handler);

my $generator = XML::Generator::Win32OLETypeLib->new($handler);
ok($generator);

my $str = $generator->find_typelib("Microsoft Winsock");
ok($str);

warn($str);

}
