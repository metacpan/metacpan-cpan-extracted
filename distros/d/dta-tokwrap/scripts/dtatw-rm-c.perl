#!/usr/bin/perl -w

while (<>) {
  #s|^\s+||g;			      ##-- remove whitespace at BOL
  s|<c> </c>||g;	  	      ##-- remove id-less whitespace <c> tags inserted by dtatw-add-c.perl (original whitespace is retained in following text node)
  s|\s*<c\s[^>]*>(.*)</c>\s*|$1|sg;   ##-- remove whitespace following OCR <c> tags
  s|</?c\b[^>]*>||g;	  	      ##-- remove all remaining <c> tags (but keep content)
  #s|(</[ws]>)\s*$|$1 |g;	      ##-- add non-newline after //w|s
  print;
}
