#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More;

my $GEN_PLAN = "bin/webrobot-gen-plan";
my $prefix = 'http://erbse:6080/erp';

my @testplan =
    (
     ["Simple",
      "/tree.do",
      "GET $prefix/tree.do",
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
EOF
     ],

     ["Simple, Parameters",
      "/tree.do?id=17&a=AAAA",
      "GET $prefix/tree.do?id=17&a=AAAA",
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do?id=17&amp;a=AAAA"/>
      <description value="0"/>
EOF
     ],

     ["Simple, Parameters with special characters",
      q{/tree.do?id=17&a=<"'},
      qq{GET $prefix/tree.do?id=17&a=%3C%22%27},
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do?id=17&amp;a=%3C%22%27"/>
      <description value="0"/>
EOF
     ],

     ["GET, Parameters",
      "GET /tree.do?id=17&a=AAAA",
      "GET $prefix/tree.do?id=17&a=AAAA",
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do?id=17&amp;a=AAAA"/>
      <description value="0"/>
EOF
     ],

     ["GET, Parameters, encoding",
      "GET /tree.do?id=(first,second)&a=AAAA",
      "GET $prefix/tree.do?id=%28first%2Csecond%29&a=AAAA",
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do?id=%28first%2Csecond%29&amp;a=AAAA"/>
      <description value="0"/>
EOF
     ],

     ["GET, Parameters, umlaut",
      "GET /tree.do?id=הצü&a=AAAA",
      "GET $prefix/tree.do?id=%E4%F6%FC&a=AAAA",
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do?id=%E4%F6%FC&amp;a=AAAA"/>
      <description value="0"/>
EOF
     ],

     ["POST",
      "POST /tree.do id=17&a=AAAA",
      "POST $prefix/tree.do id=17&a=AAAA",
      <<EOF
      <method value="POST"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
      <data>
          <parm name="id" value="17"/>
          <parm name="a" value="AAAA"/>
      </data>
EOF
     ],

     ["POST, special parameters",
      q{POST /tree.do id=17&a=<"'},
      qq{POST $prefix/tree.do id=17&a=%3C%22%27},
      <<EOF
      <method value="POST"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
      <data>
          <parm name="id" value="17"/>
          <parm name="a" value="&lt;&quot;'"/>
      </data>
EOF
     ],

     ["POST, encoding",
      "POST /tree.do id=(first,second)&a=AAAA",
      "POST $prefix/tree.do id=%28first%2Csecond%29&a=AAAA",
      <<EOF
      <method value="POST"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
      <data>
          <parm name="id" value="(first,second)"/>
          <parm name="a" value="AAAA"/>
      </data>
EOF
     ],

     ["POST, umlaut",
      "POST /tree.do id=הצü&a=AAAA",
      "POST $prefix/tree.do id=%E4%F6%FC&a=AAAA",
      <<EOF
      <method value="POST"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
      <data>
          <parm name="id" value="הצü"/>
          <parm name="a" value="AAAA"/>
      </data>
EOF
     ],

     ["GET, Assert",
      "GET /tree.do text1 text2",
      "GET $prefix/tree.do text1 text2",
      <<EOF
      <method value="GET"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
      <assert>
          <status value="2"/>
          <regex value="text1"/>
          <regex value="text2"/>
      </assert>
EOF
     ],

     ["POST, Assert",
      "POST /tree.do name1=wert1&name2=wert2 text1 text2",
      "POST $prefix/tree.do name1=wert1&name2=wert2 text1 text2",
      <<EOF
      <method value="POST"/>
      <url value="http://erbse:6080/erp/tree.do"/>
      <description value="0"/>
      <data>
          <parm name="name1" value="wert1"/>
          <parm name="name2" value="wert2"/>
      </data>
      <assert>
          <status value="2"/>
          <regex value="text1"/>
          <regex value="text2"/>
      </assert>
EOF
     ],

    );

MAIN: {
    if ($^O eq "linux") {
        plan tests => 2 * scalar(@testplan);
        test_text(@$_) foreach (@testplan);
        test_xml(@$_) foreach (@testplan);
    }
    else {
        plan skip_all => "enabled on linux only because you need (sh, echo)";
    }
}


sub test_text {
    my ($title, $in, $expected, $xml_expected) = @_;
    (my $in_sh = $in) =~ s/'/'"'"'/g;
    my $got = `echo '$in_sh' | $GEN_PLAN -prefix='$prefix' -output=text -encode=url -encode=data -nodata`;
    chomp $got;
    is($got, $expected, $title);
}

sub test_xml {
    my ($title, $in, $expected, $xml_expected) = @_;
    (my $in_sh = $in) =~ s/'/'"'"'/g;
    my $got = `echo '$in_sh' | $GEN_PLAN -prefix='$prefix' -output=xml -encode=url -encode=data -nodata`;
    $xml_expected = <<EOS;
<?xml version="1.0" encoding="ISO-8859-1"?>
<plan>
<request>
<!-- $in -->
$xml_expected
</request>
</plan>
EOS
    ($got, $xml_expected) = norm($got, $xml_expected);
    is($got, $xml_expected, $title);
}

sub norm {
    foreach (@_) {
        s/^\s+//gm;
        s/\s+$//gm;
        s/\n+/\n/g;
    }
    return (@_>1) ? @_ : $_[0];
}

1;
