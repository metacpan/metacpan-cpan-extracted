#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP qw/load_wsdl/;
use WWW::Mechanize;
use File::Temp qw/ tempfile tempdir /;
use XML::LibXML;
use Try::Tiny;

#
# This script tests W3C-SOAP against real world WSDL files gathered from the xmethods.com site.
# Before checking any WSDL against W3C::SOAP the WSDL is downloaded and
# validated only if there no problems encountered will it try to run a test
#

my %option = (
    file => 'wsdls.txt',
);
Getopt::Long::Configure('bundling');
GetOptions(
    \%option,
    'file|f=s',
    'die|die-on-error',
    'verbose|v+',
    'man',
    'help',
    'VERSION!',
) or pod2usage(2);

my $dir = path($0)->parent;
my $wsdls = $dir->child($option{file})->openr;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $mech = WWW::Mechanize->new;
$mech->timeout(2);
my $count = 1;
my $skipped = 0;
my %state;

while (my $wsdl = <$wsdls>) {
    next if $wsdl =~ /^#/;
    next if $wsdl =~ /^\s*$/;
    next if $ENV{SKIP} && $ENV{SKIP}--;

    chomp $wsdl;
    SKIP: {
        try {
            $skipped++;
            get_dependencies($wsdl);
            test_wsdl($wsdl);
            $skipped = 0;
        }
        catch {
            push @{ $state{unavailable} }, $wsdl;
            die $_ if $option{die};
            skip "The WSDL ($wsdl) can't be retreived or is not valid", 1
                if $_;
        }
    };
}
file('result.pl')->spew(Dumper \%state);
done_testing;

sub test_wsdl {
    my ($wsdl) = @_;

    # create the parser object
    my @cmd = ( qw/perl -MW3C::SOAP=load_wsdl -e/, "load_wsdl(q{$wsdl})" );
    note join ' ', @cmd, "\n";
    my $error = system @cmd;
    ok !$error, "Loaded $wsdl";
    push @{ $state{ $error ? 'good' : 'bad' } }, $wsdl;
        #or BAIL_OUT("Error: $error");
    return;
}

# check that the WSDLs & XSDs can be downloaded, parsed as XML documents and validated
sub get_dependencies {
    my ($url, $xsd) = @_;
    my $xml = XML::LibXML->load_xml(location => $url);

    # write the XML document to disk
    my ($fh, $xml_file) = tempfile();
    print {$fh} $xml->toString;
    my $not_valid = system "xmllint --schema '". ($xsd ? 'http://www.w3.org/2001/XMLSchema.xsd' : 'http://schemas.xmlsoap.org/wsdl/' ) . "' '$xml_file' >/dev/null 2>/dev/null";
    die "Not valid" if $not_valid;

    # look for any XSDs imported or included
    my $xpc = XML::LibXML::XPathContext->new($xml);
    $xpc->registerNs(xsd  => 'http://www.w3.org/2001/XMLSchema');

    my @xsds = $xpc->findnodes('//xsd:import');
    push @xsds, $xpc->findnodes('//xsd:include');

    while ( my $xsd = shift @xsds ) {
        my $loc = $xsd->getAttribute('schemaLocation') || $xsd->getAttribute('namespace');
        if ( $url && $url =~ m{^(?:https?|ftp)://} ) {
            $loc = URI->new_abs($loc, $url) . '';
        }
        my $file = get_dependencies($loc, 1);
    }

    return;
}

