#!/usr/bin/perl
# 	$rcs = ' $Id: etext.t,v 1.8 1996/10/30 20:04:30 ilya Exp ilya $ ';
require 5.002;
#use English;
#use lib qw(../blib/arch ../blib/lib); # For syntax checking
use lib '../Tk/blib';		# Bug with Tk install ???
use lib 'utils';		# TeX and FreezeThaw
use Tk;

print "1..1\n";

use Tk::eText;
#use Tk::ROText;
require Tk::ErrorDialog;
use Tk::Menubar;
use FreezeThaw qw(freeze thaw);
use Text::TeX;


%recognized_args = qw(\\sqrt Radical \\frac Fraction ^ SuperSub _ SuperSub
		      \\left LR \\right LR);
%recognized_envs = qw(equation Equation matrix Matrix);
%tag_for_args = qw(\\operatornamewithlimits operatornamewithlimits
		   \\operatorname operatorname
		   \\text mathtext \\em italic \\bold bold \\mathcal cmsy
		   \\mathbb msbm \\mathfrak frak
		  );
%block2TeX = (SuperSub => \&superSub2TeX, LR => \&LR2TeX);
%blockStart = ( Radical => '\\root{',
		Fraction => '\\frac{',
	      );
%blockEnd = ( Radical => '}',
	      Fraction => '}',
	    );
%blockLen = ( Fraction => 1 );	# 1 less than required number of arguments.

%block2Env = ( Matrix => 'matrix',
	     );


%startMath = qw(Equation 1);
%parens = ( '(', '(', ')', ')', '[', '[', ']', ']', '\{', '{', '\}', '}',
	       '|', '|', '\|', '\\', '.', ' ' );

%parens2TeX = ( '(', '(', ')', ')', '[', '[', ']', ']', '{', '\{', '}', '\}',
	       '|', '|', '\|', '\\', ' ', '.' );
%blockTypes = (Matrix => 2, Fraction => 3); # See @separators.

@separators = ( [],		# 0
		['\\\\'],	# 1
		['\\\\', '&'],	# 2
		['}{'],		# 3
		['\\\\'],	# 4 - Special case for SuperSub
	      );

my $matrixSeparators = { '&' => 1, '\\\\' => 2 };
my $equationSeparators = { '\\\\' => 1 };
%separators = ( Matrix => $matrixSeparators ,
		Equation => $equationSeparators);
%tag2TeX_text = ( italic => '{\em', bold => '{\bf');
%tag2TeX_math = ( italic => '{\mit', bold => '{\bold');

%char_by_char = qw( symbol 1 cmsy 1 cmex 1 msam 1 msbm 1 frak 1 );

my @msbm = @Text::TeX::msbm;
my @cmsy = @Text::TeX::cmsy;
my @frak;

%by_table = ( symbol => \@Text::TeX::symbol,
	      cmsy => \@cmsy,
	      cmex => \@Text::TeX::cmex,
	      msam => \@Text::TeX::msam,
	      msbm => \@msbm,
	      frak => \@frak,
	    );
foreach ('A' .. 'Z') {
  $msbm[ord $_] = "{\\mathbb $_}";	# \\Bbb ?
  $cmsy[ord $_] = "{\\mathcal $_}";	# \\cal ?
  $frak[ord $_] = "{\\mathfrak $_}";	# \\frak ?
  $frak[ord lc $_] = "{\\mathfrak \l$_}";	# \\frak ?
}

#TeX::initgreek;

#sub sigalrm {alarm 5}
#alarm 15;
#$SIG{ALRM} = \&sigalrm;

# $top = MainWindow->new;
# $top->title('Widget Demonstration');
# #Tk::Widget::EnterWidgetCmd($top,"text",Tk::eText::Cmd());

# $text = $top->eText(-relief => 'raised', -borderwidth => 1);
# @a = %$text;
# print "$text\n@a\n", ;
# $text->pack(-side => 'bottom', -expand => 'yes', -fill => 'both');
# $text->insert('insert',"Here is some text");
# @conf = $text->block('configure','Std');
# $text->insert('insert',"@conf");

# MainLoop;

require 'dumpvar.pl';
eval 'use Devel::Peek'; warn $@ if $@ and $ENV{ETEXT_DB};

# use strict;

$dumpvar::compactDump = 160;

my $not_X;
my $server;

$initialized || do {
  $top = MainWindow->new;
  $not_X = $^O eq 'os2' && ($server = $top->winfo('server')) =~ /win32|os\/2/i;
print "server: `$server', not_X: `$not_X'\n";  
$prefix = $ENV{kprefix} || ($^O eq 'os2' 
			    ? ($server =~ /os\/2/i 
			       ? "Control-Alt-"
			       : "Control-Alt-")
			    : "Control-Meta-");

  #Tk::Widget::EnterWidgetMethod("Text","block");
  
  my $mb  = $top->Menubar; #(-bindto => 'Tk::Text');
  
  require Tk::FileSelect;
  my $fs  = $top->Component(FileSelect => 'fs', -width => 25, -height => 8,
			    '-accept'   => sub 
			    { my $file = shift ; 
			      return 0 if (-s $file && (stat(_))[12] eq 0);
			      return (-r $file) && (-T $file);  
			    },
			    Name => 'fs', -filter => '*');

  $text = $top->Component(ScrleText => 'text', wrap => 'word');
  $top->Delegates(DEFAULT => $text); 
  $top->ConfigSpecs(DEFAULT => [$text]); 
  $text->pack(-expand => 1, -fill => 'both');

  $text = $text->{SubWidget}->{etext};
  $text->focus;

  $testbutton = $text->Button(text => "Press me!", 
				 command => sub {print "# OK\n"});
  
  $mb->command(-button => ['File', -underline => 0],
	       -label => 'Open...', -underline => 0, 
	       -command => sub { my $file = $fs->Show(-popover => $top);
				 $text->Load($file) if (defined $file);
			       });
  $mb->command(-button => 'File', 
	       -label => 'Open save.tsf', -underline => 0, 
	       -command => [ $text , 'Load' ]);
  $mb->command(-button => 'File', 
	       -label => 'Save...', -underline => 0, 
	       -command => sub { my $file = $fs->Show(-popover => $top);
				 $text->Save($file) if (defined $file);
			       });
  $mb->command(-button => 'File', 
	       -label => 'Save to save.tsf', -underline => 0, 
	       -command => [ $text , 'Save' ]);
  $mb->command(-button => 'File', 
	       -label => 'List', -underline => 0,
	       -accelerator => "<${prefix}l>",
	       -command => sub {dumpVar ($text->listRange)});
  $mb->command(-button => 'File',  	      
	       -label => 'Mstats', -underline => 1,
	       -accelerator => "<${prefix}s>",
	       -command => sub {Devel::Peek::mstat("from menu")});
  $mb->command(-button => 'File', 
	       -label => 'Reload Source', -underline => 0, 
	       -accelerator => "<${prefix}n>",
	       -command => sub {do "t/eText.t"; die $@ if $@;});
  $mb->command(-button => 'File', 
	       -label => 'Load TeX from t/test.tex', -underline => 5, 
	       -command => [$text, readTeX]);
  $mb->command(-button => 'File', -label => 'Debug off', -underline => 6, 
	       # -accelerator => "<${prefix}q>",
	       -command => [ $text, 'debug', 'no'] );
  $mb->command(-button => 'File', -label => 'Debug on', -underline => 0, 
	       # -accelerator => "<${prefix}q>",
	       -command => [ $text, 'debug', 'yes'] );
  $mb->command(-button => 'File', 
	       -label => 'To TeX', -underline => 0,
	       -accelerator => "<${prefix}w>",
	       -command => sub {print ($text->range2TeX, "\n")});
  $mb->command(-button => 'File', -label => 'Quit', -underline => 0, 
	       -accelerator => "<${prefix}q>",
	       -command => [ sub {print "ok 1\n"; exit(0)}] );

  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Int Copy', -underline => 4, 
	       -command => sub { 
		 my @sel = $text->tag('nextrange', 'sel', '0.0');
		 undef $sel;
		 $sel = $text->block('list', @sel) if @sel;
		 #::dumpValue($sel);
	       });
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Int Paste', -underline => 4, 
	       -command => sub {
		 return unless $sel;
		 for $piece (@$sel) {
		   #::dumpValue $piece;
		   $piece->insertSelf($text, 'insert');
		 }
	       });
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'TeX insert', -underline => 0,
	       -command => \&getString );
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'selection TeX insert', -underline => 0,
	       -command => [$text,'selTeXinsert','insert'] );
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Find', -underline => 0,
	       -command => \&getSearch );
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Copy', -underline => 3,
	       -command => 
	       sub {$text->insert( 'insert', 
				   $text->SelectionGet("-selection",
						       "CLIPBOARD") ) 
		  } );
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Unbusy', -underline => 3,
	       -command => [$text, 'unmake_busy'] );

  $mb->command(-button => ['Insert', underline => 0],
	       -label => 'Tree', -underline => 0, 
	       -accelerator => "<${prefix}i>",
	       -command => [ $text, 'insertBlock', 'Std' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -label => 'Fraction', -underline => 0, 
	       -accelerator => "<${prefix}f>",
	       -command => [ $text, 'insertBlock', 'Fraction' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}d>",
	       -label => 'Radical', -underline => 0, 
	       -command => [ $text, 'insertBlock', 'Radical' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}t>",
	       -label => 'Tab', -underline => 2, 
	       -command => [ $text, 'insertBlock', 'Tab' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}m>",
	       -label => 'Matrix', -underline => 0, 
	       -command => [ $text, 'insertBlock', 'Matrix' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}b>",
	       -label => 'Table', -underline => 4, 
	       -command => [ $text, 'insertBlock', 'Table' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}c>",
	       -label => 'SuperSub', -underline => 0, 
	       -command => [ $text, 'insertBlock', 'SuperSub' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}e>",
	       -label => 'Equation', -underline => 0, 
	       -command => [ $text, 'insertBlock', 'Equation' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}(>",
	       -label => 'Braces ()', -underline => 7, 
	       -command => [ $text, 'insertBlockWithData', 'LR', '()' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}[>",
	       -label => 'Braces []', -underline => 7, 
	       -command => [ $text, 'insertBlockWithData', 'LR', '[]' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}{>",
	       -label => 'Braces {}', -underline => 7, 
	       -command => [ $text, 'insertBlockWithData', 'LR', '{}' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}<>",
	       -label => 'Braces <>', -underline => 7, 
	       -command => [ $text, 'insertBlockWithData', 'LR', '<>' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}\\>",
	       -label => 'Braces Floor', -underline => 7, 
	       -command => [ $text, 'insertBlockWithData', 'LR', 'Ff' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}/>",
	       -label => 'Braces Ceiling', -underline => 7, 
	       -command => [ $text, 'insertBlockWithData', 'LR', 'Cc' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -label => 'Case', -underline => 1, 
	       -command => [ $text, 'insertBlockWithData', 'LR', '{ ' ] );

  $mb->command(-button => ['Split', underline => 0],
	       -accelerator => "<Control-Return>",
	       -label => 'Shallow', -underline => 0, 
	       -command => [ $text, 'block', 'split', 'insert', 1 ] );
  $mb->command(-button => ['Split', underline => 0],
	       -accelerator => "<${prefix}Return>",
	       -label => 'Depth 2', -underline => 6, 
	       -command => [ $text, 'block', 'split', 'insert', 2 ] );
  $mb->command(-button => ['Split', underline => 0],
	       -label => 'Depth 3', -underline => 6, 
	       -command => [ $text, 'block', 'split', 'insert', 3 ] );
  $mb->command(-button => ['Split', underline => 0],
	       -accelerator => "<${prefix}BackSpace>",
	       -label => 'Trim', -underline => 0, 
	       -command => [ $text, 'block', 'trim', 'insert'] );
  
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Tree', -underline => 0, -accelerator => '<F1>',
	       -command => [ $text, 'example1', 'insert' ] );
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Tree in Tree', -underline => 5,  
	       -accelerator => '<F2>',
	       -command => [ $text, 'example2', 'insert' ] );
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Radical', -underline => 0,  -accelerator => '<F3>',
	       -command => [ $text, 'example3', 'insert' ] );
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Equation', -underline => 0,  -accelerator => '<F4>',
	       -command => [ $text, 'example4', 'insert' ] );
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Tabs', -underline => 1,  -accelerator => '<F5>',
	       -command => [ $text, 'example5', 'insert' ] );
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Empty Tree', -underline => 1,  -accelerator => '<F10>',
	       -command => [ $text, 'example10', 'insert' ] );

  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'VerbTeX', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'verbTeX' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'CommentTeX', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'commentTeX' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Math', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'math' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Small', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'small' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Symbol', -underline => 1, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'symbol' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Bold', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'bold' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Italic', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'italic' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Frak', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'frak' ] );
  $mb->command(-button => ['Tag', underline => 0],
	       -label => 'Msbm', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'insTag', 'msbm' ] );

  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'VerbTeX', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'verbTeX' ] );
  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'CommentTeX', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'commentTeX' ] );
  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'Math', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'math' ] );
  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'Small', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'small' ] );
  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'Symbol', -underline => 1, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'symbol' ] );
  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'Bold', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'bold' ] );
  $mb->command(-button => ['Untag', underline => 0],
	       -label => 'Italic', -underline => 0, # -accelerator => '<F1>',
	       -command => [ $text, 'remTag', 'italic' ] );

  #$top->AddScrollbars($text);
  #my %args;
  #$top->ConfigDefault(\%args);
  #$top->configure(%args) if (%args);

  #my $s = $top->Scrollbar(-orient => 'vertical');
  #$s->pack(-side => 'right', -fill => 'y');
  #$text = $top->eText(-relief => 'raised', -borderwidth => 1,
  #		      -yscrollcommand =>  ['set', $s]);
  #$s->configure(-command => ['yview', $text]);
  #print $text->get("0.0","end"), "\n";

  $text->block('configure', 'Std');

  $initialized++;
};

