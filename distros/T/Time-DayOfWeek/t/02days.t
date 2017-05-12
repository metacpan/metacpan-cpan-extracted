use Test;use Time::DayOfWeek qw(:all);
my $rslt;my $fldz;my $tnum = 1;our $lded = 1;my $tvrb = 0;my $tsts = 8;
END { print "not " unless($lded);print "ok $tsts\n";}
plan('tests' => $tsts); &rprt(1);
sub rprt{ # prints a RePoRT of test progress
  my $badd = !shift();
  print 'not ' if($badd);
  print "ok ", $tnum++, "\n";
  print @_ if(($ENV{'TEST_VERBOSE'} || $tvrb) && $badd);}
$rslt = DoW(         2003, 12, 7);
&rprt($rslt ==          0, "$rslt\n");
$rslt = Dow(         2003, 12, 7);
&rprt($rslt eq 'Sun'     , "$rslt\n");
$rslt = DayOfWeek(   2003, 12, 7);
&rprt($rslt eq 'Sunday'  , "$rslt\n");
$rslt = DoW(         2004,  1, 1);
&rprt($rslt ==          4, "$rslt\n");
$rslt = Dow(         2004,  1, 1);
&rprt($rslt eq 'Thu'     , "$rslt\n");
DayNames('Domingo', 'Lunes',  'Martes',  'Miercoles', 'Jueves', 'Viernes', 'Sabado');
$rslt = Dow(         2003, 12, 13);
&rprt($rslt eq 'Sab'     , "$rslt\n");
