# User configuration window for Tk with interface to Getopt::Long.
# -*- perl -*-

use strict;
use vars qw($MW);

use Tk;
use Tk::Getopt;
use File::Temp qw(tempfile);

sub tk_getopt {
    my($demo) = @_;
    my $demo_widget = $MW->WidgetDemo
      (
       -name             => $demo,
       -text             => 'A Tk::Getopt demonstration.',
       -title            => 'Tk::Getopt Example',
       -iconname         => 'Tk::Getopt',
      );
    my $top = $demo_widget->Top;   # get geometry master

    my $options = {};
    my @opttable =
	(			#'loading',
	 ['adbfile', '=s', undef, 
	  {'alias' => ['f'],
	   'help' => 'The default database file',
	   'longhelp' => "This is an example for a longer help\nYou can use multiple lines\n",
	   'subtype' => 'file',
	  }],
	 ['exportfile', '=s', undef,
	  {
	   'choices' => ["/tmp/export.dat", "$ENV{HOME}/export.dat"],
	   'subtype' => 'file'}],
	 ['dumpfile', '=s', '/tmp/dump', {'subtype' => 'file'}],
	 ['autoload', '!', 0,
	  {
	   'help' => 'Turns autoloading of the default database file on or off'}],

	 'x11',
	 ['bg', '=s', undef, 
	  {'callback' =>
	   sub {
	       if ($options->{'bg'}) {
		   $top->optionAdd("*background" => $options->{'bg'}, 'userDefault');
		   $top->optionAdd("*backPageColor" => $options->{'bg'},
				   'userDefault');
	       }
	   },
	   'help' => 'Background color'}],
	 ['fg', '=s', undef,
	  {'callback' => 
	   sub {
	       $top->optionAdd("*foreground" => $options->{'fg'}, 'userDefault')
		   if $options->{'fg'};
	   },
	   'help' => 'Foreground color'}],
	 ['font', '=s', undef,
	  {'callback' =>
	   sub {
	       $top->optionAdd("*font" => $options->{'font'}, 'userDefault')
		   if $options->{'font'};
	   },
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
	   'help' => 'Font used for different encodings'}],

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
	  {
	   'help' => 'Fast templates without lists of existing objects'}],
	 ['shortform', '!', 0,
	  {
	   'help' => 'Use a shorter form'}],
	 ['editform', '!', 1,
	  {
	   'help' => 'Turn editing of forms on or off'}],
	 ['statustext', '!', 0,
	  {
	   'help' => 'Turn use of a seperate window for status text on or off'}],
	 ['debug', '!', 0, {'alias' => ['d']}],
	 ['lang', '=s', 'en',
	  {'choices' => ['en', 'de', 'hr'], 'strict' => 1,
	   'label' => 'Language'}],
	 ['stderr-extern', '!', 0],

	 'extern',
	 ['imageviewer', '=s', 'xv %s',
	  {
	   'choices' => ['xli %s', 'xloadimage %s', '#NETSCAPE file:%s']}],
	 ['internimageviewer', '!', 1,
	  {
	   'help' => 'Use intern image viewer if possible'}],
	 ['browsercmd', '=s', '#NETSCAPE %s',
	  {
	   'choices' => ['#WEB %s', 'mosaic %s', '#XTERM lynx %s']}],
	 ['mailcmd', '=s', '#XTERM mail %s', 
	  {
	   'choices' => ['#NETSCAPE mailto:%s', '#XTERM elm %s']}],
	 ['netscape', '=s', 'netscape',
	  {
	   'help' => 'Path to the netscape executable'}],
	 ['xterm', '=s', 'xterm -e %s',
	  {
	   'choices' => ['color_xterm -e %s', 'rxvt -e %s']}],

	 'dialing',
	 ['devphone', '=s', '/dev/cuaa1',
	  {
	   'help' => 'The phone or modem device'}],
	 ['dialcmd', '=s', '#DIAL %s',
	  {
	   'choices' => ['#XTERM dial %s']}],
	 ['hangupcmd', '=s', '#HANGUP'],
	 ['dialat', '=s', 'ATD',
	  {'choices' => ['ATDT', 'ATDP'],
	   'help' => 'Use ATDT for tone and ATDP for pulse dialing'}],

	 'adr2tex',
	 ['adr2tex-cols', '=i', 8, {'range' => [2, 16],
				    'help' => 'Number of columns'}],
	 ['adr2tex-font', '=s', 'sf', 
	  {'choices' => ['cmr5', 'cmr10', 'cmr17', 'cmss10', 'cmssi10',
			 'cmtt10 scaled 500', 'cmtt10']}],
	 ['adr2tex-headline', '=s', 1,
	  {
	   'help' => 'Print a headline (default headline: 1)'}],
	 ['adr2tex-footer', '=s', 1,
	  {
	   'help' => 'Print a footer (default footer: 1)'}],
	 ['adr2tex-usecrogersort', '!', 1],

	);

    my(undef,$optfilename) = tempfile(SUFFIX => ".tk-getopt", UNLINK => 1);
    my $opt = new Tk::Getopt(-opttable => \@opttable,
			     -options => $options,
			     -filename => $optfilename);

    $opt->set_defaults;
    $opt->load_options;
    if (!$opt->get_options) {
	die $opt->usage;
    }
    $opt->process_options;
    if ($@) {
	warn $@;
    }

    $top->Button(-text => "Open option dialog",
		 -command => sub {
		     my $answer = $opt->option_dialog($top,
						      -statusbar => 1,
						      -popover => 'cursor',
						      -buttons => ['oksave','cancel'],
						     );
		     if (defined $answer) {
			 $top->messageBox(-message => "The button pressed was <$answer>.");
			 if ($answer eq 'ok') {
			     my $config_data = do {
				 open my $fh, $optfilename
				     or die "Error while opening $optfilename: $!";
				 local $/;
				 <$fh>;
			     };
			     my $t = $top->Toplevel(-title => 'Contents of config file');
			     my $txt = $t->Scrolled('ROText', -wrap => 'none', -scrollbars => 'oe')->pack(qw(-fill both -expand 1));
			     $txt->insert('end', $config_data);
			     my $wait = 1;
			     $t->Button(-text => 'Ok', -command => sub { $wait = 0 })->pack;
			     $t->waitVariable(\$wait);
			     $t->destroy;
			 }
		     } else {
			 $top->messageBox(-message => "Undefined answer, probably closed via the window manager close button.");
		     }
		 })->pack;
}

return 1 if caller();

require WidgetDemo;

$MW = new MainWindow;
$MW->geometry("+0+0");
$MW->Button(-text => 'Close',
            -command => sub { $MW->destroy })->pack;
tk_getopt('tk_getopt');
MainLoop;