if ($not_X) {
  $mainfont = '-*-Courier-*-*-*-*-20-*-*-*-*-*-*-*';
  $italicfont = '-*-Courier-*-I-*-*-20-*-*-*-*-*-*-*';
  $boldfont = '-*-Courier-Bold-*-*-*-20-*-*-*-*-*-*-*';
  #$calfont = '-*-Tms Rmn-*-I-*-*-24-*-*-*-*-*-*-*';
  $cmsyfont = 'cmsy10<144>';
  $cmexfont = 'cmex10<120>';
  #$frakfont = '-*-Tms Rmn-Bold-I-*-*-24-*-*-*-*-*-*-*';
  #$frakfont = '-*-eufm12-*-*-*-*-10-*-*-*-*-*-*-*';
  $frakfont = 'eufm10<144>';
  #$frakfont = '-*-System VIO-*-*-*-*-2-*-*-*-*-*-*-*';
  #$msbmfont = '-*-Tms Rmn-Bold-*-*-*-24-*-*-*-*-*-*-*';
  $msbmfont = 'msbm10<144>';
  $smallfont = '-*-Tms Rmn-*-*-*-*-12-*-*-*-*-*-*-*';
  $symbolfont = '-*-Symbol Set-*-*-*-*-20-*-*-*-*-*-*-*';
} else {
  $mainfont = '10x20';
  $italicfont = '-*-Courier-*-O-*-*-20-*-*-*-*-*-*-*';
  $boldfont = '-*-Courier-Bold-*-*-*-20-*-*-*-*-*-*-*';
  $cmsyfont = '-*-Times-*-I-*-*-24-*-*-*-*-*-*-*';
  $cmexfont = '-*-Times-*-I-*-*-24-*-*-*-*-*-*-*';
  $frakfont = '-*-Times-Bold-I-*-*-24-*-*-*-*-*-*-*';
  $msbmfont = '-*-Times-Bold-*-*-*-24-*-*-*-*-*-*-*';
  $smallfont = '6x10';
  $symbolfont = '-*-symbol-*-*-*-*-20-*-*-*-*-*-*-*';
}

destroy $popupString if Exists $popupString;

$top->title('Extended Text Demonstration');
#@a = %$text;
#print "$text\n@a\n", ;

#$text->pack(-side => 'bottom', -expand => 'yes', -fill => 'both');

# $text->debug("yes");

# Initialize the mark stack
$text->{tags} = {};		# We keep indices of starts of tags in progress here.
$text->{activetags} = [#'lmargin1'
		      ]; # The tags to use for insert
$text->{activeblocks} = [];	# The blocks we are in during TeX insert
$text->{markc} = 0;		# Names of floating marks.
$text->{indices} = 0;		# Names of fixed marks.
$text->{indexinfo} = 0;		# Data associated to fixed marks.

#require ExtUtils::Dump;

#@conf = $text->block('configure', 'Std');
#$text->insert('insert',"Here is some text");
#$text->insert('insert',"@conf");
#dumpvar("main","conf");

$| = 1;

$text->configure (-insertbackground => "Gray", -insertborderwidth => 2,
  -insertwidth => 6, -height => 25, -width => 35, -font => $mainfont);

$text->block('configure', 'Std', "-layoutcmd" => \&recursiveLayout,
	     '-layoutdepth' => -1, 
	     '-layoutwidths' => [[1,12]]);

$text->block('configure', 'Fraction', "-layoutcmd" => \&layoutFraction,
	     '-layoutdepth' => 1, 
	     '-layoutwidths' => [2]);

$text->block('configure', 'SuperSub', "-layoutcmd" => \&layoutSuperSub,
	     '-layoutdepth' => 1, 
	     '-layoutwidths' => [2]);

$text->block('configure', 'Radical', "-layoutcmd" => \&layoutRadical,
	     '-layoutdepth' => 1, 
	     '-layoutwidths' => [1]);

$text->block('configure', 'Equation', "-layoutcmd" => \&layoutEquation,
	     '-layoutdepth' => 1, 
	     '-layoutwidths' => [2]);

$text->block('configure', 'Tab', "-layoutcmd" => [\&layoutTab, 5, 35],
	     -empty => 'on');

$text->block('configure', 'Matrix', 
	     -layoutcmd => [\&layoutTable, 5, 5, 0, 0, 0],
	     -layoutdepth => 2);

$text->block('configure', 'Table', 
	     -layoutcmd => [\&layoutTable, 5, 5, 3, 3, 2],
	     -layoutdepth => 2);

$text->block('configure', 'LR', 
	     -layoutcmd => \&layoutLR,
	     -layoutdepth => 1, -layoutwidths => [1]);

#$text->block('configure', 'Tab', "-layoutcmd" => sub {layoutTab(5, 35, @_)},
#	     -empty => 'on');

#@conf = $text->block('configure', 'std');
#@conf = $text->block('configure', 'Std');
#dumpvar("main","conf");

