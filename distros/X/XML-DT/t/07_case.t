#!/usr/bin/perl
use XML::DT ;
use Test::More tests => 8;
my $filename = "t/07_case.xml";

####

%h1=('-default'   => sub{"<$q></$q>"});
$str = dt($filename,%h1);
$str =~ s/\s//g;
is($str, "<A></A>");


%h1=('-ignorecase' => 1,
     '-default'    => sub{"<$q></$q>"});
$str = dt($filename,%h1);
$str =~ s/\s//g;
is($str, "<a></a>");

####

%h2=('c' => sub{ "<$q></$q>" },
     '-default'   => sub{"<$q>$c</$q>"});
$str = dt($filename,%h2);
$str =~ s/\s//g;
is($str, "<A><b><c></c><c></c></b><b><C>aeiou</C><c></c></b><b><c></c><c></c></b></A>");


%h2=('c' => sub{ "<$q></$q>" },
     '-ignorecase' => 1,
     '-default'   => sub{"<$q>$c</$q>"});
$str = dt($filename,%h2);
$str =~ s/\s//g;
is($str, "<a><b><c></c><c></c></b><b><c></c><c></c></b><b><c></c><c></c></b></a>");

####

%h3=('-ignorecase' => 1,
     '-default'   => sub{"$q:$c"});
$str = dt($filename,%h3);
$str =~ s/\s//g;
is($str, "a:b:c:aeiouc:aeioub:c:aeiouc:aeioub:c:aeiouc:aeiou");


%h3=('-default'   => sub{"$q:$c"});
$str = dt($filename,%h3);
$str =~ s/\s//g;
is($str, "A:b:c:aeiouc:aeioub:C:aeiouc:aeioub:c:aeiouc:aeiou");

####

%h4=('-ignorecase' => 1,
     c => sub{ $v{title} },
     '-default'   => sub{ 
	$v{title} ||="";
        "$v{title}$c" });
$str = dt($filename,%h4);
$str =~ s/\s//g;
is($str, "zbrzbr");


%h4=(c => sub{ $v{title} },
     '-default'   => sub{ 
	$v{title} ||="";
        "$v{title}$c" });
$str = dt($filename,%h4);
$str =~ s/\s//g;
is($str, "zbraeiou");


