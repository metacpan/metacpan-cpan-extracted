#!/usr/bin/perl
use XML::DT ;
use Test::More tests => 8;
my $filename = "t/05_input.xml";

####

%h1=('-default'   => sub{"<$q></$q>"});
$str = dt($filename,%h1);
$str =~ s/\s//g;
is($str, "<a></a>");

####

%h2=('c' => sub{ "<$q></$q>" },
     '-default'   => sub{"<$q>$c</$q>"});
$str = dt($filename,%h2);
$str =~ s/\s//g;
is($str, "<a><b><c></c><c></c></b><b><c></c><c></c></b><b><c></c><c></c></b></a>");

####

%h3=('-default'   => sub{"$q:$c"});
$str = dt($filename,%h3);
$str =~ s/\s//g;
is($str, "a:b:c:aeiouc:aeioub:c:aeiouc:aeioub:c:aeiouc:aeiou");

####

%h4=(c => sub{ $v{title} },
     '-default'   => sub{ 
	$v{title} ||="";
        "$v{title}$c" });
$str = dt($filename,%h4);
$str =~ s/\s//g;
is($str, "zbrzbr");

###

# Isto não é portável!!!!!
#
# %h5=(-default=>sub{toxml});
# $str = dt($filename, %h5);
# is(`tail -14 t/05_input.xml`,$str);

###

$str = dtstring("<foo></foo>", -declr => 1);
is("<?xml version=\"1.0\"?>\n<foo/>",$str);

###

{
  no utf8;

  # use Encode;

  # for my $straux ("<encoding>áéíóú</encoding>",
  # qq{<encoding v="josé">áéíç</encoding>}) {
  # $str = dtstring($straux, -inputenc=>'ISO-8859-1');
  # is(decode("iso-8859-1",$str),$straux);
  # }

  ###

  for my $straux ("<encoding>áéíóú</encoding>",
		  qq{<encoding v="josé">áéíóú</encoding>},
		  "<encoding>çÇãÃ</encoding>") {
    $str = dtstring($straux, -outputenc=>'ISO-8859-1', -inputenc=>'ISO-8859-1');
    is($str,$straux);
  }

}
