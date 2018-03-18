use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

eval { require XML::Parser; };
if($@) {
  plan skip_all => 'no XML::Parser';
}

plan tests => 2;

use XML::Simple;

$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

my ($fh, $filename) = tempfile(UNLINK => 1);
print $fh "bad";
close $fh;

my $xml = qq(<?xml version="1.0"?>
<!DOCTYPE foo [ <!ELEMENT foo ANY >
<!ENTITY xxe SYSTEM "file://$filename" >]>
<creds>
    <user>&xxe;</user>
    <pass>mypass</pass>
</creds>
);

my $opt = XMLin($xml);
isnt($opt->{'user'}, 'bad', 'External entity not retrieved');
like($opt->{'user'}, qr/^file/, 'External entity left as URL');

unlink($filename) if (-f $filename);
exit(0);