$text->bind( "<${prefix}n>",sub {do "t/eText.t"; die $@ if $@; $text->break});
$text->bind( "<${prefix}q>",sub {print "ok 1\n"; exit(0)});
$text->bind( "<${prefix}s>",sub {Devel::Peek::mstat("hotkey"); $text->break});
$text->bind( "<${prefix}i>", ['insertBlock','Std', 1]);
$text->bind( "<${prefix}f>", ['insertBlock','Fraction', 1]);
$text->bind( "<${prefix}d>", ['insertBlock','Radical', 1]);
$text->bind( "<${prefix}t>", ['insertBlock','Tab', 1]);
$text->bind( "<${prefix}b>", ['insertBlock','Table', 1]);
$text->bind( "<${prefix}m>", ['insertBlock','Matrix', 1]);
$text->bind( "<${prefix}c>", ['insertBlock','SuperSub', 1]);
$text->bind( "<${prefix}x>", sub {$text->block('insert', 'SuperSub', 'insert'); $text->break});
$text->bind( "<${prefix}e>", ['insertBlock','Equation', 1]);
$text->bind( "<${prefix}parenleft>", ['insertBlockWithData','LR', '()', 1]);
$text->bind( "<${prefix}bracketleft>", ['insertBlockWithData','LR', '[]', 1]);
$text->bind( "<${prefix}less>", ['insertBlockWithData','LR', '<>', 1]);
$text->bind( "<${prefix}braceleft>", ['insertBlockWithData','LR', '{}', 1]);
$text->bind( "<${prefix}bar>", ['insertBlockWithData','LR', '||', 1]);
$text->bind( "<${prefix}numbersign>", ['insertBlockWithData','LR', '\\\\', 1]);
$text->bind( "<${prefix}backslash>", ['insertBlockWithData','LR', 'Ff', 1]);
$text->bind( "<${prefix}slash>", ['insertBlockWithData','LR', 'Cc', 1]);
$text->bind( "<${prefix}p>",
	    sub {dumpVar ($text->block('configure','Std')); $text->break});
$text->bind("<Control-Return>",
	    sub {$text->block('split','insert',1); $text->break});
$text->bind("<${prefix}Return>",
	    sub {$text->block('split','insert',2); $text->break});
$text->bind("<${prefix}BackSpace>",
	    sub {$text->block('trim','insert'); $text->break});
$text->bind( "<${prefix}l>",
	    sub {dumpVar ($text->listRange); $text->break});
$text->bind( "<${prefix}w>",
	    sub {print ($text->range2TeX, "\n"); $text->break});
$text->bind( "<${prefix}W>",
	    sub {$text->window( 'create', 'insert', -window => $testbutton);
	         $text->break});

my $default_bindtags = [$text, ref $text, $text->toplevel,'all'];
my $busy_bindtags = ['Tk::ROText', $text->toplevel,'all'];
Tk::eText::bindRdOnly('Tk::ROText', $text);

$text->bindtags($default_bindtags);

sub myDump {dumpVar([@_]); @_}

my $def_cursor = $text->cget('-cursor');

sub Tk::eText::make_busy {
  my $widget = shift;
  $widget->configure(-cursor => 'watch');
  $text->bindtags($busy_bindtags);
}

sub Tk::eText::unmake_busy {
  my $widget = shift;
  $text->bindtags($default_bindtags);
  $widget->configure(-cursor => $def_cursor);
}

sub Tk::eText::example1 {
  shift->blockInsert(shift, 
		     "x",
		     (bless ['Std',"abc","ef","g"], Tk::Text::Block),
		     "y");
}

sub Tk::eText::example2 {
  shift->blockInsert(shift, 
		     "x",
		     (bless ['Std', "abc",
			     ["e", (bless ['Std',"pqr","st"],
				    Tk::Text::Block), "f"],
			     "g"],
		      Tk::Text::Block),
		     "y");
}

sub Tk::eText::example3 {
  shift->blockInsert(shift, 
		     bless ['Radical',
			    ["a+b", (bless ['SuperSub',"2","in"],
				     Tk::Text::Block)]],
		     Tk::Text::Block);
}

sub Tk::eText::example4 {
  shift->blockInsert(shift, 
		     "\n",
		     (bless
		      ['Equation', "(3.1a)",
		       [(bless 
			 ['Radical', 
			  ["1+",
			   (bless
			    ['Radical', 
			     ["1+", 
			      (bless
			       ['Radical', 
				["1+", 
				 (bless
				  ['Radical',"1+..."], 
				  Tk::Text::Block)]],
			       Tk::Text::Block)]],
			    Tk::Text::Block)]],
			 Tk::Text::Block), "=",
			(bless 
			 ['Fraction', 1,
			  ["1+",
			   (bless
			    ['Fraction', 1,
			     ["1+", 
			      (bless
			       ['Fraction', 1,
				["1+", 
				 (bless
				  ['Fraction', 1, "1+..."], 
				  Tk::Text::Block)]],
			       Tk::Text::Block)]],
			    Tk::Text::Block)]],
			 Tk::Text::Block)]],
		      Tk::Text::Block));
}

sub Tk::eText::example5 {
  shift->blockInsert(shift, 
		     "x",
		     (bless ['Tab'], Tk::Text::Block), "xx",
		     (bless ['Tab'], Tk::Text::Block), "xxx",
		     (bless ['Tab'], Tk::Text::Block), "xxxx",
		     (bless ['Tab'], Tk::Text::Block), "|");
}

sub Tk::eText::example10 {
  shift->blockInsert(shift, 
		     (bless ['Std'], Tk::Text::Block));
}

$text->bind( "<F1>", ['example1', 'insert']);
$text->bind( "<F2>", ['example2', 'insert']);
$text->bind( "<F3>", ['example3', 'insert']);
$text->bind( "<F4>", ['example4', 'insert']);
$text->bind( "<F5>", ['example5', 'insert']);
$text->bind( "<F10>", ['example10', 'insert']);

$text->tag('configure', 'commentTeX', -foreground => 'red');
$text->tag('configure', 'verbTeX', -foreground => 'red', -font => $smallfont);
$text->tag('configure', 'green', -foreground => 'seagreen');
$text->tag('configure', 'orange', -foreground => 'orange');
$text->tag('configure', 'math', -background => 'lightblue');
$text->tag('configure', 'mathlike', -background => 'lightblue');
$text->tag('configure', 'mathtext', -foreground => 'red');
$text->tag('configure', 'bold', -font => $boldfont);
$text->tag('configure', 'italic', -font => $italicfont);
$text->tag('configure', 'cmsy', -font => $cmsyfont, -foreground => 'blue');
$text->tag('configure', 'cmex', -font => $cmexfont, -foreground => 'blue');
$text->tag('configure', 'msam', -font => $msamfont, -foreground => 'blue');
$text->tag('configure', 'msbm', -font => $msbmfont, -foreground => 'blue');
$text->tag('configure', 'frak', -font => $frakfont, -foreground => 'blue');
$text->tag('configure', 'operatorname', -foreground => 'green');
$text->tag('configure', 'operatornamewithlimits', -foreground => 'blue');
$text->tag('configure', 'raised', -border => 2, -relief => 'raised');
$text->tag('configure', 'small', -font => $smallfont);
$text->tag('configure', 'lmargin1', -lmargin1 => 30);
$text->tag('configure', 'black', -background => 'black');
eval {
  $text->tag('configure', 'symbol', -font => $symbolfont);
};
eval {
  $text->tag('configure', 'symbol', -font => '-*-Symbol Set-*-*-*-*-18-*-*-*-*-*-*-*');
} if $@;
eval {
  $text->tag('configure', 'symbol', -font => '-*-symbol-*-*-*-*-20-*-*-*-*-*-*-*');
} if $@;
eval {
  $text->tag('configure', 'symbol', -font => '-*-symbol-*-*-*-*-18-*-*-*-*-*-*-*');
} if $@;

$text->tag('configure', 'backgr1', -background => 'blue',
	   -border => 2, -relief => 'raised');
$text->tag('configure', 'backgr2', -background => 'gray90',
	   -border => 2, -relief => 'raised');
$text->tag('configure', 'backgr3', -background => 'lightblue',
	   -border => 2, -relief => 'raised');

sub init_ornaments {
  $text->block('deletelines');
  
  $text->insert('1.0', "\n", [qw(black)]);
  $blackLine = $text->block('addline', '1.0');
  $text->delete('1.0', '1.0+1c');
  
  #$text->insert('1.0', "v\n", [qw(blue red)]);
  #$fractionLine =  $text->block('addline', '1.0');
  #$text->delete('1.0', '1.0+2c');
  
  $text->insert('1.0', "\326\n", [qw(symbol)]);
  $radicalCheck = $text->block('addline', '1.0');
  $text->delete('1.0', '1.0+2c');
  
  foreach $symb (split '', ' {}[]()<>|') {
    $text->insert('1.0', "$symb\n", [qw()]);
    $LR{$symb} = $text->block('addline', '1.0');
    $text->delete('1.0', '1.0+2c');
  }
  $text->insert('1.0', "\347\347\n", [qw(symbol)]);
  $LR{'\\'} = $text->block('addline', '1.0'); # Douple |
  $text->delete('1.0', '1.0+3c');
  
  $text->insert('1.0', " \n", [qw(backgr3)]);
  $LR{' '} = $text->block('addline', '1.0'); # Douple |
  $text->delete('1.0', '1.0+2c');
  
  foreach (0 .. 3) {		# Floor and ceiling
    $text->insert('1.0', substr("\353\373\351\371", $_, 1) . "\n", 
		  [qw(symbol)]);
    $LR{substr("FfCc", $_, 1)} = $text->block('addline', '1.0');
    $text->delete('1.0', '1.0+2c');
  }
  
  $LR{'['} = [undef, $LR{'C'}, $LR{'F'}];
  
  $text->insert('1.0', "\n", [qw(backgr1)]);
  $backgrId1 = $text->block('addline', '1.0');
  $text->delete('1.0', '1.0+1c');
  
  $text->insert('1.0', "\n", [qw(backgr2)]);
  $backgrId2 = $text->block('addline', '1.0');
  $text->delete('1.0', '1.0+1c');
}

init_ornaments();

