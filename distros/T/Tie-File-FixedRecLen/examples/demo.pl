#!/usr/bin/perl

# for typical read/write random access...

use Tie::File::FixedRecLen;
  
tie @array, 'Tie::File::FixedRecLen', $file, record_length => 20;

