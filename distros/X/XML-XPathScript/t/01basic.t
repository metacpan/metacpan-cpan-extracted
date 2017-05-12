#!/usr/bin/perl

use strict;
use Test;

BEGIN
{
	plan tests => 6, todo => [];
}

use XML::XPathScript;

ok(1); # So we can load XPathScript. Yay!

do {

	my( $style, $xml );
	open $style, "t/t1.xps";
	open $xml, "t/t1.xml";
	my $xps = new XML::XPathScript( xml => $xml, stylesheet => $style );

	undef $/;
	open F, "t/t1.result";
	my $result = <F>;
	close F;

	my $buf="";
	$xps->process(sub {$buf .= shift});
	ok($buf, $result);
};

do {
	my( $style, $xml );
	open $style, "t/t2.xps";
	open $xml, "t/t1.xml";
	my $xps = new XML::XPathScript( xml => $xml, stylesheet => $style );

	my $buf="";
	$xps->process(sub {$buf .= shift});
	ok($buf,'<chicken></chicken>
');
};

# Redirection test, and also sync'ness of compat test cases
do {
	my( $style, $xml );
	open $xml, "t/t1.xml";

	my $xps = new XML::XPathScript( xml => $xml,
									stylesheetfile =>  "t/t2_compat.xps");

	open FILE, ">", "t/out.bogus";
	$xps->process(\*FILE);
	close(FILE);

	open FILE, "<", "t/out.bogus";
	ok(scalar <FILE>,'<chicken></chicken>
');
	unlink("t/out.bogus");
};

# Test for comment and text nodes
do {

	my $xml = '<doc><!-- comment --><p>oops</p></doc>';
	my $style = <<'EOT';
<%
	$t->{'comment()'}{pre}  = '<comment />';
	$t->{'comment()'}{testcode} = sub{ DO_SELF_ONLY() };

	$t->{'text()'}{testcode} = sub {

		my ( $n, $t ) = @_;

		$t->{pre} = $n->toString;

		$t->{pre} =~ s/oops/yay/;

		return DO_SELF_ONLY();
	};

%><%= apply_templates() %>
EOT
	
	my $xps = new XML::XPathScript( xml => $xml, stylesheet => $style );

	my $buf="";
	$xps->process(sub {$buf .= shift});
	ok( $buf,"<doc><comment /><p>yay</p></doc>\n" );

};

# set_xml and set_stylesheet
my $xps = XML::XPathScript->new;
$xps->set_xml( '<doc><t>sets rule</t></doc>' );
$xps->set_stylesheet( '<%~ //t %>' );

ok $xps->transform => '<t>sets rule</t>';