$treeline = 2;
$treelineLen = 6;
#$layout = \&stdTree;

sub init_contents {
  $text->insert('1.0', "abcd\nefg");

  #print $text->get("0.0","end"), "\n";
  $text->block('insert', 'Std', "1.2", "2.2");
  $text->block('split',  "1.4", 1);
  $text->insert('1.0', "\347\347\n", [qw(backgr3 symbol)]);
}

sub init_contents1 {
  my @abc;
  splice @abc, 0,0, ();		# To be able to set a breakpoint
  $text->TeX_insert('insert', ' a^b_c ');
}

init_contents1();

$fractionWidth = 2;
$fractionWidthHalf = $fractionWidth + 1/2;
$stdAscent = 15;
$stdAscentHalf = int($stdAscent/2);
$stdDescent = 5;

#dumpValue($text->bind);

sub myLoop {
  if (defined &DB::DB) {
    while (1) {			# MainWindow->Count
      Tk::DoOneEvent(0);
    }
  } else {
    MainLoop;
  }
}

my $stdWidth = 10;
my $elth = 18;
my $eqGap = 15;

my $stime = times;
$do_update = 1;

$text->readTeX;

$stime = times - $stime;
print "Time in readTeX: $stime.\n";

$inmainloop++ || myLoop;	# To allow reloading

sub dumpVar {local %dumpvar::address; dumpvar::unwrap(shift,0);}

# sub stdLayout {			# Example Layout: makes almost the same as
# 				# the standard one, only puts middle at the
# 				# average baseline
#   #dumpVar \@_;
#   shift; shift;			# Name of the block and x-coordinate
#   my ($y, $w, $ww, $h, $b, $trow, @out) = (0) x 5;
#   foreach $row (@_) {
#     # Starts with multiplicity and y-coordinate
#     if ($w < $row->[2]) {$w = $row->[2]} # Width
#     if ($ww < $row->[3]) {$ww = $row->[3]} # Width of background
#     $h += $row->[4];
#     $b += $row->[5];
#   }
#   $b = ($h + $b/@_)/2;		# So that the middle is average baseline high
#   @out = ([-1, 0, $y, $w, $ww, $h, $b]);
#   foreach $row (@_) {
#     $trow = [ @{$row}[0..5] ]; $trow->[3] = $ww;
#     splice(@$trow, 1, 0, 0);	# Insert 0 after the first element - x coord
#     push(@out, $trow);
#   }
#   #print "X";
#   #dumpVar \@out;
#   return @out;
# }

# sub treeLayout {		# Example Layout: makes almost the same as
# 				# the standard one, only puts middle at the
# 				# average baseline
#   # dumpVar \@_;
#   shift; shift;			# Name of the block and x-coordinate
#   my ($y, $w, $ww, $h, $b, $trow, @out) = (0) x 5;
#   foreach $row (@_) {
#     # Starts with multiplicity and y-coordinate
#     if ($w < $row->[2]) {$w = $row->[2]} # Width
#     if ($ww < $row->[3]) {$ww = $row->[3]} # Width of background
#     $h += $row->[4];
#     $b += $row->[5];
#   }
#   $b = ($h + $b/@_)/2;		# So that the middle is average baseline high
#   @out = ([-1, 0, $y, $w, $ww, $h, $b]);
#   foreach $row (@_) {
#     $trow = [ @{$row}[0..5] ]; $trow->[3] = $ww;
#     splice(@$trow, 1, 0, 0);	# Insert 0 after the first element - x coord
#     push(@out, $trow);
#   }
#   print STDOUT "X";
#   #dumpVar \@out;
#   return @out;
# }

# The following layout procedure takes a name of layered layout
# procedure and makes it into usual one

#sub wrapLayout {
#  my ($block,$inner,$addlines) = &$layout;
#  ($block, @$inner, @$addlines); # Just collect arrays together
#}

# Below &$layout returns a reference to a list the first element of
# which contains a layout data for what is inside. It uses only the
# first component of arguments to make layout, all the rest is preserved
# in other components of the return. If it takes 3 arguments, the first
# component of return is the total size, the second gives layout of
# internal blocks, the third of additional blocks, and 3 others are just
# copies of what it got.

sub descendTree {
  my ($dx, $dy, $res, $add, @tree) = @_;
  #dumpValue (\@_);
  for (@$add) {
    $_->[1] += $dx;
    $_->[2] += $dy;
    push( @addlines, $_ );
  }
  my $i = 0;
  my $head;
  for (@tree) {
    if (@$_ > 1) {		# Arrays of length 1 or >=4
      $head = shift(@$_);
      descendTree($dx + $res->[$i]->[1], $dy + $res->[$i]->[2], @$_);
    } else {
      #$_->[0]->[1] += $dy + $res->[$i]->[2]; # y-coordinate
      #splice(@ {$_->[0]}, 6, 3);
      #splice(@ {$_->[0]}, 1, 0, $dx + $res->[$i]->[1]); # x-coordinate
      #push(@lines,$_->[0]);
      $res->[$i]->[1] += $dx; # x-coordinate
      $res->[$i]->[2] += $dy; # y-coordinate
      push(@lines,$res->[$i]);
    }
    $i++;
  }
}

