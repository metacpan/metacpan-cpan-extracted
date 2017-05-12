package XUL::Node::Application::HTMLExample;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application';

sub start {
	Window(VBox(FILL,
		HTML_H1(textNode => 'This is an <H1> heading.'),
		HTML_H2(textNode => 'This is an <H2> heading.'),
		HTML_H3(textNode => 'This is an <H3> heading.'),
		HTML_H4(textNode => 'This is an <H4> heading.'),
		HTML_Pre(textNode => "1st line of <pre> element.\nSecond line."),
		# for some reason mozilla only shows links if inside some HTML element
		HTML_Div(HTML_A(
			textNode => 'An <href> to http://www.mozilla.org, in this window',
			href     => 'http://www.mozilla.org',
			target   => 'new_browser',
		)),
	))
}

1;
