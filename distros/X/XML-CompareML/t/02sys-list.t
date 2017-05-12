#!/usr/bin/perl -w

use Test::More tests => 1;

use strict;

use XML::CompareML::HTML;
use IO::Scalar;

my $no_use_buffer = "";
my $file = IO::Scalar->new(\$no_use_buffer);
my $converter =
    XML::CompareML::HTML->new(
        'input_filename' => "t/files/scm-sys-list-1.xml",
        'output_handle' => $file,
        'data_dir' => "./extradata",
    );

my $buffer = "";
my $fh = IO::Scalar->new(\$buffer);
$converter->gen_systems_list(output_handle => $fh);

# TEST
is ($buffer,
    <<"EOF",
<li><a href="http://www.cvshome.org/">CVS</a></li>
<li><a href="http://subversion.tigris.org/">Subversion Version Control System</a></li>
<li><a href="http://bazaar-vcs.org/">Bazaar</a> by Canonical</li>
<li><a href="http://toobad.tld/">Not-Too-Bad</a> by MyCompany</li>
EOF
    "Checking that the systems' list is correct."
);