sub stdTree {			# Example Layout: makes almost the same as
				# the standard one, only puts middle at the
				# average baseline
  shift; shift;			# Name of the block and x-coordinate
  #print "Tree:\n";
  #dumpValue ( \@_ );
  my ($y, $w, $ww, $h, $b, $trow, @out, $row, $uppermin, $lowermid) = (0) x 5;
  $y = $_[0][0][1];		# In first row: second elt of layout info
  foreach (@_) {
    $row = $_->[0];		# the layout for inside
    warn "Error: \$_ = `$_', \$row = `$row'\n" unless ref $row;
    # Starts with multiplicity and y-coordinate
    if ($w < $row->[2]) {$w = $row->[2]} # Width
    if ($ww < $row->[3]) {$ww = $row->[3]} # Width of background
    $h += $row->[4];
    $b += $row->[5];
  }
  $uppermid = $_[0]->[0];
  $uppermid = $uppermid->[4]/2; # 1/3 of accent high looks pretty reasonable
  $lowermid = $_[$#_]->[0];
  $lowermid = $h - $lowermid->[4]/2; # + $lowermid->[5]*2/3;
  $b = $b/@_/3 + ($uppermid + $lowermid)/2;
  # So that the middle is average baseline high
  my @block = (-1, $y, $w + $treelineLen, $ww + $treelineLen, $h, $b);
  @out = ();
  my @addl = ();
  my $nrow;
  foreach (@_) {
    $nrow = $_->[0];
    $trow = [ @{$nrow}[0..5] ]; $trow->[3] = $ww;
    $trow->[1] -= $y;		# Make relative.
    splice(@$trow, 1, 0, $treelineLen); # Insert $tl after the first element - x coord
    push(@out, $trow);
    push(@addl,[$blackLine,0,$trow->[2] + $trow->[5]/2,
		$treelineLen,$treelineLen,$treeline,0]);
  }
  push(@addl,
       [$blackLine,0,$uppermid,$treeline,$treeline,$lowermid - $uppermid,0]);
  #print "X";
  #dumpVar \@out;
  return [\@block,\@out,\@addl,@_];
}

sub digester {
  my ($data, $x) = (shift, shift);
  # Prepares information for handling to stdTree
  #print "Before:\n";
  #dumpValue ( \@_ );
  for (@_) {
    if (ref $_->[0]) {		# Inner block
      $_ = &digester( $data, $x, @$_);
    } else {
      $_=[$_];
    }
  }
  #print "After:\n";
  #dumpValue ( \@_ );
  stdTree $data, $x, @_;
}

sub recursiveLayout {
  my $tree = &digester;
  #dumpValue ($tree);
  local @addlines;		# the kids will extend it
  local @lines;			# the kids will extend it
  my $block = shift(@$tree);
  splice @$block, 1, 0, 0;	# Add x coordinate to the block
  descendTree 0, 0, @$tree;	# dx, dy, tree; Will extend arrays
  #print "block";
  #dumpValue ($block);
  #print "lines";
  #dumpValue (\@lines);
  #print "add";
  #dumpValue (\@addlines);
  ($block, @lines, @addlines);
}


sub layoutFraction {		#block x super sub
  my ($data,$x,$super,$sub) = @_;
  #dumpValue( \@_ );
  my $w = $super->[2];
  $w = $sub->[2] if $w < $sub->[2];
  $w += 4;
  my $shift1 = ($w - $super->[2])/2;
  my $shift2 = ($w - $sub->[2])/2;
  my $b = $stdAscentHalf + $super->[4] + $fractionWidthHalf;
  my $h = $super->[4] + $fractionWidth + $sub->[4];
  $h = $b if $h < $b;
  my @out = (
	     [-1, 0, 0, $w, $w, $h, $b],
	     [$super->[0], $shift1, $super->[1], $super->[2],
	      $super->[2], $super->[4], $super->[5]],
	     [$sub->[0], $shift2, $sub->[1] + $fractionWidth, $sub->[2],
	      $sub->[2], $sub->[4], $sub->[5]],
	     [$blackLine, 1, $super->[4], $w - 2, $w - 2, 2, 1],
	    );
  #dumpValue( \@out );
  return @out;
}

sub layoutSuperSub {		#block x super sub
  my ($data,$x,$super,$sub) = @_;
  #dumpValue( \@_ );
  my $w = $super->[2];
  $w = $sub->[2] if $w < $sub->[2];
  my $ww = $super->[3];
  $ww = $sub->[3] if $ww < $sub->[3];
  my $b = $stdAscentHalf + $super->[4];
  my $d = 0;
  my $y1 = 0;
  if (defined $sub) {
    # There is a subscript
    $d = $stdDescent + $sub->[4] - $sub->[5];
    if ($d < $sub->[4] - $stdAscentHalf ) {
      $d = $sub->[4] - $stdAscentHalf;
      $y1 = $super->[4];
    } else {
      $y1 = $b + $stdAscentHalf - $sub->[5];
    }
  }
  $#$super = $#$sub = 5;
  splice @$super, 1, 0, 0;
  splice @$sub, 1, 0, 0;
  $super->[4] = $sub->[4] = $ww;
  $sub->[2] = $y1;
  my @out = (
	     [-1, 0, 0, $w, $ww, $b + $d, $b],
	     $super,
	     $sub,
	    );
  #dumpValue( \@out );
  return @out;
}

sub layoutRadical {		# block x row
  my ($block, $x, $row) = (shift, shift, shift);
  my $h = $row->[4];
  my $vlx = 9;
  my $hlw = 2;
  my $vlw = 1;
  my $addxoff = 1;
  my $rcYoff = 1;
  my $xoff = $vlx + $hlw + $addxoff;
  my $checkH = 20;
  my $checkB = 15;
  my $addHeight = 3;
  $addHeight = $checkB - $h + $addHeight - 1 if $h < $checkB;
  my $vlH = 0;
  my $vrow = [];
  if ($h > $checkB) {
    $vlH = $h - $checkB;
    $vrow = [$blackLine, $vlx, 0, $vlw, $vlw, $vlH, 0];
  }
  my $b = $row->[5] + $addHeight;
  my $h_ = $h + $addHeight;
  my $wtot = $row->[2] + $xoff;
  my $hll = $row->[2] + $vlw + $addxoff;
  $row->[1] = $xoff;
  splice @$row, 2, 0, $addHeight;
  $#$row = 6;
  my $hrow = [$blackLine, $vlx, 0, $hll, $hll, $hlw, $hlw];
  my $totblock = [-1, 0, 0, $wtot, $wtot, $h_, $b];
  my $check = [$radicalCheck, 0, $vlH + $rcYoff, 0, 0, $checkH, $checkB];
  if ( @$vrow ) {
    return ($totblock, $row, $hrow, $vrow, $check);
  } else {
    return ($totblock, $row, $hrow, $check);
  }
}

sub layoutEquation {		# block x row
  my ($block, $x, $ind, $eq) = @_;
  my $eqw = $block->[1]->winfo('width') - 10; # XXXX Borders? otherwise
                                              # cannot get cursor into
                                              # the beginning of line

  #dumpValue($block);
  #dumpValue($eq);
  #print $eqw,"\n";
  # warn "#ind `$#$ind', #eq `$#$eq'\n";
  $#$ind = 5;
  $#$eq = 5;
  #defined $ind->[2] or warn 1;defined $eq->[2] or warn 2;
  my $tw =  $ind->[2] + $eq->[2] + $eqGap;
  $eqw = $tw if $eqw < $tw;
  my $gap = $ind->[2] + $eqGap + int(($eqw - $tw)/2);
  my $h = $ind->[4];
  $h = $eq->[4] if $h < $eq->[4];
  my $y0 = 0;
  $y0 =  int(($h - $ind->[4])/2)
      if $h > $ind->[4];
  my $y1 = 0;
  my $b = $eq->[5] + $y1;
  splice @$ind, 1, 1, 0, $y0;
  splice @$eq, 1, 1, $gap, $y1;
  my @out = (
	     [-1, 0, 0, $eqw, $eqw, $h, $b],
	     $ind,
	     $eq,
	    );
  #dumpValue( \@out );
  return @out;
}

sub layoutTab {			# min mult block x
  my ($min,$mult,$block,$x) = @_;
  my $w = $min + $mult - ($x + $min - 1) % $mult - 1;
  my $totblock = [$backgrId2, 0, 0, $w, $w, 5, 3];
  return ($totblock, $totblock);
}

sub layoutLR {			# \left-\right pair (in instance data).
  my ($block, $x, $in) = @_;
  my ($left, $right) = split '', $block->[2];
  my ($w,$b,$h) = @$in[2,5,4];
  my $diff = $h - 2 * $b + $stdAscent;
  if ( $diff > 0 ) {
    $h += $diff;
    $b += $diff;
  } elsif ($diff < 0) {
    $h -= $diff;
  }
  @$in[5,4] = ($b, $h);
  my $empty = $LR{' '};
  $left = $LR{$left} || $empty;
  $right = $LR{$right} || $empty;
  my $aw = $stdWidth;
  $w += 2*$aw;
  $#$in = 5;
  splice @$in, 1, 1, $aw, 1;	# Vert off = 1.
  #dumpVar($in);
  ([-1, 0, 0, $w, $w, $h+2, $b+1], 
   $in,
   [$empty, 0, 1, $aw, $aw, $h, $b],
   expanding($left, $h, $b, 0, 1),	# [$left, 0, 1, $aw, $aw, $h, $b],
   [$empty, $w - $aw, 1, $aw, $aw, $h, $b],
   expanding($right, $h, $b, $w - $aw, 1), # [$right, $w - $aw, 1, $aw, $aw, $h, $b]
  );
}

sub expanding {
  # Expanding element may have the following parts: 
  # middle, top, bottom, fill, topfill, bottomfill
  my $in = shift;
  $in = [$in] unless ref $in eq 'ARRAY';
  my ($middle, $top, $bottom, $fill, $topfill, $bottomfill) = @$in;
  my ($h, $b, $horoff, $voff) = @_;
  my @out;
  if (defined $top) {
    push @out, [$top, $horoff, $voff, $stdWidth, $stdWidth, $stdAscent + $stdDescent, $stdAscent];
  }
  if (defined $bottom) {
    push @out, [$bottom, $horoff, $voff + $h - $stdAscent - $stdDescent, $stdWidth, $stdWidth, $stdAscent + $stdDescent, $stdAscent];
  }
  if (defined $middle) {
    push @out, [$middle, $horoff, $voff + $b - $stdAscent, $stdWidth, $stdWidth, $stdAscent + $stdDescent, $stdAscent];
  }
  @out;
}

sub layoutTable {		# xgap ygap xborder yborder linew block x rows
  my ($xgap, $ygap, $xborder, $yborder, $linew, $block, $x, @rows) = @_;
  my (@colw, @rowac, @rowdec);
  my ($row, $col);
  foreach $row (0 .. $#rows) {
    $rowac[$row] = 0;
    $rowdec[$row] = 0;
    foreach $col (0 .. $#{$rows[$row]}) {
      $colw[$col] = $rows[$row]->[$col][2] 
	if ($colw[$col] || -1) < $rows[$row]->[$col][2];
      $rowac[$row] = $rows[$row]->[$col][5]
	if $rowac[$row] < $rows[$row]->[$col][5];
      $rowdec[$row] = $rows[$row]->[$col][4] - $rows[$row]->[$col][5]
	if $rowdec[$row] < $rows[$row]->[$col][4] - $rows[$row]->[$col][5];
    }
  }
  my (@baselines, @xmiddles);
  $baselines[0] = $rowac[0] + $yborder;
  foreach $row (1 .. $#rows) {
    $baselines[$row] = $baselines[$row - 1] + 
      $rowdec[$row - 1] + $rowac[$row] + $ygap;
  }
  $xmiddles[0] = $colw[0]/2 + $xborder;
  foreach $col (1 .. $#colw) {
    $xmiddles[$col] = $xmiddles[$col - 1] + 
      $colw[$col - 1]/2 + $colw[$col]/2 + $xgap;
  }
  my $tw =  $xmiddles[-1] + $colw[-1]/2 + $xborder;
  my $h = $baselines[-1] + $rowdec[-1] + $yborder;
  my @outrows;
  my @addrows;
  if ($linew) {
    push @addrows, [$blackLine, 0, 0, $tw, $tw, $linew, 0];
    push @addrows, [$blackLine, 0, $h - $linew, $tw, $tw, $linew, 0];
    push @addrows, [$blackLine, 0, 0, $linew, $linew, $h, 0];
    push @addrows, [$blackLine, $tw - $linew, 0, $linew, $linew, $h, 0];
    foreach $col (0 .. $#colw - 1) {
      push @addrows, [$blackLine, 
		      $xmiddles[$col] + ($colw[$col] + $xgap - $linew)/2, 
		      0, $linew, $linew, $h, 0];
    }
  }
  foreach $row (0 .. $#rows) {
    foreach $col (0 .. $#{$rows[$row]}) {
      $#{$rows[$row]->[$col]} = 5;
      splice @{$rows[$row]->[$col]}, 1, 1, 
      $xmiddles[$col] - $rows[$row]->[$col][2]/2,
      $baselines[$row] - $rows[$row]->[$col][5];
      push @outrows, \@{$rows[$row]->[$col]};
    }
    if ($linew) {
      push @addrows, [$blackLine, 0, 
		      $baselines[$row] + $rowdec[$row] + ($ygap - $linew)/2, 
		      $tw, $tw, $linew, 0];
    }
  }
  ([-1, 0, 0, $tw, $tw, $h, $h/2 + $stdAscentHalf], @outrows, @addrows);
}

sub Tk::eText::insertBlock {
  my ($widget, $name) = (shift,shift);
  my @sel = $widget->tag('nextrange','sel','0.0');
  if (@sel) {
    $widget->block( 'insert', $name, $sel[0], $sel[1]);
  } else {
    $widget->block( 'insert', $name, 'insert' );
    $widget->SetCursor('insert-1c');
  }
  $widget->break if shift;
}

sub Tk::eText::insertBlockWithData {
  my ($widget, $name, $data) = (shift,shift,shift);
  my @sel = $widget->tag('nextrange','sel','0.0');
  if (@sel) {
    $widget->block( 'insert', $name, $sel[0], $sel[1]);
    $widget->block( 'data', "$sel[0] + 1 c", $data);
  } else {
    $widget->block( 'insert', $name, 'insert' );
    $widget->block( 'data', 'insert-1c', $data);
    $widget->SetCursor('insert-1c');
  }
  $widget->break if shift;
}

sub Tk::eText::insTag {
  my ($widget, $name) = (shift,shift);
  my @sel = $widget->tag('nextrange','sel','0.0');
  if (@sel) {
    $widget->tag( 'add', $name, $sel[0], $sel[1]);
  } else {
    $widget->tag( 'add', $name, 'insert' );
  }
  $widget->break if shift;
}

sub Tk::eText::remTag {
  my ($widget, $name) = (shift,shift);
  my @sel = $widget->tag('nextrange','sel','0.0');
  if (@sel) {
    $widget->tag( 'remove', $name, $sel[0], $sel[1]);
  } else {
    $widget->tag( 'remove', $name, 'insert' );
  }
  $widget->break if shift;
}

sub Tk::eText::listRange {
  my ($widget, $name) = (shift,shift);
  my @sel = $widget->tag('nextrange','sel','0.0');
  if (@sel) {
    return $widget->block( 'list', $sel[0], $sel[1]);
  } else {
    return $widget->block( 'list', '0.0', 'end' );
  }
}

sub Tk::eText::range2TeX {
  my ($widget, $name) = (shift,shift);
  my @sel = $widget->tag('nextrange','sel','0.0');
  my $contents;
  my $state = { atBeg => 1, blocks => [0], depths => [0], level0 => [],
		tags => [[]], tags_inserted => [0], 
		tag2TeX => [\%tag2TeX_text], need_space => 0,
		char_by_char => 0, by_table => 0
	      };
  my ($b, $e) = ($sel[0], $sel[1]);
  if (!@sel) {
    ($b, $e) = ('0.0', 'end');
  }
  $contents = $widget->block( 'list', $b, $e);
#  my @btags = $widget->tag( 'names', $b );
#  my @etags = $widget->tag( 'names', $e );
#  my @contents = ((map {bless \$_, 'Tk::Text::TagOn'} @btags), 
#		  @$contents, 
#		  (map {bless $_, 'Tk::Text::TagOff'} @etags));

#  print "length: `@btags' ", length @btags, "\n";
#  dumpValue ( \ (
#		 (map {bless $_, 'Tk::Text::TagOn'} \ ( @btags ) ), 
#		 @$contents, 
#		 (map {bless $_, 'Tk::Text::TagOff'} \ ( @etags ) ) ) );
#  dumpValue ("\n");		# To free buffer.
#  return 1;
  
  join  '',			# '||', 
    ( map { $_->insertSelfTeX($state) } @$contents ),
    flashTags($state);		# Depends on order of evaluation :-(
}

# Takes widget, position, and a list reference. The elements of the
# list may be:
# 
# a) strings to insert;
# 
# b) blessed references to blocks
# 
# A block object is a list: name, array of arrays of contents

$biMark = 0;

sub Tk::eText::blockInsert {
  my ($widget, $pos) = (shift,shift);
  my $mark = "bim" . $biMark++;
  $widget->mark('set',$mark, $pos);
  foreach $elt (@_) {
    if (!ref $elt) {	# String to insert
      $widget->insert($mark, $elt);
    } elsif (ref $elt eq 'Tk::Text::Block') {
      my $cnt = 1;
      $widget->block('insert',$elt->[0],$mark);
      my @what;
      while ($cnt <= $#$elt) {
	if (ref $elt->[$cnt]) {
	  @what = @{$elt->[$cnt]};
	} else {
	  @what = $elt->[$cnt];
	}
	$widget->blockInsert("$mark -1 c", @what);
	$widget->insert("$mark -1 c", "\n") if $cnt++ < $#$elt;
      }
    } else {
      warn "Unknown data type `" . (ref $elt) . "' given to blockInsert";
    }
  }
  $biMark--;
  $widget->mark('unset',$mark);
  return;
}

sub listdepth {
  my $d = 0;
  my $din = 0;
  foreach (@_) {
    next unless ref $_ eq 'ARRAY';
    $din = listdepth $_;
    $d = $din if $d < $din;
  }
  return $d;
}

sub Tk::eText::insertBlockWith {
  my ($widget, $name) = (shift,shift);
  $widget->block( 'insert', $name, 'insert' );
  $widget->SetCursor('insert-1c');
  my $d = &listdepth;
}

sub Tk::eText::Save {
  my $widget = shift;
  my $file = shift || 'save.tsf';
  open(SAVE, ">$file") or die "Cannot open $file for write: $!\n";
  my $lines = $widget->index('end');
  $lines =~ s/\.\d+//;
  my $got;
  for $line (1 .. $lines - 1) {
    $got = $widget->block('list', "$line.0", "$line.0+1l");
    print SAVE freeze($got), "\n\n";
  }
  close(SAVE) or die "Cannot close $file for write: $!\n";
}

sub Tk::eText::Load {
  my $widget = shift;
  my $file = shift || 'save.tsf';
  open(SAVE, "<$file") or die "Cannot open $file for read: $!\n";
  my $old = select(SAVE);
  $/ = "\n\n";
  select($old);
  my @got;
  while (<SAVE>) {
    chop; chop;
    @got = thaw $_;
    for $piece (@ {$got[0]}) {
      $piece->insertSelf($widget,'insert');
    }
  }
  close(SAVE) or die "Cannot close $file for read: $!\n";
}

sub TeX::toTeXState::blah {}	# To make a package

sub Tk::Text::String::insertSelfTeX {
  my $self = shift;
  my $state = shift;
  my $chars = $$self;
  my @chars = $chars;
  my ($inmid, @pre, @post, @out) = 0;
  
  if (not $state->{tags_inserted}[-1] 
      or $state->{char_by_char} and length $chars > 1) {
    @pre = pushTags($state);
    @out = @pre unless $state->{tags_inserted}[-1];
  }
  # flashTags has sideeffects, thus pushTags:
  (@post = (flashTags($state), @pre)), pushTags($state), 
    @chars = split //, $chars
      if $state->{char_by_char} and length $chars > 1;
  $state->{tags_inserted}[-1] = 1;
  my $leader;
  my $need_space = $state->{need_space};
  $state->{need_space} = 0;
  my $inmid_need_space = @post || $post[-1] =~ /\\[a-zA-Z]+$/;
  @chars = map { $state->{by_table}->[-1]->[ord $_] || '\unknown' } @chars
    if @{$state->{by_table}};
  for $chars (@chars) {
    #print STDERR "\nDoing `$chars', \@out = `@out'\n";
    
    $need_space = $inmid_need_space if $inmid;
    $need_space = ($out[-1] =~ /\\[a-zA-Z]+$/) if not @post and $inmid;
    $leader = '';
    if ($need_space) {
      if ($chars =~ /^\s/) {
	$leader = '{}';
      } elsif ($chars =~ /^[a-zA-Z]/) {
	$leader = ' ';
      }
    }
    push @out, @post if $inmid++;
    push @out, $leader, $chars;
  }
  $state->{need_space} = ($out[-1] =~ /\\[a-zA-Z]+$/);
  $state->{atBeg} = 0;
  ( @out );
}

sub flashTags {
  my $state = shift;
  my $curtags = $state->{tags}[-1];
  if ($state->{tags_inserted}[-1]) {
    $state->{tags_inserted}[-1] = 0;
    if (@$curtags) {
      if ($state->{need_space}) {
	$state->{need_space} = 0;
      }
      '}' x @$curtags;
    } else {
      ();
    }
  } else {
    ();
  }
}

sub pushTags {
  my $state = shift;
  my $tag2TeX = $state->{tag2TeX}[-1];
  my @out = map { $tag2TeX->{$_} } @{ $state->{tags}[-1] };
  if (@out) {
    if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
      $state->{need_space} = 1;
    } else {
      $state->{need_space} = 0;
    }
  }
  @out;
}

