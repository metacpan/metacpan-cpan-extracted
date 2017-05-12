use Test::More;

use Data::Dumper;

plan tests => 2;

use XHTML::Instrumented;

my $data = <<DATA;
<?xml version="1.0"?>
<!DOCTYPE image [
  <!ELEMENT image EMPTY>
  <!ATTLIST image height CDATA #REQUIRED>
  <!ATTLIST image width CDATA #REQUIRED>
]>
<image height="32" width="32"/>
DATA

eval {
    my $t = XHTML::Instrumented->new(name => \$data, type => '');

    my $output = $t->output(
        list => $t->loop(),
    );
};
like($@, qr/We don't do these here/, 'attlist');


$data = <<DATA;
<!DOCTYPE foo
  [
    <!NOTATION bar PUBLIC "qrs">
    <!ENTITY zinger PUBLIC "xyz" "abc" NDATA bar>
    <!ENTITY fran SYSTEM "fran-def">
    <!ENTITY zoe  SYSTEM "zoe.ent">
   ]>
<foo>
  First line in foo
  <boom>Fran is &fran; and Zoe is &zoe;</boom>
  <bar id="jack" stomp="jill">
  <?line-noise *&*&^&<< ?>
    1st line in bar
    <blah> 2nd line in bar </blah>
    3rd line in bar <!-- Isn't this a doozy -->
  </bar>
  <zap ref="zing" />
  This, '\240', would be a bad character in UTF-8.
  <![CDATA[
    This is a CDATA marked section.
  ]]>
</foo>
DATA

eval {
    my $t = XHTML::Instrumented->new(name => \$data, type => '');

    my $output = $t->output(
        list => $t->loop(),
    );
};
like($@, qr/Don't know how to handle Unparsed Data/, 'attlist');



