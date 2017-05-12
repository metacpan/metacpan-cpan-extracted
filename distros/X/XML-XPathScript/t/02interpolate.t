#!/usr/bin/perl

use strict;
use Test;

BEGIN
{
	plan tests => 2, todo => [];
}

use XML::XPathScript;

do {
	my $xps = new XML::XPathScript( xml => <<'XML',
<doc>
<linkinter url="/some/where"><blah/></linkinter>
<link url="/some/where"><blah/></link>
</doc>
XML
									stylesheet => <<'STYLE' );
<%
   $t->{'linkinter'}{pre} = '<a href="{@url}">';
   $t->{'linkinter'}{post} = '</a>';
   $t->{'link'}{testcode} = sub {
      my ($currentnode, $t) = @_;
      my $url = $currentnode->getAttribute('url');
      $t->{pre}="<a href=\"$url\">";
      $t->{post}='</a>';
      return 1;
   };
%><%= apply_templates() %>
STYLE

	my $buf="ABC";
	$xps->process(\$buf);

	ok($buf, <<'EXPECTED');
<doc>
<a href="/some/where"><blah></blah></a>
<a href="/some/where"><blah></blah></a>
</doc>
EXPECTED
};


do {
	my $xps = new XML::XPathScript( xml => <<'XML',
<doc>
<link url="/some/where"><blah/></link>
</doc>
XML
									stylesheet => <<'STYLE' );
<%
	# by default, we interpolate
   die unless get_interpolation();
    # set to 1 (no-op)
   die unless set_interpolation(1);
   	# recheck
   die unless get_interpolation();

	# set to 0
   die if set_interpolation(0);

	# re-check
   die if get_interpolation();

   	# set to 0 again
   die if set_interpolation(0);
   die if get_interpolation();

   $t->{'link'}{pre} = '<a href="{@url}">';
   $t->{'link'}{post} = '</a>';
%><%= apply_templates() %>
STYLE

	my $buf="";
	$xps->process(\$buf);

	ok($buf, <<'EXPECTED');
<doc>
<a href="{@url}"><blah></blah></a>
</doc>
EXPECTED
};