sub Tk::Text::Block::insertSelfTeX {
  my $self = shift;
  my $state = shift;
  my $type = $self->[0];
  my $sub = $block2TeX{$type->[0]};
  return &$sub($self, $state) if $sub;
  push @ {$state->{blocks}}, ($blockTypes{$type->[0]} || 0);
  push @ {$state->{depths}}, $self->[0]->[1];
  push @ {$state->{level0}}, 0;
  # push @ {$state->{level1}}, 0;
  my @out = flashTags($state);
  push @out, $blockStart{$type->[0]} || 
    "\\begin{" . ( $block2Env{$type->[0]} || "block_$type->[0]") . "}";
  push @{ $state->{tags} }, $state->{tags}[-1];
  push @{ $state->{tags_inserted} }, 0;
  # push @out, '{{}}';
  $state->{need_space} = 0;
  $state->{atBeg} = 1;
  push @out, map $_->insertSelfTeX($state), @$self[1 .. $#$self];
  push @out, flashTags($state);
  push @out, $blockEnd{$type->[0]} || 
    "\\end{" . ( $block2Env{$type->[0]} || "block_$type->[0]") . "}";
  pop @{ $state->{tags} };
  pop @{ $state->{tags_inserted} };
  pop @ {$state->{depths}};
  if ( ( $blockLen{$type->[0]} || 0 )
       > 
       $ {$state->{level0}}[-1] ) {
    push @out, ('{}') x ($blockLen{$type->[0]} - $ {$state->{level0}}[-1]);
  }
  pop @ {$state->{level0}};
  # pop @ {$state->{level1}};
  if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
    $state->{need_space} = 1;
  } else {
    $state->{need_space} = 0;
  }
  $state->{atBeg} = 0;		# XXXX ???? Some need, some do not
  @out;
}

