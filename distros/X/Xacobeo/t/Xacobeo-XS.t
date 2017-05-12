#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin";

BEGIN { use_ok('Xacobeo::XS') };
use Xacobeo::UI::SourceView;
use Xacobeo::Document;
use Xacobeo::Utils 'scrollify';

use Glib qw(TRUE FALSE);
use Gtk2 qw(-init);
use FindBin;
use File::Slurp qw(slurp);
use Encode 'decode';


exit tests() unless caller;


sub tests {

	my $window = Gtk2::Window->new();
	my $textview = Xacobeo::UI::SourceView->new();
	$textview->set_show_line_numbers(TRUE);
	$textview->set_highlight_current_line(TRUE);
	$window->set_size_request(800, 600);
	$window->add(scrollify($textview));
	$window->signal_connect(destroy => sub { Gtk2->main_quit(); });

	foreach my $file ('sample.xml') {

		my $filename = File::Spec->catfile($FindBin::Bin, File::Spec->updir, 'tests', $file);
		my $document = Xacobeo::Document->new_from_file($filename, 'xml');

		$textview->set_document($document);
		$textview->load_node($document->documentNode);

		my $buffer = $textview->get_buffer;
		my $text = $buffer->get_text($buffer->get_start_iter, $buffer->get_end_iter, TRUE);
	
		my $expected = expected($filename);
		if ($text ne $expected) {
			my @got = split /\n/, $text;
			my @expected = split /\n/, $expected;
			is_deeply(\@got, \@expected, "Generated the proper XML for $file");

			# Start the GUI's main loop
			$window->show_all();
			Gtk2->main();
		}
		else {
			ok("XML rendered properly $file");
		}
	}

	return 0;
}


sub expected {
	my ($file) = @_;
	$file .= '.expected';
	my $content = decode('UTF-8', slurp($file));
	chomp ($content);
	return $content;
}
