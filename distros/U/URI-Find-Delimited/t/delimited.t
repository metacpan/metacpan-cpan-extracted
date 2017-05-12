use strict;
local $^W = 1;

use Test::More tests => 18;

use_ok( "URI::Find::Delimited" );

my $finder = URI::Find::Delimited->new;

my $text = "This contains no URIs";
$finder->find(\$text);
is( $text, qq|This contains no URIs|, "left alone if no URIs" );

$text = "http://the.earth.li/ foo bar";
$finder->find(\$text);
like( $text, qr|<a href="http://the.earth.li/">http://the.earth.li/</a>|,
    "URIs at very start of line are picked up" );
is( $text, qq|<a href="http://the.earth.li/">http://the.earth.li/</a> foo bar|,
    "...and don't pick up trailing stuff as a title" );

$text = "foo bar http://the.earth.li/";
$finder->find(\$text);
is( $text, qq|foo bar <a href="http://the.earth.li/">http://the.earth.li/</a>|,
    "URIs at very end of line are picked up" );

$text = "This is a sentence containing http://the.earth.li/";
$finder->find(\$text);
is( $text, qq|This is a sentence containing <a href="http://the.earth.li/">http://the.earth.li/</a>|,
    "URI used as title if no title or delimiters" );
#print "# $text\n";

$text = "[http://use.perl.org/]";
$finder->find(\$text);
is( $text, qq|[<a href="http://use.perl.org/">http://use.perl.org/</a>]|,
    "delimited URIs are found even if no title" );

$text = "This has a [http://the.earth.li/ usemod link]";
$finder->find(\$text);
is( $text, qq|This has a [<a href="http://the.earth.li/">usemod link</a>]|,
    "title found and used" );
#print "# $text\n";

$text = "This has a [http://the.earth.li/ broken usemod link";
$finder->find(\$text);
is( $text, qq|This has a [<a href="http://the.earth.li/">http://the.earth.li/</a> broken usemod link|,
    "title ignored when final square bracket missing" );
#print "# $text\n";

$text = "This has a http://the.earth.li/ broken usemod link]";
$finder->find(\$text);
is( $text, qq|This has a <a href="http://the.earth.li/">http://the.earth.li/</a> broken usemod link]|,
    "title ignored when first square bracket missing" );
#print "# $text\n";

$text = <<EOT;
http://the.earth.li/
http://www.pubs.com/
EOT
$finder->find(\$text);
like( $text, qr|<a href="http://www.pubs.com/">http://www.pubs.com/</a>|,
      "untitled URI following another untitled URI gets picked up correctly" );

$text = <<EOT;
http://the.earth.li/
[http://www.pubs.com/ foo]
EOT
$finder->find(\$text);
like( $text, qr|<a href="http://www.pubs.com/">foo</a>|,
      "titled URI following untitled URI gets picked up correctly" );

# Test alternative callbacks.
$finder = URI::Find::Delimited->new(
    callback => sub {
        my ($open, $close, $uri, $title, $whitespace) = @_;
	if ( $open && $close ) {
	    $title ||= $uri;
	    qq|<a href="$uri">$title</a>|;
	} else {
	    qq|<a href="$uri">$uri</a>$whitespace$title|;
	}
    }
);
$text = "This has a [http://the.earth.li/ usemod link]";
$finder->find(\$text);
is( $text, qq|This has a <a href="http://the.earth.li/">usemod link</a>|,
    "can override callback" );

# Test alternative delimiters.
$finder = URI::Find::Delimited->new( delimiter_re => [ '\{', '\}' ] );
$text = qq|A {http://the.earth.li/ titled link}|;
$finder->find(\$text);
is( $text, qq|A {<a href="http://the.earth.li/">titled link</a>}|,
    "can overrride the delimiters" );

# Test ignoring quoted URIs.
$finder = URI::Find::Delimited->new;
$text = qq|This has a <a href="http://the.earth.li/">link already embedded|;
$finder->find(\$text);
is( $text, qq|This has a <a href="<a href="http://the.earth.li/">http://the.earth.li/</a>">link already embedded|,
    "URIs in existing links picked up by default" );

$finder = URI::Find::Delimited->new( ignore_quoted => 0 );
$text = qq|This has a <a href="http://the.earth.li/">link already embedded|;
$finder->find(\$text);
is( $text, qq|This has a <a href="<a href="http://the.earth.li/">http://the.earth.li/</a>">link already embedded|,
    "...and when ignore_quoted is false" );

$finder = URI::Find::Delimited->new( ignore_quoted => 1 );
$text = qq|This has a <a href="http://the.earth.li/">link already embedded|;
$finder->find(\$text);
is( $text, qq|This has a <a href="http://the.earth.li/">link already embedded|,
    "...but not when ignore_quoted is true" );

# Bug CPAN RT #2245
$finder = URI::Find::Delimited->new;
$text = qq|style:font|;
$finder->find(\$text);
is( $text, "style:font",
    "random things with colons in not automatically assumed to be URIs" );

