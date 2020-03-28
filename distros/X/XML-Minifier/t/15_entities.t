use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier qw(minify);


# chdir to file
chdir 't/data/';

# Actually we test that the processing of entities which is a feature implemeted by xmlprocessor (XML::LibXML) is preserved by our minifier

# Read file
open my $fh, '<', 'entitynotag.xml' or die "Can't open file $!";
my $entity = do { local $/; <$fh> };
close $fh;

my $entityexpanded = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0">

Just Another Perl Hacker,

</catalog>
END
# Same as xmllint entity.xml --noent

my $entitynotexpanded = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0">

&japh;

</catalog>
END


chomp $entityexpanded;
chomp $entitynotexpanded;

#is(minify($entity, no_prolog => 1, expand_entities => 1), $entityexpanded, "Process entities");
is(minify($entity, no_prolog => 1), $entitynotexpanded, "Do not process entities (default)");

# Read file
open $fh, '<', 'entitywithtag.xml' or die "Can't open file $!";
$entity = do { local $/; <$fh> };
close $fh;

$entityexpanded = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0"><strong>Just Another Perl Hacker,</strong></catalog>
END
# Same as xmllint entity.xml --noent

$entitynotexpanded = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude" version="1.0">

&japh;

</catalog>
END


chomp $entityexpanded;
chomp $entitynotexpanded;

#is(minify($entity, no_prolog => 1, expand_entities => 1), $entityexpanded, "Process entities with a tag therefore some blanks cleaning is done");
is(minify($entity, no_prolog => 1), $entitynotexpanded, "Do not process entities (default)");

done_testing;

