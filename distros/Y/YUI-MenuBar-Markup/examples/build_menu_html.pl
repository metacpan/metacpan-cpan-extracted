#!/usr/local/bin/perl
# 
# build_menu_html.pl
# 
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 01/19/2010 13:44:22 PST 13:44:22

use strict;
use warnings;
use YUI::MenuBar::Markup;
use YUI::MenuBar::Markup::YAML;
use Data::Dumper;

my $markup_yaml = YUI::MenuBar::Markup::YAML->new(
        filename => 'examples/menu_yaml.yaml');
my $markup = YUI::MenuBar::Markup->new(
        source_ref => $markup_yaml);

my $html_head_body = <<HTML;
<html>
	<head>
		<title>MenuBar</title>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
		<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.6.0/build/fonts/fonts-min.css" />
		<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.6.0/build/grids/grids-min.css" />
		<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.6.0/build/menu/assets/skins/sam/menu.css" />
		<!-- links related to tooltips -->
        <script type="text/javascript" src="http://yui.yahooapis.com/2.6.0/build/yahoo-dom-event/yahoo-dom-event.js"></script>
        <script type="text/javascript" src="http://yui.yahooapis.com/2.6.0/build/container/container_core.js"></script>
        <script type="text/javascript" src="http://yui.yahooapis.com/2.6.0/build/menu/menu.js"></script>
	</head>
	<body class="yui-skin-sam" bgcolor="#FFFFFF" text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
HTML
print $html_head_body;
print $markup->generate();

