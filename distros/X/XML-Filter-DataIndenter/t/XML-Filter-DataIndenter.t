use Test;
use XML::Filter::DataIndenter;
use XML::SAX::PurePerl;
use XML::SAX::Writer;
use Test::Differences;

use strict;

my $out;

my $w = XML::SAX::Writer->new( Output => \$out );

my $f = XML::Filter::DataIndenter->new(
    Handler => $w,
);

my $p = XML::SAX::PurePerl->new( Handler => $f );

my $s1 = <<'XML_END';
<a><?A?>
<!--A--><b><?B?><!--B-->B</b>
    <!--A-->
       </a>
XML_END

my $e1 = <<'XML_END';
<a>
  <?A?>
  <!--A-->
  <b><?B?><!--B-->B</b>
  <!--A-->
</a>
XML_END

my @tests = (
sub {
    $p->parse_string( $s1 );
    $out =~ s/\s+(\??>)/$1/g;
    1 while chomp $out;
    1 while chomp $e1;
    eq_or_diff $out, $e1;
},

sub {
    eval { $p->parse_string( "<a>a<b/></a>" ) };
    ok $@;
},

sub {
    eval { $p->parse_string( "<a><b/>a</a>" ) };
    ok $@;
},

sub {
    eval { $p->parse_string( "<a><b>a</a>" ) };
    ok $@;
},

sub {
    eval { $p->parse_string( "<a>" ) };
    ok $@;
},

);

plan tests => 0+@tests;

$_->() for @tests;
