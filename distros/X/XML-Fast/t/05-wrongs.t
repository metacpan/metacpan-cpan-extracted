#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;1 }
		and *had_no_warnings = \&Test::NoWarnings::had_no_warnings
		or  *had_no_warnings = sub {} and diag "Test::NoWarnings missed, skipping no warnings test";
	#plan tests => 26 + $add;
	eval {require Data::Dumper;Data::Dumper::Dumper(1)}
		and *dd = sub ($) { Data::Dumper->new([$_[0]])->Indent(0)->Terse(1)->Quotekeys(0)->Useqq(1)->Purity(1)->Dump }
		or  *dd = \&explain;
}

use XML::Fast 'xml2hash';

sub dies_ok(&;@) {
	my $code = shift;
	my $name = pop || 'line '.(caller)[2];
	my $qr = shift;
	local $@;
	if( eval { $code->(); 1} ) {
		fail $name;
	} else {
		if ($qr) {
			like $@,$qr,"$name - match ok";
		} else {
			diag "died with $@";
		}
		pass $name;
	}
}

dies_ok { xml2hash('<') } qr/Bad document end/, 'open tag';
dies_ok { xml2hash('<!') } qr/Bad document end/, 'open !';
dies_ok { xml2hash('<!--') } qr/Comment node not terminated/, 'unbalanced comment';
dies_ok { xml2hash('<![CDATA[') } qr/Cdata node not terminated/, 'unbalanced cdata';
dies_ok { xml2hash('<!DOCTYPE') } qr/Doctype not properly terminated/, 'unbalanced doctype';
dies_ok { xml2hash('<!DOCTYPE ') } qr/Doctype not properly terminated/, 'unbalanced doctype';
dies_ok { xml2hash('<!DOCTYPE[') } qr/Doctype intSubset not terminated/, 'unbalanced doctype';
dies_ok { xml2hash('<!BULLSHIT') } qr/Malformed document after/, 'bad <!';
dies_ok { xml2hash('<!BULLSHIT ') } qr/Malformed document after/, 'bad <!+';
dies_ok { xml2hash('<?') } qr/Processing instruction not terminated/, 'open PI';
dies_ok { xml2hash('<? ') } qr/Bad processing instruction/, 'open PI_';
dies_ok { xml2hash('<?x?') } qr/Processing instruction not terminated/, 'open PI';
dies_ok { xml2hash('<?x a="1" ?') } qr/Processing instruction not terminated/, 'open PI';
dies_ok { xml2hash('<?x a=b=c ?>') } qr/Error parsing PI attributes/, 'PI bad attrs';
{
	local $TODO = 'bad EOD tracking';
}
dies_ok { xml2hash('<a></') } qr/Close tag not terminated/, 'unclosed close node';
dies_ok { xml2hash('</x') } qr/Close tag not terminated/, 'unclosed close node 2';
dies_ok { xml2hash('<x') } qr/Unterminated node/, 'unclosed open node';

dies_ok { xml2hash('<a') } qr/Unterminated node/, 'unclosed open tag';
dies_ok { xml2hash('<a ') } qr/Error parsing node attributes/, 'unclosed open tag + sp';
dies_ok { xml2hash('<a /') } qr/Unterminated node/, 'unclosed open tag + sl';
dies_ok { xml2hash('<x a=b=c>') } qr/Error parsing node attributes/, 'node bad attrs';

dies_ok { xml2hash('<>') } qr/Bad node open/, 'null node';
dies_ok { xml2hash('</>') } qr/Empty close tag name/, 'null / node';

had_no_warnings();
done_testing();