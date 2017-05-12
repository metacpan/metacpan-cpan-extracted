# -*- perl -*-

BEGIN { $| = 1; print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}

use Tk::Getopt;
use vars qw(%xrange $yrange $func $c_width $c_height $file $datastyle
	    $overlay $lang $grid $precision $seperator
	    $opt %options);
$loaded = 1;

@ARGV = qw(--xfrom=12 -xto 13 -overlay --nogrid --codetest);


%options = ("xfrom=f" => \$xrange{from},
	    "yfrom=f" => \$yrange{from},
	    "xto=f"   => \$xrange{to},
	    "yto=f"   => \$yrange{to},
	    "func=s"  => \$func,
	    "width=i" => \$c_width,
	    "height=i" => \$c_height,
	    "file=s"  => \$file,
	    "datastyle=s" => \$datastyle,
	    "overlay" => \$overlay,
	    "lang=s"  => \$lang,
	    "grid!"    => \$grid,
	    "precision=f" => \$precision,
	    "debug"   => \$^W,
	    "seperator=s" => \$seperator,
	    "xcodetest" => sub { print "not ok 1\n" },
	    "codetest" => sub { print "ok 1\n" },
	   );

$opt = new Tk::Getopt(-getopt => \%options);

if (!$opt->get_options) {
    die $opt->usage;
}

$opt->process_options;

print( ($xrange{from} != 12 ? "not " : "") . "ok 2\n");
print( ($xrange{to} != 13 ? "not " : "") . "ok 3\n");
print( ($overlay != 1 ? "not " : "") . "ok 4\n");
print( ($grid != 0 ? "not " : "") . "ok 5\n");

