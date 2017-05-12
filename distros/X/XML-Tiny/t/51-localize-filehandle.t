use XML::Tiny qw(parsefile);

require "t/test_functions";
print "1..3\n";

open(XML::Tiny::FH, $0) || die "Couldn't read '$0': $!"; # read a file
seek(XML::Tiny::FH, 10, 0) || die "Couldn't seek '$0': $!";

my $fh_pos = tell XML::Tiny::FH;
ok($fh_pos, "Opened and read some random file as *XML::Tiny::FH");

my $document = parsefile('t/localize-filehandles.xml');

ok(defined($document), "We read an XML file");

my $new_pos = tell *XML::Tiny::FH;
ok($new_pos == $fh_pos, "The filehandle survived unchanged.");
