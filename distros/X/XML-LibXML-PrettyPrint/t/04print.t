use strict;
use warnings;
use Test::More;
use Test::Warnings;

use XML::LibXML::PrettyPrint 0.001 qw(-io);

my $FN = 'print_xml.tmp';

SKIP: {
	open FILE, '>', $FN
		or skip "cannot write to temporary file.", 1;
	print_xml FILE '<foo>  <bar>  </bar>  </foo>';
	close FILE;

	my $contents = do { open my($fh), $FN; local $/ = <$fh>; };

	is($contents, <<'DATA', 'print_xml works with bareword handle');
<?xml version="1.0"?>
<foo>
	<bar/>
</foo>
DATA

	unlink $FN;
}

SKIP: {
	open my($file), '>', $FN
		or skip "cannot write to temporary file.", 1;
	print_xml $file '<foo>  <bar>  </bar>  </foo>';
	close $file;

	my $contents = do { open my($fh), $FN; local $/ = <$fh>; };

	is($contents, <<'DATA', 'print_xml works with lexical handle');
<?xml version="1.0"?>
<foo>
	<bar/>
</foo>
DATA

	unlink $FN;
}

SKIP: {
	open my($file), '>', $FN
		or skip "cannot write to temporary file.", 1;
	$file->print_xml('<foo>  <bar>  </bar>  </foo>');
	close $file;

	my $contents = do { open my($fh), $FN; local $/ = <$fh>; };

	is($contents, <<'DATA', 'print_xml works as method with lexical handle');
<?xml version="1.0"?>
<foo>
	<bar/>
</foo>
DATA

	unlink $FN;
}

done_testing;
