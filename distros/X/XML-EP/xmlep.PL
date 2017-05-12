# -*- perl -*-

my $script = <<'END_OF_SCRIPT';
~startperl~

use strict;
use XML::EP ();
use XML::EP::Request::CGI ();

my $ep = XML::EP->new();
my $request = XML::EP::Request::CGI->new(@ARGV);
$ep->Handle($request);


if ($@) {
    print("content-type: text/html\n\n",
	  "<html><head><title>Internal error</title></head>\n",
	  "<body bgcolor=\"#ffffff\"><h1>Internal error</h1>\n",
	  "<p>An internal error occurred and a Perl exception was thrown.\n",
	  "The error message is:</p><pre>\n",
	  $@, "\n</pre></body></html>\n");
}


exit 0;
END_OF_SCRIPT

use Config();

$script =~ s/\~(\w+)\~/$Config::Config{$1}/sg;
(open(FILE, ">xmlep") and (print FILE $script) and close(FILE))
    || die "Failed to open output file: $!";