sub superSub2TeX {
  my $self = shift;
  return unless @$self > 1;	# Skip empty blocks
  my $state = shift;
  my @out;
  @out = '{}' if $state->{atBeg};
  my $depth = $self->[0]->[1];
  my $depthSub = $depth;
  # push @ {$state->{level1}}, 0;
  unless ($depthSub) {
    $depthSub = grep ref $_ eq 'Tk::Text::BlockSeparator', @$self[1..$#$self];
    $depthSub = 0 if $depthSub <= 1;
  }
  my $c = 1;
  my $next = $self->[1];
  unless (ref $next eq 'Tk::Text::BlockSeparator' and $$next >= $depth) {
    # Have SuperScript
    push @out, ($depth ? '\Sp{' : '^{');
    push @ {$state->{blocks}}, ($depth == 0 ? 0 : 4);
    push @ {$state->{level0}}, 0;
    push @ {$state->{depths}}, $depth;
    push @{ $state->{tags} }, $state->{tags}[-1];
    push @{ $state->{tags_inserted} }, 0;
    $state->{atBeg} = 1;
    $state->{need_space} = 0;
    until ($c > $#$self
	   or ref $next eq 'Tk::Text::BlockSeparator' and $$next >= $depth) {
      push @out, $next->insertSelfTeX($state);
      $next = $self->[++$c];
    }
    push @out, flashTags($state);
    pop @{ $state->{tags} };
    pop @{ $state->{tags_inserted} };
    pop @ {$state->{blocks}};
    pop @ {$state->{depths}};
    pop @ {$state->{level0}};
    push @out, '}';
    return @out if $c >= $#$self;
  }
  $c++;
  $state->{atBeg} = 1;
  push @out, ($depthSub ? '\Sb{' : '_{');
  $state->{need_space} = 0;
  push @ {$state->{level0}}, 0;
  push @ {$state->{blocks}}, ($depthSub == 0 ? 0 : 4);
  push @ {$state->{depths}}, $depthSub;
  push @{ $state->{tags} }, $state->{tags}[-1];
  push @{ $state->{tags_inserted} }, 0;
  push @out, map $_->insertSelfTeX($state), @$self[$c .. $#$self];
  push @out, flashTags($state);
  pop @{ $state->{tags} };
  pop @{ $state->{tags_inserted} };
  pop @ {$state->{blocks}};
  pop @ {$state->{depths}};
  pop @ {$state->{level0}};
  # pop @ {$state->{level1}};
  push @out, '}';
  if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
    $state->{need_space} = 1;
  } else {
    $state->{need_space} = 0;
  }
  $state->{atBeg} = 1;
  @out;
}

sub LR2TeX {
  my $self = shift;
  my $state = shift;
  my $data = $self->[0]->[2];
  my ($l, $r) = ($parens2TeX{substr $data, 0, 1},
		 $parens2TeX{substr $data, 1});
  $l ||= '.';
  $r ||= '.';
  my @out = flashTags($state);
  $state->{atBeg} = 1;
  push @out, '\left' . $l;
  if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
    $state->{need_space} = 1;
  } else {
    $state->{need_space} = 0;
  }
  push @ {$state->{level0}}, 0;
  push @ {$state->{blocks}}, 0;
  push @ {$state->{depths}}, $depthSub;
  push @{ $state->{tags} }, $state->{tags}[-1];
  push @{ $state->{tags_inserted} }, 0;
  push @out, map $_->insertSelfTeX($state), @$self[1 .. $#$self];
  push @out, flashTags($state);
  push @out, '\right' . $r;
  pop @{ $state->{tags} };
  pop @{ $state->{tags_inserted} };
  pop @ {$state->{blocks}};
  pop @ {$state->{depths}};
  pop @ {$state->{level0}};
  # pop @ {$state->{level1}};
  if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
    $state->{need_space} = 1;
  } else {
    $state->{need_space} = 0;
  }
  $state->{atBeg} = 0;
  @out;
}


sub Tk::Text::BlockSeparator::insertSelfTeX {
  my ($self, $state) = (shift, shift);
  my $level = $ {$state->{depths}}[-1] - $$self;
  if ($level) {			# Sublevel
    # $ {$state->{level1}}[-1]++;
  } else {
    # $ {$state->{level1}}[-1] = 0;
    $ {$state->{level0}}[-1]++;
  }
  $state->{atBeg} = 1;
  ( flashTags($state),
    $separators[ $ {$state->{blocks}}[-1]][ $level ] 
    || ( $ {$state->{blocks}}[-1] == 4
	 ? '\\\\'		# SuperSup: everything to \\
	 : ' '),
  );
}

sub Tk::Text::TagOn::insertSelfTeX {
  my ($self, $state) = (shift, shift);
  my $out = $state->{tag2TeX}[-1]{$$self};
  my @out;
  $state->{char_by_char}++ if $char_by_char{$$self};
  push @{$state->{by_table}}, $by_table{$$self} if $by_table{$$self};
  if (defined $out) {
    push @{ $state->{tags}[-1] }, $$self;
    if ($state->{tags_inserted}[-1]) {
      @out = ($out);		# Insert now
    } else {
      return ();
    }
  } elsif ($$self eq 'math') {
    @out = flashTags($state);
    push @{ $state->{tag2TeX} }, \%tag2TeX_math;
    $state->{atBeg} = 1;
    return (@out, '$ ');	# No check for spaces needed
  } elsif ($$self eq 'mathlike') {
    @out = flashTags($state);
    push @{ $state->{tag2TeX} }, \%tag2TeX_math;
  }
  if (@out) {
    if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
      $state->{need_space} = 1;
    } else {
      $state->{need_space} = 0;
    }
  }
  @out;
}

sub Tk::Text::TagOff::insertSelfTeX {
  my ($self, $state) = (shift, shift);
  my $found;
  my @out;
  $state->{char_by_char}-- if $char_by_char{$$self};
  if ($by_table{$$self}) {
    my $table;
    foreach $table (0 .. $#{$state->{by_table}}) {
      (splice @{$state->{by_table}}, $table, 1), last 
	if $state->{by_table}[$table] eq $by_table{$$self}
    }
  }
  if (exists $state->{tag2TeX}[-1]{$$self}) {
    if ( $#{ $state->{tags}[-1] } < 0 ) {
      # warn "TagOff `$$self' when none expected";
    } elsif ( $state->{tags}[-1][-1] eq $$self) { # Optimization
      pop @{ $state->{tags}[-1] };
      $found = 1;
      if ($state->{tags_inserted}[-1]) {
	return '}';			# Insert now
      } else {
	return ();
      }
    } else {
      @out = flashTags($state);
      my $i;
    loop:
      for ($i = -2; $i >= - @{ $state->{tags}[-1] }; $i--) {
	if ( $state->{tags}[-1][$i] eq $$self ) {
	  splice @{ $state->{tags}[-1] }, @{ $state->{tags}[-1] } + $i, 1;
	  $found = 1;
	  last loop;
	}
      }
      unless ($found) {
	# warn "Unexpected TagOff `$$self'";
	# pop @{ $state->{tags}[-1] };
      }
    }
  } elsif ($$self eq 'math') {
    @out = flashTags($state);
    pop @{ $state->{tag2TeX} };
    return (@out, " \$");
  } elsif ($$self eq 'mathlike') {
    @out = flashTags($state);
    pop @{ $state->{tag2TeX} };
  } else {
    return ();
  }
  if (@out) {
    if ($out[-1] =~ /\\[a-zA-Z]+\s*$/) {
      $state->{need_space} = 1;
    } else {
      $state->{need_space} = 0;
    }
  }
  @out;
}


sub Tk::Text::NewLine::insertSelfTeX {
  my ($self, $state) = (shift, shift);
  $state->{need_space} = 0;
  (flashTags($state), "\n\n");
}

sub Tk::Text::MarkRight::insertSelfTeX {()}
sub Tk::Text::MarkLeft::insertSelfTeX {()}
sub Tk::Text::Window::insertSelfTeX {()}

sub UNIVERSAL::insertSelfTeX {()} # { '{' . shift() . '}' }

#sub UNIVERSAL::insertSelf {}
sub Tk::Text::NewLine::insertSelf {}
sub Tk::Text::MarkRight::insertSelf {}
sub Tk::Text::MarkLeft::insertSelf {}
sub Tk::Text::Window::insertSelf {}
sub Tk::Text::TagOn::insertSelf {
  my $self = shift;
  my $widget = shift;
  my $pos = shift || 'insert';
  $widget->{tags}{$$self} = $widget->index($pos);
}

sub Tk::Text::TagOff::insertSelf {
  my $self = shift;
  my $widget = shift;
  my $pos = shift || 'insert';
  $widget->tag('add', $$self, (delete $widget->{tags}{$$self}), $pos)
    if exists $widget->{tags}{$$self};
}

sub Tk::Text::String::insertSelf {
  my $self = shift;
  my $widget = shift;
  my $pos = shift || 'insert';
  $widget->insert($pos, $$self);
}

