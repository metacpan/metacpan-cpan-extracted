#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;

use XML::SemanticDiff;

$SIG{__WARN__} = sub { die $_[0]; };

my $xml1 = <<'EOX';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE
    html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
<head>
<title>Create a Great Personal Home Site</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
<h2 id="books">Books</h2>
<p>
These are my books.
</p>
<h3 id="fiction_books">Fiction books</h3>

<div class="prod">
<div class="head">
<p class="prod_img">
<a href="http://www.amazon.com/exec/obidos/ASIN/06903459409/ref=nosim/shlomifishhom-20/"><img src="images/little_women.jpg" alt="Preview" /></a>
</p>
<p class="prod_title">
<a href="http://www.amazon.com/exec/obidos/ASIN/06903459409/ref=nosim/shlomifishhom-20/">Little Women</a>
</p>
</div>
<div class="desc">
<p>
Little Women by Louisa May Alcott.
</p>
</div>
</div>

<h3 id="computer_books">Computer books</h3>
</body>
</html>
EOX

my $xml2 = <<'EOX';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
  <head>
    <title>Create a Great Personal Home Site</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  </head>
  <body>
    <h2 id="books">Books</h2>
    <p>
                    These are my books.
                </p>
    <h3 id="fiction_books">Fiction books</h3>
    <div class="prod">
      <div class="head">
        <p class="prod_img">
          <a href="http://www.amazon.com/exec/obidos/ASIN/06903459409/ref=nosim/shlomifishhom-20/">
            <img alt="Preview" src="images/little_women.jpg"/>
          </a>
        </p>
        <p class="prod_title">
          <a href="http://www.amazon.com/exec/obidos/ASIN/06903459409/ref=nosim/shlomifishhom-20/">Little Women</a>
        </p>
      </div>
      <div class="desc">
        <p>
                            Little Women by Louisa May Alcott.
                        </p>
      </div>
    </div>
    <h3 id="computer_books">Computer books</h3>
  </body>
</html>
EOX

my $diff = XML::SemanticDiff->new();

my @results=(qw(Humpty Dumpty sat on a wall));
eval {
@results = $diff->compare($xml1, $xml2);
};

# TEST
is ($@, "", "No exception was thrown");
# TEST
ok ((@results == 0), "XML is OK.");



