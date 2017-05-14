#! /usr/local/bin/perl

#showtime();
#TestFunc(1,2.555,"How U doin?");
#TestFuncHash(1,2.555,"A","How U doin?");

sub showtime
{
 print 	`date`; 
}

sub TestFunc
{
 my($a,$b,$c) = @_;

 print "A = $a\n";
 print "B = $b\n";
 print "C = $c\n";
 my(%Test) = ("A"=>$a,"B"=>$b,"C"=>$c);
 return (%Test);
 #return "Hai";
}

sub TestFuncHash
{
 my(%name) = @_;
 foreach $_ (keys(%name))
  {
   print "Hash:",$_,":","$name{$_}\n";
  }
  #Returning undefined values like this causes SEGV
  #my(%Test) = ("A",$NULL,"B",$NULL,"C",$NULL);
  my(%Test) = ("A",1,"B",2,"C",3);
  #my(%Test) = ("A","1","B","2","C","3");
  return (%Test);
}

sub TestFuncCA
{
 my(%name) = @_;
 foreach $_ (keys(%name))
  {
   print $_,":","$name{$_}\n";
  }
 return 100;
}

sub TestFuncAI 
{  
 foreach $_ (@_)
  {
   print $_,"\n";
  }
 return 100;
}

sub TestFuncI { 100 }
sub TestFuncD { 2.3332 }
sub TestFuncAS 
{ 
 print join(",",@_);
 my(@A) = ("Hi","This","is","a","test") ;
 return @A;
}
sub TestFuncAD
{ 
 my(@A) = (1.1,2.2,3.3) ;
 return @A;
}
