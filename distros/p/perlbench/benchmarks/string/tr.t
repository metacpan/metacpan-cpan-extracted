#!perl

# Name: Try the tr/// function
# Require: 4
# Desc:
#


require 'benchlib.pl';

@a = (0 .. 255);
for (@a) { $_ = sprintf("%c", $_) };
$a = join("",  @a);

&runtest(8, <<'ENDTEST');

   $a =~ tr/A-ZÀ-ÖØ-Þ/a-zà-öø-þ/;
   $a =~ tr/a-zà-öø-þ/A-ZÀ-ÖØ-Þ/;

   $a =~ tr/A-ZÀ-ÖØ-Þ/a-zà-öø-þ/;
   $a =~ tr/a-zà-öø-þ/A-ZÀ-ÖØ-Þ/;

ENDTEST
