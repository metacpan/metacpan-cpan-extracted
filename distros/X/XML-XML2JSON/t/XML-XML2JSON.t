# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-XML2JSON.t'

#########################

use strict;

use CPAN;
use XML::LibXML;

use Test::More tests => 2;

BEGIN { use_ok('XML::XML2JSON') };

#########################

my $PARSER = XML::LibXML->new;

my @Modules = qw(JSON::Syck JSON::XS JSON JSON::DWIW);

my $XML = qq|<?xml version="1.0" encoding="UTF-8" ?>
<test xmlns:test='http://test.example/test'>
	<data attr1="test">some test text</data>
	<empty a="b"><inner c="d"/></empty>
	<private some="value" />
	<censored foo="secret"/>
	<array perl="awesome" hidden="secret">
		<item index="0"/>
		<item index="1"/>
		<item index="2"/>
	</array>
	<test:nstest attr1="bar"/>
</test>
|;

diag "\nChecking for compatible JSON modules (you need at least one):\n";

my $FoundModules = 0;

foreach my $Module (@Modules)
{
	$FoundModules++ if &check_module($Module);
}

diag "compatible JSON modules found: $FoundModules";

ok($FoundModules);

sub check_module
{
	my ($Module) = @_;
	
	diag "checking for $Module...";
	
	eval "use $Module (); 1;";
	if ($@)
	{
		diag "NOT FOUND";
		return 0;
	}
	else
	{
		eval
		{
			my $XML2JSON = XML::XML2JSON->new
			( 
				module => $Module, 
				pretty => 0,
				empty_elements => [qw( empty )],
				private_elements => [qw( private )],
				private_attributes => [qw( foo hidden )],
				debug => 0,
			);
			my $JSON = $XML2JSON->convert($XML);
			
			diag "JSON from $Module: $JSON\n";
			
			# check attribute
			die "$Module: attribute test failed" unless $JSON =~ /["']\@attr1["']\s*:\s*["']test["']/;

			# check element text
			die "$Module: text test failed" unless $JSON =~ /["']\$t["']\s*:\s*["']some test text["']/;
			
			my $Object = $XML2JSON->json2obj($JSON);
			
			# make sure arrays work
			die "did not create array of elements correctly" 
				unless $Object->{test}->{array}->{item}->[2]->{'@index'} eq '2';
			
			# test sanitize
			die "$Module: private element was not removed" if $Object->{test}->{private};
			die "$Module: empty element is not empty" if grep /^\@/, keys %{$Object->{test}->{empty}};
			die "$Module: empty element destroyed child" unless $Object->{test}->{empty}->{inner};
			die "$Module: private attribute \@foo was not removed" if $Object->{test}->{censored}->{'@foo'};
			die "$Module: private attribute \@hidden was not removed" if $Object->{test}->{array}->{'@hidden'};
			
			# back to XML...
			my $xml2 = $XML2JSON->obj2xml($Object);
			#diag "and back again: $xml2";
			my $dom = $PARSER->parse_string($xml2);
			diag "Reconstructed XML: " . $dom->toString();
			
			my $item2 = $dom->documentElement->findvalue('array/item[@index=2]/@index');
		    die "the reconstructed xml is invalid" unless ($item2 eq '2');
		};
		if ($@)
		{
			diag "FAILED: $@";
			return 0;
		}
	}
	
	diag "OK";
	return 1;
}
