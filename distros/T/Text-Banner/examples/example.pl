#!/usr/local/bin/perl
#
# $Id: example.pl,v 1.1.1.1 1999/12/19 18:19:41 stuart Exp $
#
use Text::Banner;

$obj=Text::Banner->new;
$newsize=1; $neworient="h";

while (1) {
   undef $create; undef $fill; undef $orient;

   print "\nCURRENT ";
   print "Orientation: '",$obj->rotate,"' ";
   print "Fill char: '",$obj->fill,"' ";
   print "Size: ",$obj->size,"\n\n";
   
   print "Enter a string (Null value exits program): ";
   chop($create=<STDIN>);
   exit 0 unless $create;
   $obj->set($create);

   print "Size (1-5): ";
   chop ($size=<STDIN>);
   $size=$newsize unless $size;
   if ($size<1 || $size >5) {
      print "  -> Invalid size, must be between 1 and 5 - defaulting to 1.\n";
      $newsize=1;
   } else {
      $newsize=$size;
   }
   $obj->size($newsize);

   print "Fill character (use 'reset' to restore default behavior): ";
   chop ($fill=<STDIN>);
   $obj->fill($fill);

   print "(H)orizontal or (V)ertical: ";
   chop ($orient=<STDIN>);
   $orient=$neworient unless $orient;
   unless ($orient=~/^h|v/i) {
      print "  -> Orientation can only be horizontal or vertical. Defaulting to horizontal.\n";
      $orient="H";
   }
   $neworient=$orient;
   $obj->rotate($neworient);

   print "Hit <ENTER> or <RETURN> to display output banner:\n";
   $_=<STDIN>;

   print $obj->get,"\n";
}
