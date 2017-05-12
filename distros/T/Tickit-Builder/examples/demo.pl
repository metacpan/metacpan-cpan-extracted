#!/usr/bin/perl 
use strict;
use warnings;

# Both of these are pulled in by Tickit::Builder at the moment, but that
# may change in future so we're explicitly listing them now anyway.
use IO::Async::Loop;
use Tickit::Async;

use Tickit::Builder;

my $layout = Tickit::Builder->new;
# We'll let the layout instance control the main event loop.
# If given a file as a parameter, will attempt to read from that file - assumes
# JSON content.
$layout->run(@ARGV ? $$layout->parse_file(@ARGV) : {
	# Provide a default example
	widget => {
		type => 'VBox',
		children => [
			{ widget => { type => "HBox", text => "Static entry", children => [
				{ widget => { type => "VBox", children => [
					{ widget => { type => "Tree", keybindings => {
							'C-r' => 'grab_focus',
						}, label => 'Root', is_open => 1, last => 1, children => [
						{ widget => { type => "Tree", label => 'Users', is_open => 0, children => [
							{ widget => { type => "Tree", label => 'Local', children => [
								{ widget => { type => "Tree", label => 'First user' } },
								{ widget => { type => "Tree", label => 'Second user' } },
								{ widget => { type => "Tree", label => 'Third user' } },
							] } },
							{ widget => { type => "Tree", label => 'Remote', last => 1, children => [ ] } },
						] } },
						{ widget => { type => "Tree", label => 'Groups', last => 1, children => [
						] } },
					] }, expand => 1 },
				] }, expand => 0.15 },
				{ widget => { type => "VBox", children => [
					{ widget => { type => "Frame", style => 'single', title => 'Main editing area', children => [
						{ widget => { type => "Scroller", children => [
							{ widget => { type => "Scroller::Item::Text", text => "This is an example layout." } },
							{ widget => { type => "Scroller::Item::Text", text => " " } },
							{ widget => { type => "Scroller::Item::Text", text => "For more examples, please consult the documentation." } },
						], fg => 'yellow' }, expand => 1 },
					] }, expand => 1 },
					{ widget => { type => "Frame", style => 'single', title => 'Log messages', children => [
						{ widget => { type => "Static", text => "Lower panel" } },
					] } },
				] }, expand => 0.85 },
			] }, expand => 1 },
			{ widget => { type => "Static", text => "Status bar", bg => 0x04, fg => 'white', } },
		],
	}
});

