#!/usr/bin/perl
use utf8;
use XML::Rules;
open my $OUT, '>:utf8', 'output.xml';
open my $LOGOUT, '>:utf8', 'log.dat';
my $parser = new XML::Rules (
	rules => [
         _default => 'raw',
#         'data,title' => sub{
         'data' => sub{
             my ($tagname, $attrHash, $contexArray, $parentDataArray, $parser) = @_;
             my  $string =  $attrHash->{_content};
             $string =~ s/^file:\/\/\/var\//file:\/\/\/usr\//;
             return $tagname => $string;
         },
     ],
style => 'filter',
#   other options
);

#open my $IN, '<', 'input.xml';
#binmode $IN;
$IN = \*DATA;
$parser->filter( $IN, $OUT);
close $IN;
close $OUT;

__DATA__
<?xml version="1.0"?>
<recs>
  	<rec>
	<title>The times &amp; the rivers</title>
	<data>file:///var/documents/doc.pdf</data>
	</rec>
</recs>