use strict;
use warnings;

use Test::More 0.98;

use XML::Minifier qw(minify);

my $maxi = << "END";
<!DOCTYPE root [
<!ELEMENT protectednode (#PCDATA | protectedleaf | unprotectedleaf)*>
<!ELEMENT protectedleaf (#PCDATA)*>

]>
<root>

<protectednode>

<protectedleaf>                       </protectedleaf>
<unprotectedleaf>                       </unprotectedleaf>

</protectednode>
</root>
END

my $mini = << "END";
<root><protectednode>

<protectedleaf>                       </protectedleaf>
<unprotectedleaf/>

</protectednode></root>
END



chomp $maxi;
chomp $mini;

# The unprotected leaf is protected because it is a leaf
is(minify($maxi, no_prolog => 1), $mini, "DTD protect node and leaf (but DTD itself is removed)");

$maxi = << "END";
<!DOCTYPE root [
<!ELEMENT protectednode (protectedleaf | unprotectedleaf)*>
<!ELEMENT protectedleaf (#PCDATA)*>

]>
<root>

<protectednode>

<protectedleaf>                       </protectedleaf>
<unprotectedleaf>                       </unprotectedleaf>

</protectednode>
</root>
END

$mini = << "END";
<root><protectednode><protectedleaf>                       </protectedleaf><unprotectedleaf/></protectednode></root>
END

my $ignore = << "END";
<root><protectednode><protectedleaf>                       </protectedleaf><unprotectedleaf>                       </unprotectedleaf></protectednode></root>
END

chomp $maxi;
chomp $mini;
chomp $ignore;

# The unprotected leaf is protected because it is a leaf
is(minify($maxi, no_prolog => 1), $mini, "DTD does not protect node (but DTD itself is removed)");
is(minify($maxi, no_prolog => 1, ignore_dtd => 1), $ignore, "Ignore DTD");

$maxi = << "END";
<!DOCTYPE root [ <!ELEMENT protectednode (protectedleaf | unprotectedleaf)*> <!ELEMENT protectedleaf (#PCDATA)*> <!ELEMENT somethingelse (tag)*>

]>
<root>

<protectednode>

<protectedleaf>                       </protectedleaf>
<unprotectedleaf>                       </unprotectedleaf>

</protectednode>
</root>
END

$mini = << "END";
<root><protectednode><protectedleaf>                       </protectedleaf><unprotectedleaf/></protectednode></root>
END

chomp $maxi;
chomp $mini;

is(minify($maxi, no_prolog => 1), $mini, "DTD on one line");

$maxi = << "END";
<!DOCTYPE root [ <!ELEMENT protectednode (protectedleaf | unprotectedleaf)*> <!ELEMENT unprotectedleaf (tag)*> <!ELEMENT somethingelse (#PCDATA)*>

]>
<root>

<protectednode>

<unprotectedleaf>                       </unprotectedleaf>

</protectednode>
</root>
END

$mini = << "END";
<root><protectednode><unprotectedleaf/></protectednode></root>
END

chomp $maxi;
chomp $mini;

is(minify($maxi, no_prolog => 1), $mini, "DTD on one line try to make the regex fail (the weak .*)");


done_testing;

