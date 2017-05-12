#!/usr/bin/perl

# This code used to generate a memory error in valgrind/etc.
# Testing it.

use strict;
use warnings;

use Test::XML::Ordered qw(is_xml_ordered);

use Test::More tests => 4;

my @common = (validation => 0, load_ext_dtd => 0, no_network => 1);

{
    my $xml_source = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/">
  <head>
    <title>David vs. Goliath - Part I</title>
  </head>
  <body>
    <div class="fiction story" xml:id="index">
      <h1>David vs. Goliath - Part I</h1>
      <div class="fiction section" xml:id="top">
        <h2>The Top Section</h2>
        <p>
    King David and Goliath were standing by each other.
    </p>
        <p>
    David said unto Goliath: "I will shoot you. I <b>swear</b> I will"
    </p>
        <div class="fiction section" xml:id="goliath">
          <h3>Goliath's Response</h3>
          <p>
    Goliath was not amused.
    </p>
          <p>
    He said to David: "Oh, really. <i>David</i>, the red-headed!".
    </p>
          <p>
    David started listing Goliath's disadvantages:
    </p>
        </div>
      </div>
    </div>
  </body>
</html>
EOF

    my $final_source = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/">
  <head>
    <title>David vs. Goliath - Part I</title>
  </head>
  <body>
    <div class="fiction story" xml:id="index">
      <h1>David vs. Goliath - Part I</h1>
      <div class="fiction section" xml:id="top">
        <h2>The Top Section</h2>
        <p>
    King David and Goliath were standing by each other.
    </p>
        <p>
    David said unto Goliath: "I will shoot you. I <b>swear</b> I will"
    </p>
        <div class="fiction section" xml:id="goliath">
          <h3>Goliath's Response</h3>
          <p>
    Goliath was not amused.
    </p>
          <p>
    He said to David: "Oh, really. <i>David</i>, the red-headed!".
    </p>
          <p>
    David started listing Goliath's disadvantages:
    </p>
        </div>
      </div>
    </div>
  </body>
</html>
EOF

    # TEST
    is_xml_ordered(
        [ string => $final_source, @common, ],
        [ string => $xml_source, @common, ],
        {},
        "XMLs are equivalent.",
    );

}

{
    my $xml_source = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<article xmlns="http://docbook.org/ns/docbook" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/" xmlns:db="http://docbook.org/ns/docbook" xmlns:xlink="http://www.w3.org/1999/xlink" xml:id="index" xml:lang="" version="5.0">
  <db:info>
    <db:title>David vs. Goliath - Part I</db:title>
  </db:info>
  <section xml:id="top">
    <db:info>
      <db:title>The Top Section</db:title>
    </db:info>
    <db:para>
        David and Goliath were standing by each other.
    </db:para>
    <db:para>
        David said unto Goliath: "I will shoot you."
    </db:para>
    <section xml:id="goliath">
      <db:info>
        <db:title>Goliath\'s Response</db:title>
      </db:info>
      <db:para>
    Goliath was not amused.
    </db:para>
      <db:para>
    He said to David: "Oh, really".
    </db:para>
    </section>
  </section>
</article>
EOF

    my $final_source = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<article xmlns="http://docbook.org/ns/docbook" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/" xmlns:xlink="http://www.w3.org/1999/xlink" xml:id="index" xml:lang="" version="5.0">
  <info>
    <title>David vs. Goliath - Part I</title>
  </info>
  <section xml:id="top">
    <info>
      <title>The Top Section</title>
    </info>
    <para>
        David and Goliath were standing by each other.
    </para>
    <para>
        David said unto Goliath: "I will shoot you."
    </para>
    <section xml:id="goliath">
      <info>
        <title>Goliath\'s Response</title>
      </info>
      <para>
    Goliath was not amused.
    </para>
      <para>
    He said to David: "Oh, really".
    </para>
    </section>
  </section>
</article>
EOF

    # TEST
    is_xml_ordered(
        [ string => $final_source, @common, ],
        [ string => $xml_source, @common, ],
        {},
        "<info /> and <db:info /> where xmlns:db == xmlns",
    );

}

{
    my $xml_source = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<document xmlns="http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/"><head></head><body id="index"><scene id="top"><scene id="david_and_goliath"><description><para>David and <ulink url="http://en.wikipedia.org/wiki/Goliath">Goliath</ulink> are
standing by each other.</para></description><saying character="David"><para>I will kill you.
</para></saying><saying character="Goliath"><para>no way, you little idiot!
</para></saying><saying character="David"><para>yes way!
</para><para>In the name of <ulink url="http://real-allah.tld/">Allah, the
<italics>merciful</italics>, real merciful</ulink>, I will show you the power of my sling.
</para><para>I shall sling you and bing you till infinity.
</para></saying><description><para>David takes his sling. <image url="sling.png" alt="a sling" title="Photo of David’s sling."></image> . </para></description><saying character="Goliath"><para>I'm still <ulink url="http://wait.tld/">waiting</ulink>.
</para></saying><saying character="David"><para>so you are.
</para></saying><description><para>David puts a stone in his sling and shoots Goliath. He hits.</para></description></scene></scene></body></document>
EOF

    my $final_source = <<'EOF';
<?xml version='1.0' encoding='utf-8'?>
<document xmlns="http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/">
    <head>
    </head>
    <body id="index">
<scene id="top">
    <scene id="david_and_goliath">
        <description>
            <para>
                David and
                <ulink url="http://en.wikipedia.org/wiki/Goliath">Goliath</ulink>
                are standing by each other.
            </para>
        </description>
        <saying character="David">
            <para>
                I will kill you.
            </para>
        </saying>
        <saying character="Goliath">
            <para>
                no way, you little idiot!
            </para>
        </saying>
        <saying character="David">
            <para>
                yes way!
            </para>
            <para>
                In the name of <ulink url="http://real-allah.tld/">Allah, the <italics>merciful</italics>, real merciful</ulink>, I will show you the power
                of my sling.
            </para>
            <para>
                I shall sling you and bing you till infinity.
            </para>
        </saying>
        <description>
            <para>
                David takes his sling. <image url="sling.png" alt="a sling" title="Photo of David’s sling."/> .
            </para>
        </description>
    <saying character="Goliath">
        <para>
            I'm still <ulink url="http://wait.tld/">waiting</ulink>.
        </para>
    </saying>
    <saying character="David">
        <para>
            so you are.
        </para>
    </saying>
    <description>
        <para>
            David puts a stone in his sling and shoots Goliath. He hits.
        </para>
    </description>
</scene>
</scene>
</body>
</document>
EOF

    # TEST
    is_xml_ordered(
        [ string => $final_source, @common, ],
        [ string => $xml_source, @common, ],
        {},
        "<image /> with empty tag",
    );

}

# TEST
ok (1, "Finished");
