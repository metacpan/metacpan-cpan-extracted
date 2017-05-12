#!/usr/bin/perl

=head1 NAME

sites-ok.t - check web sites

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
	sites-ok:
	    sites:
	        http://ant.local:
	            content: It works!
	        http://debrepo.ant.local/debian/:
	            title  : Index of /[a-z]+
	            content: Parent Directory
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';


eval "use Test::WWW::Mechanize";
plan 'skip_all' => "need Test::WWW::Mechanize to run web tests" if $@;

my $config = LoadFile($Bin.'/test-server.yaml');
plan 'skip_all' => "no configuration sections for 'sites-ok'"
	if (not $config or not $config->{'sites-ok'});


exit main();

sub main {
	plan 'no_plan';
	
	my $mech = Test::WWW::Mechanize->new;
	my $sites = $config->{'sites-ok'}->{'sites'};
	
	# loop through sites that needs to be working
	foreach my $base_url (keys %$sites) {
		$mech->get_ok($base_url, 'fetch '.$base_url);
		
		# test site title
		my %site = %{$sites->{$base_url}};
		
		# check title
		like($mech->title, qr/$site{'title'}/, 'check title')
			if exists $site{'title'};
		
		#check content
		like($mech->content, qr/$site{'content'}/, 'check content')
			if exists $site{'content'};
		
		# fetch site links
		my $INTERNAL_LINKS_QR = qr{
			^
			(
				$base_url       # links starting with base url
				|
				(?![a-zA-Z]+:)  # and NOT starting with http: or mailto: or ftp: or ...
			)
		}xms;

		$mech->links_ok(
			# match the links that starts with base url or are without http(s) in the beginning
			[ $mech->find_all_links( url_regex => $INTERNAL_LINKS_QR ) ],
			'check all internal page links',
		);
	}
	
	return 0;
}


__END__

=head1 NOTE

Web checking depends on L<Test::WWW::Mechanize>.

=head1 AUTHOR

Jozef Kutej

=cut
