This directory contains some sample Perl scripts.

- xql.pl

  This script will be installed in your perl/bin directory. It is a nice
  utility that allows you to grep XML files using XQL expressions on the
  command line. Run xql.pl without any arguments to see the USAGE message.

Run the other scripts as follows (after installing the perl modules in this 
distribution). They should print out errors, warnings and info messages
to STDERR.

	perl script.pl file.xml

- pretty.pl

  Uses XML::Filter::Reindent and XML::Handler::Composer to 
  pretty print your XML file.
  These classes need some work so don't expect too much...

- testCheckerParser.pl

  Uses XML::Checker::Parser to parse the file.

- testCheckDOM.pl

  Uses XML::DOM::Parser to build a DOM (no checking is done at parse time) 
  and then uses XML::Checker and the check() methods in XML::DOM to check the 
  XML::DOM::Document

- testValParser.pl

  Uses XML::DOM::ValParser to create a DOM (while checking at parse time)

- filterInsignifWS.pl

  Uses XML::Checker to determine which whitespace is insignificant and
  print the filtered document to stdout.

Try the different xml files in the t/ directory to see what errors are 
generated. (I still need to force some of the errors in the xml sample files.)
