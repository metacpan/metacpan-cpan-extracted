use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier qw(minify);

my $cdataincomment = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude">
<book/>
<!-- <![CDATA[ ...]]> -->
</catalog>
END

my $commentincdata = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude">
<book/>
<![CDATA[ <!-- Comment --> ]]>
</catalog>
END

my $minikeepcdataincomment = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/>
<!-- <![CDATA[ ...]]> -->
</catalog>
END

my $minidropcdataincomment = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/></catalog>
END

my $minikeepcommentincdata = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/>
<![CDATA[ <!-- Comment --> ]]>
</catalog>
END

my $minidropcommentincdata = << "END";
<catalog xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xi="http://www.w3.org/2001/XInclude"><book/></catalog>
END

chomp $cdataincomment;
chomp $commentincdata;
chomp $minikeepcdataincomment;
chomp $minidropcdataincomment;
chomp $minikeepcommentincdata;
chomp $minidropcommentincdata;

is(minify($cdataincomment, no_prolog => 1, keep_comments => 1), $minikeepcdataincomment, "Keep cdata in comment");
is(minify($cdataincomment, no_prolog => 1, keep_comments => 0), $minidropcdataincomment, "Remove cdata with comment (1)");
is(minify($cdataincomment, no_prolog => 1, keep_comments => 1, keep_cdata => 0), $minikeepcdataincomment, "Keep cdata as protected by comment");
is(minify($cdataincomment, no_prolog => 1, keep_comments => 0, keep_cdata => 1), $minidropcdataincomment, "Remove cdata with comment (2)");

is(minify($commentincdata, no_prolog => 1, keep_cdata => 1), $minikeepcommentincdata, "Keep comment in cdata");
is(minify($commentincdata, no_prolog => 1, keep_cdata => 0), $minidropcommentincdata, "Remove comment with cdata (1)");
is(minify($commentincdata, no_prolog => 1, keep_cdata => 1, keep_comments => 0), $minikeepcommentincdata, "Keep comment as protected by cdata");
is(minify($commentincdata, no_prolog => 1, keep_cdata => 0, keep_comments => 1), $minidropcommentincdata, "Remove comment with cdata (2)");

done_testing;

