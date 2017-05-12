#  Copyright 2000-2004  The Apache Software Foundation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use Apache::Request ();

my $r = shift;
my $apr = Apache::Request->new($r);
$apr->no_cache(1);
$apr->send_http_header('text/html');

my $title = "File Upload Example";
print <<EOF;
<HTML>
<HEAD><TITLE>$title</TITLE></HEAD>
<BODY>
<h1>$title</h1>
EOF

my @types = ('count lines', 'count words', 'count characters');

print <<EOF;
<FORM METHOD="POST"  ENCTYPE="multipart/form-data">
Enter the file to process:
<INPUT TYPE="file" NAME="filename" SIZE=45><BR>
<INPUT TYPE="checkbox" NAME="count" VALUE="count lines">count lines
<INPUT TYPE="checkbox" NAME="count" VALUE="count words">count words
<INPUT TYPE="checkbox" NAME="count" VALUE="count characters">count characters
<P><INPUT TYPE="reset">
<INPUT TYPE="submit" NAME="submit" VALUE="Process File">
</FORM>
EOF

# Process the form if there is a file name entered
if (my $upload = $apr->upload) {
    my $type = $upload->type;
    my $name = $upload->name;
    my $filename = $upload->filename;
    my $fh = $upload->fh;
    my $size = $upload->size;

    unless ($filename) {
	print "no file specified";
	return;
    }

    print <<EOF;
<hr>
<h2>$name</h2>
<h3>$filename ($size bytes)</h3>
<h4>MIME Type: $type</h4>
EOF
    my %stats;
    my($lines, $words, $characters, @words) = (0,0,0,0);
    while (<$fh>) {
	$lines++;
	$words += @words = split /\s+/;
	$characters += length $_;
    }
    close $fh;
    for ($apr->param('count')) {
	$stats{$_}++;
    } 

    if (%stats) {
	print "Lines: $lines<br>\n" if $stats{'count lines'};
	print "Words: $words<br>\n" if $stats{'count words'};
	print "Characters: $characters<br>\n" if $stats{'count characters'};
    } 
    else {
	print "No statistics selected.\n";
    }
}
print "</BODY></HTML>";
