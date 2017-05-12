This directory contains some sample Perl scripts.

- testCheckerParser.pl

  Uses XML::Checker::Parser to parse the file.

- testCheckDOM.pl

  Uses XML::DOM::Parser to build a DOM (no checking is done at parse time) 
  and then uses XML::Checker and the check() methods in XML::DOM to check the 
  XML::DOM::Document

- filterInsignifWS.pl

  Uses XML::Checker to determine which whitespace is insignificant and
  print the filtered document to stdout.

- testValParser.pl
 
  Uses XML::DOM::ValParser to create a DOM (while checking at parse time)

Try the different xml files in the t/ directory to see what errors are 
generated. (I still need to force some of the errors in the xml sample files.)
