#!/bin/csh

# call a program to align files

if ($#argv != 2) then
   echo "usage: $0  <directory align> <directory text>"
   exit 0
endif

foreach file ($1/*.align)
    set name = $file:t
    set english = $name:s/align/e/
    set chinese = $name:s/align/c/
    $GMApath/util/align.pl $file $2/$chinese $2/$english 
end 
