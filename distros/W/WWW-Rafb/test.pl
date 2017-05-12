#!/usr/bin/perl
use WWW::Rafb;

# create object with the paste information
my $paste = WWW::Rafb->new( 'language' => 'C',
                               'nickname' => 'Di42lo',
                               'description' => 'my first script in perl',
                               'tabs' => 'No',
                               'file' => "/home/diablo/main.c");
								
	# do the http request ( the paste itself )
	$paste->paste();

	# print the url
	print "You can get $paste->{FILE} at url: $paste->{URL}\n";
