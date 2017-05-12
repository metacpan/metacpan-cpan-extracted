
/* 
William A. Gale and Kenneth W. Church, "A Program for Aligning Sentence 
in Bilingual Corpora" in Susan Armstong ed. "Using Large Corpora", MIT
Press, 1994, p91-102.

with Michael D. Riley

The following code is the core of align. It is a C language program
that inputs two files, with one token (word) per line. The text files
contain a number of delimiter tokens: "hard" and "soft". The hard
regions (e.g. paragraphs) may not be changed, and there must be 
equal numbers of them in the two input files. The soft regions 
(e.g. sentences) may be deleted (1-0), inserted (0-1), contracted
(2-1), expanded (1-2) or merged (2-2) as necessary so that the
output ends up with the same number of soft regions. The program
generates two output files. The two output files contain an equal
number of soft regions, each on a line. If the -v command line 
option is included, each soft region is preceded by its probability
score. 
*/

/*
  Return -100*log probability that an English sentence of length
  len1 is a translation of a foreign sentence of length len2. The
  probability is based on two parameters, the mean and variance of
  number of foreign characters per English characters
*/
  mean=(len1+len2/c)/2;
  z=(c*len1-len2)/sqrt(s2*mean);

  /* Need to deal with both sides of the normal distribution */  
  if (z<0) z=-z;
  pd=2*(1-pnorm(z));

  pd=2*(1-pnorm(z));
  if (pd>0) return((int)(-100*log(pd)));
