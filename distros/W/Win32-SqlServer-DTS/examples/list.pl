use warnings;
use strict;
use XML::Simple;
use Win32::SqlServer::DTS::Application;

my $xml_file = 'modify.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );

my $pkg_info;

print 'Enter a regex for the package name: ';
my $regex = <STDIN>;
chomp $regex;

my $list_ref = $app->regex_pkgs_names($regex);

map { print $_, "\n" } @{$list_ref};

