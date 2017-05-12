use strict;
use Tk;
use Tk::XMLViewer;
use XML::Parser;
use FindBin;
use Getopt::Long;
use Test::More;

my $demo = 0;
GetOptions("demo!" => \$demo) or die "usage!";

my $use_unicode = ($Tk::VERSION >= 803); # unicode enabled
my $file;
if ($use_unicode) {
    $file = "$FindBin::RealBin/testutf8.xml";
} else {
    $file = "$FindBin::RealBin/test.xml";
}

my $top = eval { new MainWindow };

if (!$top) {
    plan skip_all => $@;
    exit 0;
}

plan tests => 18;

my $t2 = $top->Toplevel;
$t2->withdraw;

my $xmlwidget = $top->Scrolled('XMLViewer',
			       -tagcolor => 'blue',
			       -scrollbars => "osoe")->pack;
ok($xmlwidget, "Got a widget");
isa_ok($xmlwidget->Subwidget("scrolled"), "Tk::XMLViewer");

$xmlwidget->tagConfigure('xml_comment', -foreground => "white",
			 -background => "red", -font => "Helvetica 15");

eval { $xmlwidget->insertXML(-file => $file) };
is($@, '', "Inserted XML file '$file'");
eval { $xmlwidget->XMLMenu };
is($@, '', 'Created XMLMenu');

my $xml_string1 = $xmlwidget->DumpXML;
isnt($xml_string1, '', 'XML content dumped from widget');

my $xmlwidget2 = $t2->XMLViewer->pack;
isa_ok($xmlwidget2, 'Tk::XMLViewer');

$xmlwidget2->insertXML(-text => <<EOF);
<?xml version="1.0" encoding="ISO-8859-1" ?>
<!DOCTYPE ecollateral SYSTEM "test.dtd">
<book title="test">
</book>
EOF
$xmlwidget2->destroy;

# test internals

$xmlwidget->ShowHideRegion(1, -open => 0);
pass("Closed region");
$xmlwidget->ShowHideRegion(1, -open => 1);
pass("Opened region");
$xmlwidget->OpenCloseDepth(1, 0);
pass("OpenCloseDepth 0");
$xmlwidget->OpenCloseDepth(1, 1);
pass("OpenCloseDepth 1");
$xmlwidget->ShowToDepth(0);
pass("ShowToDepth 0");
$xmlwidget->ShowToDepth(undef);
pass("ShowToDepth all");
ok(defined &Tk::XMLViewer::_convert_from_unicode, "Has unicode converted defined");

my %info = %{ $xmlwidget->GetInfo };
is($info{Version}, "1.0", "Info: version OK");
if ($use_unicode) {
    is($info{Encoding}, "utf-8", "Info: encoding OK");
} else {
    is($info{Encoding}, "ISO-8859-1", "Info: encoding OK");
}
is($info{Name}, "ecollateral", "Info: name Ok");
is($info{Sysid}, "test.dtd", "Info: dtd Ok");

# definitions for interactive use...

$top->bind("<P>" => sub {
    require Config;
    my $perldir = $Config::Config{'scriptdir'};
    require "$perldir/ptksh";
});

my $depth=10;
my $f=$top->Frame->pack;
$f->Label(-text => "Depth",
	 #  -command => sub {
	 #      $xmlwidget->ShowToDepth($depth);
	 #  }
	 )->pack(-side => "left");
$f->Scale(-variable => \$depth,
	  -from => 1,
	  -command => sub {
	      $xmlwidget->ShowToDepth($depth);
	  },
	  -to => 10,
	  -orient => 'horiz')->pack(-side => "left");
$f->Button(-text => "Dump Tk::Text as XML",
	   -command => sub {
	       my $s = $xmlwidget->DumpXML;
	       #warn $s;
	       my $t = $top->Toplevel;
	       my $xmlwidget2 = $t->Scrolled('XMLViewer',
					     -scrollbars => "osoe")->pack;
	       $xmlwidget2->insertXML(-text => $s);
	       $xmlwidget2->XMLMenu;
	   })->pack(-side => "left");
my $not;
my $okb = $f->Button(-text => "OK",
		     -command => sub { $not = ""; })->pack(-side => "left");
$okb->focus;
$f->Button(-text => "Not OK",
	   -command => sub { $not = "not "; })->pack(-side => "left");

if (!$demo || $ENV{BATCH}) {
    $top->repeat(100, sub { $not = "" }); # repeat instead of after here
}

$top->update;
$top->waitVariable(\$not);

$t2->destroy;

#MainLoop;

is($not, "");
