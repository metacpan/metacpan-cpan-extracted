#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: gui.t,v 1.16 2008/02/08 22:29:04 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Data::Dumper;
	use Test::More;
	use Tk;
	1;
    }) {
	print "1..0 # skip: no Data::Dumper, Test::More and/or Tk modules\n";
	exit;
    }
}

plan tests => 5;

use_ok("Tk::Getopt");

my $top;
my $options = {};
my @opttable =
  (#'loading',
   ['adbfile', '=s', undef,
    {'alias' => ['f'],
     'help' => 'The default database file',
     'longhelp' => "This is an example for a longer help\nYou can use multiple lines\n",
     'subtype' => 'file',
    }],
   ['newfile', '=s', undef,
    {'help' => 'An option to specify a possible new file',
     'subtype' => 'savefile',
    }],
   ['exportfile', '=s', undef,
    {'choices' => ["/tmp/export.dat", "$ENV{HOME}/export.dat"],
     'subtype' => 'file'}],
   ['dumpfile', '=s', '/tmp/dump', {'subtype' => 'file'}],
   ['datadir', '=s', '/tmp', {'subtype' => 'dir'}],
   ['autoload', '!', 0,
    {'help' => 'Turns autoloading of the default database file on or off'}],

   'x11',
   ['', '', "X11 related options like colors and fonts.\nThis is named `X11', but is also relevant for other windowing systems."],
   ['bg', '=s', undef,
    {'callback' =>
     sub {
	 if ($options->{'bg'}) {
	     foreach (qw(background
			 backPageColor
			 highlightBackground)) {
		 $top->optionAdd("*$_" => $options->{'bg'}, 'userDefault');
	     }
	 }
     },
     'help' => 'Background color',
     'length' => 7,
     'maxsize' => 7,
     'subtype' => 'color',
    }],
   ['fg', '=s', undef,
    {'callback' =>
     sub {
	 $top->optionAdd("*foreground" => $options->{'fg'}, 'userDefault')
	   if $options->{'fg'};
     },
     'help' => 'Foreground color',
     'length' => 7,
     'maxsize' => 7,
     'subtype' => 'color',
    }],
   ['font', '=s', undef,
    {'callback' =>
     sub {
	 $top->optionAdd("*font" => $options->{'font'}, 'userDefault')
	   if $options->{'font'};
     },
     'subtype' => 'font',
     'help' => 'Default font'}],
   ['i18nfont', '=s', undef,
    {'callback' =>
     sub {
	 if (!$options->{'i18nfont'}) {
	     my(@s) = split(/-/, $top->optionGet('font', 'Font'));
	     if ($#s == 14) {
		 $options->{'i18nfont'} = join('-', @s[0..$#s-2]) . '-%s';
	     }
	 }
     },
     'subtype' => 'font',
     'help' => 'Font used for different encodings'}],
   ['geometry', '=s', undef,
    'help' => 'Font used for different encodings',
    'subtype' => 'geometry',
   ],

   'appearance',
   ['infowin', '!', 1, {'label' => 'Balloon', 'help' => 'Switches balloons on or off'}] ,
   ['undermouse', '!', 1,
    {'callback' =>
     sub {
	 $top->optionAdd("*popover" => 'cursor', 'userDefault')
	   if $options->{'undermouse'};
     },
     'help' => 'Popup new windows under mouse cursor'}],
   ['fasttemplate', '!', 0,
    {'help' => 'Fast templates without lists of existing objects'}],
   ['shortform', '!', 0,
    {'help' => 'Use a shorter form'}],
   ['editform', '!', 1,
    {'help' => 'Turn editing of forms on or off'}],
   ['statustext', '!', 0,
    {'help' => 'Turn use of a seperate window for status text on or off'}],
   ['debug', '!', 0, {'alias' => ['d']}],
   ['lang', '=s', undef,
    {'choices' => ['en', 'de', 'hr'], 'strict' => 1,
     'label' => 'Language (with Browseentry)'}],
   ['lang-alt', '=s', "hr",
    {'choices' => [["english" => 'en'],
		   ["deutsch" => 'de'],
		   ["hrvatski" => 'hr']], 'strict' => 1,
     'label' => 'Language (with Optionmenu)'}],
   ['stderr-extern', '!', 0,
    'callback-interactive' => sub { warn "Only called from GUI!" },
   ],

   'extern',
   ['imageviewer', '=s', 'xv %s',
    {'choices' => ['xli %s', 'xloadimage %s', '#NETSCAPE file:%s']}],
   ['internimageviewer', '!', 1,
    {'help' => 'Use intern image viewer if possible'}],
   ['', '', '-'],
   ['browsercmd', '=s', '#NETSCAPE %s',
    {'choices' => ['#WEB %s', 'mosaic %s', '#XTERM lynx %s']}],
   ['mailcmd', '=s', '#XTERM mail %s',
    {'choices' => ['#NETSCAPE mailto:%s', '#XTERM elm %s']}],
   ['netscape', '=s', 'netscape',
    {'help' => 'Path to the netscape executable'}],
   ['xterm', '=s', 'xterm -e %s',
    {'choices' => ['color_xterm -e %s', 'rxvt -e %s']}],

   'dialing',
   ['devphone', '=s', '/dev/cuaa1',
    {'help' => 'The phone or modem device'}],
   ['dialcmd', '=s', '#DIAL %s',
    {'choices' => ['#XTERM dial %s']}],
   ['hangupcmd', '=s', '#HANGUP'],
   ['dialat', '=s', 'ATD',
    {'choices' => ['ATDT', 'ATDP'],
     'help' => 'Use ATDT for tone and ATDP for pulse dialing'}],

   'adr2tex',
   ['adr2tex-cols', '=i', 8, {'range' => [2, 16],
			      'help' => 'Number of columns'}],
   ['adr2tex-rows', '=i', undef,
    'help' => 'Number of rows', -from => 1, -to => 20],
   ['adr2tex-width', '=f', undef,
    'help' => 'page width in in', -from => 0],
   ['adr2tex-font', '=s', 'sf',
    {'choices' => ['cmr5', 'cmr10', 'cmr17', 'cmss10', 'cmssi10',
		   'cmtt10 scaled 500', 'cmtt10']}],
   ['adr2tex-headline', '=s', 1,
    {'help' => 'Print a headline (default headline: 1)'}],
   ['adr2tex-footer', '=s', 1,
    {'help' => 'Print a footer (default footer: 1)'}],
   ['adr2tex-usecrogersort', '!', 1],

  );

my $optfilename = "t/opttest";
my $opt = Tk::Getopt->new(-opttable => \@opttable,
			  -options  => $options,
			  -filename => $optfilename);
isa_ok($opt, "Tk::Getopt");

$opt->set_defaults;
$opt->load_options;
if (!$opt->get_options) {
    die $opt->usage;
}
$top = eval { new MainWindow };
if (!$top) {
 SKIP: { skip "Cannot create MainWindow, probably no DISPLAY available", 3 }
    exit 0;
}

# Skip on Windows, because transient windows does not work with
# withdrawn masters
$top->withdraw if $^O ne "MSWin32";

#eval {$opt->process_options};
$opt->process_options;
if ($@) { warn $@ }

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

my $batch_mode = !!$ENV{BATCH};
my $timerlen = ($batch_mode ? 1000 : 60*1000);

my $timer;
sub setup_timer {
    $timer = $top->after
	($timerlen,
	 sub {
	     if ($batch_mode) {
		 foreach ($top->children) {
		     $_->destroy;
		 }
	     } else {
		 my $t2 = $top->Toplevel(-popover => 'cursor');
		 $t2->Label(-text => "Self-destruction in 5s")->pack;
		 $t2->Popup;
		 $top->after(5*1000, sub {
				 foreach ($top->children) {
				     $_->destroy;
				 }
			     });
	     }
	 });
}

{
    setup_timer();
    my $w = $opt->option_editor($top,
				-statusbar => 1,
				-popover => 'cursor',
				'-wait' => 1);
    isa_ok($w, "Tk::Widget");
    $timer->cancel;
}

{
    setup_timer();
    # Should show x11 page
    my $w = $opt->option_editor($top,
				-statusbar => 1,
				-popover => 'cursor',
				-page => 'x11',
				'-wait' => 1);
    $timer->cancel;
}

{
    setup_timer();
    my $answer = $opt->option_dialog($top,
				     -statusbar => 1,
				     -popover => 'cursor',
				     -string => {optedit => 'Option Dialog'},
				    );
    ok(!defined $answer || $answer =~ m{^(ok|cancel)$}, "Expected answers");
}

{
    # Should the same page again
    my $w = $opt->option_editor($top,
				-transient => $top,
				-buttons => [qw/ok apply cancel defaults/],
				-delaypagecreate => 0,
			       );
    $w->resizable(0,0);
    $w->OnDestroy(sub {$top->destroy});

    $timerlen = ($batch_mode ? 1000 : 5*1000);

    $top->after($timerlen/2, sub { $opt->raise_page("extern") });
    $top->after($timerlen, sub { $w->destroy });
}

#$top->WidgetDump;

MainLoop;
#foreach (sort keys %$options) {
#    print "$_ = ", $options->{$_}, "\n";
#}
pass("Hopefully everything went ok");


