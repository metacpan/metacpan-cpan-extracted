use Test::More tests => 81;

use XML::Parser::LiteCopy;
use Data::Dumper;

my($s, $c, $e, $a);


#
# start, char, end
#

($s, $c, $e) = (0) x 3;
my $p1 = XML::Parser::LiteCopy->new();
$p1->setHandlers(
    Start => sub { $s++; },
    Char => sub { $c++; },
    End => sub { $e++; },
);
$p1->parse('<foo>Hello World!</foo>');

is($s, 1);
is($c, 1);
is($e, 1);


#
# attributes from start event
#

($s, $c, $e) = (0) x 3;
my %foo;
my $p2 = new XML::Parser::LiteCopy
  Handlers => {
    Start => sub { shift; $s++; %foo = @_[1..$#_] if $_[0] eq 'foo'; },
    Char => sub { $c++; },
    End => sub { $e++; },
  }
;

$p2->parse('<foo id="me" root="0" empty="">Hello <bar>cruel</bar> <foobar/> World!</foo>');
is($s, 3);
is($c, 4);
is($e, 3);
is($foo{id}, 'me');
ok(defined $foo{root});
is($foo{root}, '0');
ok(defined $foo{empty});
is($foo{empty}, '');


#
# Char & CDATA
#

sub test_chars {
  my @chars;
  my $p = new XML::Parser::LiteCopy
    Handlers => {
      Char => sub { push @chars, $_[1]; },
      CData => sub { push @chars, 'CDATA:'.$_[1]; },
    }
  ;
  my $in = shift;
  $p->parse($in);
  is(scalar @chars, scalar @_);
  is_deeply(\@chars, \@_);
}

&test_chars('<foo />', ());
&test_chars('<foo></foo>', ());
&test_chars('<foo>hey</foo>', ('hey'));
&test_chars('<foo>hey&lt;</foo>', ('hey&lt;'));
&test_chars('<foo>&amp;hey</foo>', ('&amp;hey'));

&test_chars('<foo><![CDATA[yo]]></foo>', ('CDATA:yo'));
&test_chars('<foo><![CDATA[ yo ]]></foo>', ('CDATA: yo '));
&test_chars('<foo><![CDATA[foo]bar]]></foo>', ('CDATA:foo]bar'));
&test_chars('<foo><![CDATA[foo]]bar]]></foo>', ('CDATA:foo]]bar'));
&test_chars('<foo><![CDATA[foo]>bar]]></foo>', ('CDATA:foo]>bar'));
&test_chars('<foo><![CDATA[foo]]]></foo>', ('CDATA:foo]'));

&test_chars('<foo>woo<![CDATA[foo]]><![CDATA[bar]]>yay</foo>', ('woo','CDATA:foo','CDATA:bar','yay'));


#
# comments
#

sub test_comments {
  my @comments;
  my $p = new XML::Parser::LiteCopy
    Handlers => {
      Comment => sub { push @comments, $_[1]; },
    }
  ;
  my $in = shift;
  $p->parse($in);
  is(scalar @comments, scalar @_);
  is_deeply(\@comments, \@_);
}

# >>> A note about comments:
# An XML comment opens with a "<!--" delimiter and generally closes with the first subsequent
# occurrence of the closing "-->" delimiter. An explicitly stated exception is that a double
# hyphen is not permitted within the body of a comment. This rule ensures that unterminated
# comments are detected if a new comment opening delimiter is encountered. There is an
# additional restriction that comments cannot be terminated with the "--->" sequence, that is,
# that the body of the comment cannot terminate with a hyphen

&test_comments('<foo></foo>', ());
&test_comments('<foo><!--a--></foo>', ('a'));
&test_comments('<foo><!-- b --></foo>', (' b '));
&test_comments('<foo><!-- c-d --></foo>', (' c-d '));
&test_comments('<foo><!-- e- --></foo>', (' e- '));
&test_comments('<foo><!-- - --></foo>', (' - '));
&test_comments('<foo><!--fg--></foo><!--h-->', ('fg','h'));
&test_comments('<foo><!--i-j--></foo>', ('i-j'));


#
# processing instructions (PI)
#

sub test_pi {
  my @instructions;
  my $p = new XML::Parser::LiteCopy
    Handlers => {
      PI => sub { push @instructions, $_[1]; },
    }
  ;
  my $in = shift;
  $p->parse($in);
  is(scalar @instructions, scalar @_);
  is_deeply(\@instructions, \@_);
}

&test_pi('<foo />', ());
&test_pi('<?name pidata?><foo />', ('name pidata'));
&test_pi('<?xml version="1.0"? encoding="UTF-8"?><foo/>', ('xml version="1.0"? encoding="UTF-8"'));
&test_pi(qq|<bar><?php\nexit;\n?></bar>|, (qq|php\nexit;\n|));
&test_pi('<?yay woo??><foo />', ('yay woo?')); # technically allowed...


#
# error conditions
#

sub test_error {
  my @errors;
  my $p = new XML::Parser::LiteCopy
    Handlers => {
      Error => sub { push @errors, $_[1]; },
    },
    ReturnErrors => 1
  ;
  my $in = shift;
  $p->parse($in);

  # first test method gets a list of errors from the Error() event handler
  is(scalar @errors, scalar @_);
  for my $i(0..scalar @_-1){
    like($errors[$i], $_[$i]);
  }

  # and then we check it dies correctly
  my $p2 = new XML::Parser::LiteCopy;
  eval { $p2->parse($in); };

  like($@, $_[0]);
}

&test_error('foo<foo id="me">Hello World!</foo>', qr/^junk .+ before/);
&test_error('<foo id="me">Hello World!</foo>bar', qr/^junk .+ after/);
&test_error('<foo id="me">Hello World!', qr/^not properly closed tag 'foo'/);
&test_error('<foo id="me">Hello World!<bar></foo></bar>', qr/^mismatched tag 'foo'/, qr/^mismatched tag 'bar'/);
&test_error('<foo id="me">Hello World!</foo><bar></bar>', qr/^multiple roots, wrong element 'bar'/, qr/^unexpected closing tag 'bar'/);
&test_error('  ', qr/^no element found/);

# TODO tests
# check for unclosed PI: $p2->parse('<?pi<foo></foo>');
# check for unclosed CDATA
# check for bad doctype
# check for bad comments (various kinds)
