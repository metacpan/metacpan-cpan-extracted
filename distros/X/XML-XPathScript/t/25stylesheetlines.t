use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use XML::XPathScript;

my $xps = XML::XPathScript->new;
$xps->set_xml( '<doc/>' );
$xps->set_stylesheet( <<'END_STYLESHEET' );
    One
    Two
    <% 'line 3' %>
    <% 'three';
    'four';
    %>
    <% 'line 7' %>
    <%# 'six' %>
    <% 'line 9' %>
    <%@ foo

    %>
    <% die 'line 13' %>
    ten
END_STYLESHEET

eval { $xps->transform };

ok $@ =~ /line 13.*line 13/;


