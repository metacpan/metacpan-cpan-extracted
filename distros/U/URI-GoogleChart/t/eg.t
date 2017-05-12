#!perl -w

use strict;
use Test;
plan tests => 2;

use URI::GoogleChart;

my $outfile = "examples.html";
my $newfile = $outfile;
$newfile .= ".new" if -f $newfile;

open(my $fh, ">", $newfile) || die "Can't create $newfile: $!";
binmode($fh);
print $fh <<EOT;
<html>
<head>
  <title>URI::GoogleChart Examples</title>
  <style>
  body {
    margin: 20px 50px;
    background-color: #ddd;
    max-width: 700px;
    font-family: sans-serif;
  }
  div.eg {
    background-color: #eee;
    padding: 10px 20px;
    border: 1px solid #aaa;
    margin: 30px 0;
    -webkit-box-shadow: 5px 5px 5px #aaa;
  }
  .even {
    background-color: #edf5ff;
  }
  pre {
    margin: 0px;
    font-weight: bold;
  }
  .uri {
    font-size: x-small;
  }
  img {
    border: 1px solid #aaa;
    padding: 5px;
    margin: 15px 0;
  }
  </style>
</head>

<body>
<h1>URI::GoogleChart Examples</h1>

<p> This page shows Perl code snippets using the <a
href="http://search.cpan.org/dist/URI-GoogleChart">URI::GoogleChart</a> module
to generate chart URLs and the corresponding images that the <a
href="http://code.google.com/apis/chart/">Google Chart service</a> generate
from them.

</p>

EOT

chart("pie-3d", 250, 100,
    data => [60, 40],
    label => ["Hello", "World"],
);

chart("pie", 500, 150,
    data => [80, 20],
    color => ["yellow", "black"],
    label => ["Resembes Pack-man", "Does not resemble Pac-man"],
    background => "black",
    rotate => 35,
    margin => [0, 30, 10, 10],
);

chart("pie", 250, 200,
    data => [(1) x 12],
    rotate => -90,
    label => [1 .. 12],
    encoding => "s",
    background => "transparent",
);

chart("lines", 200, 125,
    data => [37,60,60,45,47,74,70,72,],
    range_show => "left",
    range_round => 1,
);

chart("sparklines", 200, 75,
    data => [27,25,60,31,25,39,25,31,26,28,80,28,27,31,27,29,26,35,70,25],
    range_round => 1,
);

chart("lxy", 250, 125,
    data => [
        [10,20,40,80,90,95,99],
	[20,30,40,50,60,70,80],
        [undef],
        [5,25,45,65,85],
    ],
    label => ["blue", "red"],
    color => [qw(3072F3 red)],
);

chart("lines", 400, 150,
    data => [
        { range => "a", v => [20, 21, 25, 25, 24, 21] },
	{ range => "b", v => [1.1, 1.1, 1.3, 1.1, 1.7, 1.9] },
    ],
    range => {
	a => { round => 1, show => "left" },
	b => { round => 1, show => "right" },
    },
    color => ["red", "blue"],
    label => ["Damage", "Profit"],
    chxl => "0:|Jan|Feb|Mar|Apr|May|Jun",
    chxt => "x",
);

chart("horizontal-stacked-bars", 200, 150,
    data => [
        [10,50,60,80,40],
	[50,60,100,40,20],
    ],
    color => [qw(3072F3 f00)],
    range_show => "bottom",
);

chart("vertical-grouped-bars", 320, 125,
    data => [
        [10,50,60,80,40],
	[50,60,100,40,20],
    ],
    chco => "3072F3,ff0000",
    range_show => "left",
);

chart("vertical-stacked-bars", 150, 120,
    data => [10, -10, -5, 30, 15, 5],
    chbh => "a",
    color => "gray",
    margin => 5,
    range_show => "left",
);

chart("vertical-stacked-bars", 150, 120,
    data => [-10, -10, -5, -25, -15, -5],
    chbh => "a",
    color => "gray",
    margin => 5,
    range_show => "left",
);

chart("venn", 200, 100,
    data => [100, 20, 20, 20, 20, 0, 0],
    color => ["red", "lime", "blue"],
    label => ["First", "Second", "Third"],
);

chart("gom", 125, 80,
    data => 80,
    label => 80,
    title => "Awsomness",
);

chart("usa", 200, 100);

chart("europe", 300, 150,
    color => ["white", "green", "red"],
    background => "EAF7FE", # water blue
    # nordic populations 
    chld => "NOSEDKFIIS",
    data => [4.5e6, 9e6, 5.3e6, 5.1e6, 307261],
);


print $fh <<EOT;

<p style="font-size: small;">Page generated with URI::GoogleChart v$URI::GoogleChart::VERSION</p>
</body>
</html>
EOT

ok(close($fh));

if ($newfile ne $outfile) {
    ok(file_content($newfile), file_content($outfile));
    unlink($newfile);
}
else {
    skip("Regenerating $outfile");
}

sub chart {
    my $uri = URI::GoogleChart->new(@_);

    (undef, undef, my $line) = caller;
    seek(DATA, 0, 0);
    <DATA> while --$line;
    my $src = <DATA>;
    unless ($src =~ /;$/) {
	while (<DATA>) {
	    $src .= $_;
	    last if /^\);/;
	}
    }
    $src =~ s/^chart/\$u = URI::GoogleChart->new/;
    $uri =~ s/&/&amp;/g;

    print $fh <<EOT
  <div class="eg">
    <pre class="src">$src</pre>
    <div><img src='$uri'></div>
    <span class="uri">$uri</span>
  </div>
EOT
}

sub file_content {
    my $filename = shift;
    open(my $fh, "<", $filename) || return undef;
    binmode($fh);
    return do { local $/; readline($fh) }
}

__END__