sub Tk::Text::Block::insertSelf {
  my $self = shift;
  my $widget = shift;
  my $pos = shift || 'insert';
  $pos = $widget->index($pos);	# Make unmovable
  my $type = $self->[0];
  $widget->block('insert', $type->[0], $pos);
  my $markc = $widget->{markc}++;
  my $mark = "au$markc";
  $widget->mark('set', $mark, "$pos + 1c");
  for $piece (@$self[1 .. $#$self]) {
      $piece->insertSelf($widget,$mark);    
  }
  $widget->mark('unset', $mark);
  --$widget->{markc};
}

sub Tk::Text::BlockSeparator::insertSelf {
  my $self = shift;
  my $widget = shift;
  my $pos = shift || 'insert';
  if ($$self) {
    $widget->block('split', $pos, $$self);
  } else {
    $widget->insert($pos, "\n");	# Good for depth 0 only.
  }
}

my $TeXim = 0;
my $lookahead_super;

sub Tk::eText::TeXinsert {
  my($eaten,$txt,$block,$noargs,$tag) = (shift,shift);
  #print STDERR "Got: @{[ref $eaten]} -> `$eaten->[0]'\n";
  
  if (defined $eaten->[1]) {	# There is a comment.
    my $string = $eaten->[1];
    $string =~ s/\n+/\n/s;
    $text->insert('TeXinsert',$string, [@{$text->{activetags}}, 'commentTeX']);
  }
 process: {
    if (ref $eaten eq 'Text::TeX::Text') {
      my $string = $eaten->[0];
      $string =~ s/\s+/ /g;
      $text->insert('TeXinsert', $string, $text->{activetags} );
    } elsif (ref $eaten eq 'Text::TeX::Token') {
      #last process if exists $recognized_args{$eaten->[0]} or 
      # exists $tag_for_args{$eaten->[0]};
      my $exp;
      if (defined ($exp = $Text::TeX::xfont{$eaten->[0]})) {
	$text->insert('TeXinsert', $exp->[1], 
		      [@{$text->{activetags}}, $exp->[0]] );
      } elsif ($tag = $tag_for_args{$eaten->[0]}) {
	push @{$text->{activetags}}, $tag;
      } else {
	$text->insert('TeXinsert', $eaten->[0], 
		      [@{$text->{activetags}}, 'verbTeX'] );
      }
    } elsif (ref $eaten eq 'Text::TeX::Paragraph') {
      $text->insert('TeXinsert', "\n", $text->{activetags});
      $text->update if $do_update;
    } elsif (ref $eaten eq 'Text::TeX::Begin::Group' and $eaten->[0] eq "\$") {
      #push @{$text->{indices}}, $text->index('TeXinsert');
      #push @{$text->{indexinfo}}, $eaten;
      push @{$text->{activetags}}, 'math';
    } elsif (ref $eaten eq 'Text::TeX::End::Group' and $eaten->[0] eq "\$") {
      #my $start = pop @{$text->{indices}};
      #my $prev = pop @{$text->{indicexinfo}};
      pop @{$text->{activetags}};
    } elsif (ref $eaten eq 'Text::TeX::ArgToken' 
	     and $recognized_args{$eaten->[0]->[0]->[0]}) {
      $text->insert('TeXinsert', "\n", $text->{activetags});
    } elsif (ref $eaten eq 'Text::TeX::BegArgsToken' 
	     and $block = $recognized_args{$eaten->[0]->[0]->[0]}
	     or (ref $eaten eq 'Text::TeX::Begin::Group::Args'
		 and ($block = $recognized_args{$eaten->[0]}
		      or $eaten->[0] eq '\begin'
		      and $block = $recognized_envs{$eaten->[3][0][0]}) 
		 and $noargs = 1)) { # Set it, not a conditional.
      $text->block('insert', $block, 'TeXinsert');
      push @{$text->{activeblocks}}, $block;
      push @{$text->{activetags}}, 'mathlike' if $startMath{$block};
      for (@{$text->{activetags}}) {
	$text->tag('add', $_, 'TeXinsert-2c', 'TeXinsert');
      }
      $text->mark('set', 'TeXim' . ++$TeXim, 'TeXinsert');
      $text->mark('set', 'TeXinsert', 'TeXinsert-1c');
      $text->insert('TeXinsert', "\n", $text->{activetags})
	if $eaten->[0]->[0]->[0] eq '_' or $block eq 'Equation';
    } elsif (ref $eaten eq 'Text::TeX::EndArgsToken' 
	     and $block = $recognized_args{$eaten->[0]->[0]->[0]}
	     or (ref $eaten eq 'Text::TeX::End::Group::Args'
		 and ($block = $recognized_args{$eaten->[0]}
		      or $eaten->[0] eq '\end'
		      and $block = $recognized_envs{$eaten->[3][0][0]}) 
		 and $noargs = 1)) { # Set it, not a conditional.
      if ($eaten->[0] eq '\right') {
	my ($left, $right) = ($parens{$eaten->[4][3][0][0]} || ' ', 
			      $parens{$eaten->[3][0][0]} || ' ');
	$text->block('data', 'TeXinsert', "$left$right");
      }
      pop @{$text->{activetags}} if $startMath{$block};
      pop @{$text->{activeblocks}};
      $text->mark('set', 'TeXinsert', "TeXim$TeXim");
      $text->mark('unset', 'TeXim' . ($TeXim--));
    } elsif (ref $eaten eq 'Text::TeX::BegArgsToken' 
	     and $tag = $tag_for_args{$eaten->[0]->[0]->[0]}) {	# e.g. \text
      # $noargs = 1;
      push @{$text->{activetags}}, $tag;
    } elsif (ref $eaten eq 'Text::TeX::BegArgsTokenLookedAhead') {
      $text->mark('set', 'TeXinsert', 
		  $text->block('of','TeXinsert')->[0] . ' +1c') 
	if $lookahead_super;
      $text->block('split', 'TeXinsert', 1) unless $lookahead_super;
      #$text->mark('set', 'TeXinsert', 'TeXinsert-1c') if $lookahead_super;
    } elsif (ref $eaten eq 'Text::TeX::EndArgsToken' 
	     and $tag = $tag_for_args{$eaten->[0]->[0]->[0]}) {
      pop @{$text->{activetags}};
    } elsif (ref $eaten eq 'Text::TeX::LookAhead') {
      $lookahead_super = $eaten->[0]->[4];
    } elsif (ref $eaten eq 'Text::TeX::EndLocal' 
	     and $tag = $tag_for_args{$eaten->[0]->[0]}) {
      @{$text->{activetags}} = grep $_ ne $tag, @{$text->{activetags}};
    } elsif (ref $eaten eq 'Text::TeX::Separator') {
      if ($#{$text->{activeblocks}} >= 0
	  and exists $separators{ $text->{activeblocks}[-1] }
	  and exists $separators{ $text->{activeblocks}[-1] }{ $eaten->[0] }) {
	$text->block('split', 'TeXinsert', 
		     $separators{ $text->{activeblocks}[-1] }{ $eaten->[0] });
      } else {
	$text->insert('TeXinsert', $eaten->[0], 
		      [@{$text->{activetags}}, 'verbTeX']);
      }
    }
    # Ignore Text::TeX::LookAhead
  }
  if (defined $eaten->[3] and not $noargs) {
    my $txt = join '', map {$_->print} @{ $eaten->[3] };
    $text->insert('TeXinsert', $txt, 
		  [@{$text->{activetags}}, 'small', 'orange'] );
  }
}

sub Tk::eText::readTeX {
  my $file = new Text::TeX::OpenFile 't/test.tex', 'defaultact' => \&Tk::eText::TeXinsert;
  $text->mark('set','TeXinsert','0.0');
  my $cur = $text->cget('cursor');
  # $text->configure(cursor => 'watch');
  $text->make_busy;
  $file->process;
  # $text->configure(cursor => $cur);
  $text->unmake_busy;
}

sub Tk::eText::TeX_insert {
  shift;
  $text->mark('set','TeXinsert',shift);
  my $file = new Text::TeX::OpenFile undef, string => shift,
    'defaultact' => \&Tk::eText::TeXinsert;
  my $curs = $text->cget('-cursor');
  # $text->configure(-cursor => 'watch');
  $text->make_busy;
  $file->process;
  # $text->configure(-cursor => $curs);
  $text->unmake_busy;
}

sub Tk::eText::selTeXinsert {
  shift;
  $text->mark('set','TeXinsert',shift);
  my $file = new Text::TeX::OpenFile 
    undef, 
    string => $text->SelectionGet("-selection","CLIPBOARD"),
    'defaultact' => \&Tk::eText::TeXinsert;
  my $curs = $text->cget('-cursor');
  # $text->configure(-cursor => 'watch');
  $text->make_busy;
  $file->process;
  # $text->configure(-cursor => $curs);
  $text->unmake_busy;
}

sub getString {
  unless (Exists($popupString)) {
    my $txt = $text;
    $popupString = $top->Toplevel();
    my $w = $popupString;
    # dpos $w;
    $w->title('Extended Text Demonstration - get TeX');
    $w->iconname('TeX --> eText');

    my $w_t = $w->ScrleText(-setgrid => 'true')->pack(-expand => 'yes', -fill => 'both');
    my $sub = sub {$w->withdraw; 
		   $txt->TeX_insert('insert', $w_t->get('0.0','end'));
		   $txt->focus};
    $w_t->bind('<Control-Return>', $sub);
    my $w_ok = $w->Button(-text => 'OK', 
			  -width => 8, 
			  -command => $sub,
			 )->pack(-side => 'bottom')->focus;

  }
  $popupString->deiconify;
}

sub getSearch {
  unless (Exists($popupSearch)) {
    my $txt = $text;
    $popupSearch = $top->Toplevel();
    my $w = $popupSearch;
    # dpos $w;
    $w->title('Extended Text Demonstration - search');
    $w->iconname('eText search');

    my $w_t = $w->Entry(-width => 40)->pack(-expand => 'yes', -fill => 'both');
    my $sub = sub {$w->withdraw;
		   my $pos = $txt->search($w_t->get, 'insert');
		   $text->mark('set', 'insert', $pos) if defined $pos;
		 };
    $w_t->bind('<Return>', $sub);
    my $w_ok = $w->Button(-text => 'OK',
			  -width => 8,
			  -command => $sub,
			 )->pack(-side => 'bottom');
  }
  $popupSearch->deiconify;
}

