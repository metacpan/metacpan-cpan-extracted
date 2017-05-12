#!/usr/bin/perl -w
open(MY_FILE,"test") or die ("Can't open file.");
while( <MY_FILE> ) {
print if 1 .. 3; #print the first 5 lines of the file
}
close(MY_FILE);

