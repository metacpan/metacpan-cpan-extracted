use strict;
use warnings;

use Test::More 0.98;

use XML::Minify qw(minify);

# Actually we test that the xinclude is feature implemeted by xmlprocessor (XML::LibXML) is preserved by our minifier

# chdir to file
# if we were using XML::LibXML parse_file directly, we would not need this trick
chdir 't/data/';

# Read file
open my $fh, '<', 'xinclude.xml' or die "Can't open file $!";
my $xinclude = do { local $/; <$fh> };

my $xincludeprocessed = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0"><book id="bk101"><author>Chromatic</author><title>Modern Perl</title></book><include>me</include><book id="bk112"><author>Damian Conway</author><title>Perl Best Practices</title></book></catalog>
END
# Same as xmllint catalog.xml --xinclude

my $xincludenotprocessed = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0"><book id="bk101"><author>Chromatic</author><title>Modern Perl</title></book><xi:include href="inc.xml"/><book id="bk112"><author>Damian Conway</author><title>Perl Best Practices</title></book></catalog>
END


chomp $xincludeprocessed;
chomp $xincludenotprocessed;

is(minify($xinclude, no_prolog => 1, process_xincludes => 1), $xincludeprocessed, "Process xinclude");
is(minify($xinclude, no_prolog => 1), $xincludenotprocessed, "Do not process xinclude (default)");

done_testing;

