#!/usr/bin/perl
# 	$rcs = ' $Id: etext.t,v 1.8 1996/10/30 20:04:30 ilya Exp ilya $ ';
#
# Interactive demonstration of Tk::eText: editable fractions, radicals,
# super/subscripts, equations, tables, big operators with limits, tables
# with cells spanning columns and rows, with a mini TeX import/export.
# Run it as
#	perl -Mblib demo/etext.pl		(from the build directory)
# or	perl demo/etext.pl			(after "make install")
# See README.etext for the key bindings (Control-Meta-<key> by default,
# $ENV{kprefix} overrides the prefix).
require 5.006;
use FindBin;
use lib "$FindBin::Bin/../utils";	# Text::TeX and FreezeThaw, if not installed
use Tk;

use Tk::eText;
#use Tk::ROText;
require Tk::ErrorDialog;
use FreezeThaw qw(freeze thaw);
use Text::TeX;

# Tk 804 no longer has the Tk-b9 Menubar widget with its command() method;
# this minimal replacement keeps the menu definitions below unchanged.
{
  package Tk::eText::DemoMenubar;
  sub new {
    my ($class, $top) = @_;
    my $f = $top->Frame(-relief => 'raised', -borderwidth => 1);
    $f->pack(-side => 'top', -fill => 'x');
    bless { frame => $f, buttons => {} }, $class;
  }
  sub command {			# (-button => [name, opts...], menu entry opts)
    my ($self, %opt) = @_;
    my $b = delete $opt{-button};
    my ($name, %bopt) = ref $b ? @$b : ($b);
    my %nbopt = map { (/^-/ ? $_ : "-$_") => $bopt{$_} } keys %bopt;
    my $mb = $self->{buttons}{$name} ||=
      $self->{frame}->Menubutton(-text => $name, %nbopt)->pack(-side => 'left');
    $mb->command(%opt);
  }
}


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

# Tag name => { character => TeX control sequence }, for the export.
%by_table = map { ($_ => $Text::TeX::char2tex{$_}) }
  grep { $Text::TeX::char2tex{$_} } qw(symbol cmsy cmex msam msbm frak);

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
$prefix = $ENV{kprefix} || ($^O eq 'os2' ? "Control-Alt-" : "Control-Meta-");

my $not_X;
my $server;

$initialized || do {
  $top = MainWindow->new;
  $not_X = $^O eq 'os2' && ($server = $top->winfo('server')) =~ /win32|os\/2/i;
print "server: `$server', not_X: `$not_X'\n";  

  #Tk::Widget::EnterWidgetMethod("Text","block");
  
  my $mb  = Tk::eText::DemoMenubar->new($top);
  
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

  $text = $text->Subwidget('scrolled');
  $text->focus;

  $testbutton = $text->Button(-text => "Press me!", 
				 -command => sub {print "# OK\n"});
  
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
	       -command => sub {do "$FindBin::Bin/etext.pl"; die $@ if $@;});
  $mb->command(-button => 'File', 
	       -label => 'Load TeX from demo/test.tex', -underline => 5, 
	       -command => [$text, readTeX]);
  $mb->command(-button => 'File', -label => 'Debug off', -underline => 6, 
	       # -accelerator => "<${prefix}q>",
	       -command => [ $text, 'debug', 'no'] );
  $mb->command(-button => 'File', -label => 'Debug on', -underline => 0, 
	       # -accelerator => "<${prefix}q>",
	       -command => [ $text, 'debug', 'yes'] );
  $mb->command(-button => 'File', 
	       -label => 'To TeX', -underline => 0,
	       -accelerator => "<${prefix}l>",
	       -command => sub {print ($text->range2TeX, "\n")});
  $mb->command(-button => 'File', -label => 'Quit', -underline => 0, 
	       -accelerator => "<${prefix}q>",
	       -command => [ sub {exit(0)}] );

  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Int Copy', -underline => 4, 
	       -command => sub { 
		 my @sel = $text->tag('nextrange', 'sel', '0.0');
		 undef $sel;
		 $sel = $text->block('list', @sel) if @sel;
		 ::dumpValue($sel);
	       });
  $mb->command(-button => ['Edit', underline => 0],
	       -label => 'Int Paste', -underline => 4, 
	       -command => sub {
		 return unless $sel;
		 for $piece (@$sel) {
		   ::dumpValue $piece;
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
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}o>",
	       -label => 'Big operator', -underline => 4,
	       -command => [ $text, 'insertOpLimits', 'insert' ] );
  $mb->command(-button => ['Insert', underline => 0],
	       -accelerator => "<${prefix}g>",
	       -label => 'Span table', -underline => 5,
	       -command => [ $text, 'insertSpanTable', 'insert', 2, 2 ] );

  $mb->command(-button => ['Cell', underline => 0],
	       -accelerator => "<${prefix}h>",
	       -label => 'Span one more column', -underline => 9,
	       -command => [ $text, 'growSpan', 'insert', 1, 0 ] );
  $mb->command(-button => ['Cell', underline => 0],
	       -accelerator => "<${prefix}j>",
	       -label => 'Span one more row', -underline => 9,
	       -command => [ $text, 'growSpan', 'insert', 0, 1 ] );
  $mb->command(-button => ['Cell', underline => 0],
	       -label => 'Span one column less', -underline => 5,
	       -command => [ $text, 'growSpan', 'insert', -1, 0 ] );
  $mb->command(-button => ['Cell', underline => 0],
	       -label => 'Span one row less', -underline => 9,
	       -command => [ $text, 'growSpan', 'insert', 0, -1 ] );
  $mb->command(-button => ['Cell', underline => 0],
	       -accelerator => "<${prefix}k>",
	       -label => 'No span', -underline => 0,
	       -command => [ $text, 'setSpan', 'insert', 1, 1 ] );

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
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Big operators', -underline => 0,  -accelerator => '<F6>',
	       -command => [ $text, 'exampleOpLimits', 'insert' ] );
  $mb->command(-button => ['Examples', underline => 0],
	       -label => 'Span tables', -underline => 1,  -accelerator => '<F7>',
	       -command => [ $text, 'exampleSpanTables', 'insert' ] );

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

  # Ornaments (2.08): drawings over or under the text that follow it.
  $mb->command(-button => ['Ornaments', underline => 0],
	       -label => 'Box under selection', -underline => 0,
	       -command => [ $text, 'ornBoxSelection' ] );
  $mb->command(-button => ['Ornaments', underline => 0],
	       -label => 'Arrow from mark', -underline => 0,
	       -command => [ $text, 'ornArrowFromMark' ] );
  $mb->command(-button => ['Ornaments', underline => 0],
	       -label => 'Brace under selection', -underline => 1,
	       -command => [ $text, 'ornBraceSelection' ] );
  $mb->command(-button => ['Ornaments', underline => 0],
	       -label => 'Remove all', -underline => 0,
	       -command => [ $text, 'ornRemoveAll' ] );

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
  $symbolfont = '-*-Tms Rmn-*-*-*-*-20-*-*-*-*-*-*-*';
  $bigopfont = '-*-Tms Rmn-*-*-*-*-34-*-*-*-*-*-*-*';
} else {
  $mainfont = '10x20';
  $italicfont = '-*-Courier-*-O-*-*-20-*-*-*-*-*-*-*';
  $boldfont = '-*-Courier-Bold-*-*-*-20-*-*-*-*-*-*-*';
  $cmsyfont = '-*-Times-*-I-*-*-24-*-*-*-*-*-*-*';
  $cmexfont = '-*-Times-*-I-*-*-24-*-*-*-*-*-*-*';
  $frakfont = '-*-Times-Bold-I-*-*-24-*-*-*-*-*-*-*';
  $msbmfont = '-*-Times-Bold-*-*-*-24-*-*-*-*-*-*-*';
  $smallfont = '6x10';
  # The symbols are Unicode characters now, so any font with the glyphs
  # will do (Tk falls back to other fonts for missing glyphs anyway).
  $symbolfont = '-*-Times-*-*-*-*-20-*-*-*-*-*-*-*';
  $bigopfont = '-*-Times-Medium-R-*-*-34-*-*-*-*-*-*-*'; # Big operators.
}

destroy $popupString if Exists $popupString;

$top->title('Extended Text Demonstration');
#@a = %$text;
#print "$text\n@a\n", ;

#$text->pack(-side => 'bottom', -expand => 'yes', -fill => 'both');

$text->debug("yes");

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
  -insertwidth => 6, -height => 25, -width => 35, -font => $mainfont,
  -undo => 1);			# Control-z undoes, blocks included

$text->block('configure', 'Std', "-layoutcmd" => \&recursiveLayout,
	     '-layoutdepth' => -1, 
	     '-layoutwidths' => [[1,12]]);

# The bar of a fraction follows from the boxes alone: a template
# (-ornaments), drawn for every Fraction, 2 pixels thick just under the
# numerator (leaf 0), from the left to the right of the block, 1 pixel
# in from each side.
$text->block('configure', 'Fraction', "-layoutcmd" => \&layoutFraction,
	     '-layoutdepth' => 1, 
	     '-layoutwidths' => [2],
	     -ornaments =>
	     [['line', [offset => [xy => [block => 'w'], [leaf => 0, 's']], 1, 1],
	       [offset => [xy => [block => 'e'], [leaf => 0, 's']], -1, 1],
	       -width => 2]]);

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

# A big operator with limits, R( op | Lower( l1 | l2 ... ) | upper | index ):
# a ragged tree, given to the callback as it is (no -layoutdepth).
$text->block('configure', 'OpLimits', -layoutcmd => \&layoutOpLimits);

# A table whose cells may span columns and rows, R( Row( c | c ...) | ...):
# the spans are the values of the cells (see layoutSpanTable).
$text->block('configure', 'SpanTable', -layoutcmd => \&layoutSpanTable);

#$text->block('configure', 'Tab', "-layoutcmd" => sub {layoutTab(5, 35, @_)},
#	     -empty => 'on');

#@conf = $text->block('configure', 'std');
#@conf = $text->block('configure', 'Std');
#dumpvar("main","conf");

$text->bind( "<${prefix}n>",sub {do "$FindBin::Bin/etext.pl"; die $@ if $@; $text->break});
$text->bind( "<${prefix}q>",sub {exit(0)});
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
	    sub {$text->window( 'create', 'insert', -window => $testbutton);
	         $text->break});
$text->bind( "<${prefix}o>", ['insertOpLimits', 'insert', 1]);
$text->bind( "<${prefix}g>", ['insertSpanTable', 'insert', 2, 2, 1]);
$text->bind( "<${prefix}h>", ['growSpan', 'insert', 1, 0, 1]);
$text->bind( "<${prefix}j>", ['growSpan', 'insert', 0, 1, 1]);
$text->bind( "<${prefix}k>", ['setSpan', 'insert', 1, 1, 1]);

my $default_bindtags = [$text, ref $text, $text->toplevel,'all'];
my $busy_bindtags = ['Tk::ROText', $text->toplevel,'all'];
require Tk::ROText;
Tk::ROText->bindRdOnly($text);

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

# The owner's notation OpLimits{\x{2211}|(p=17|p is prime)|1000|*}: the
# operator, the lower limit (a node of two lines), the upper limit and
# the index, here a starred sum.
sub opLimitsPrimes {
  mkBlock('OpLimits', mkTagged("\x{2211}", 'bigop'),
	  mkNode('p=17', 'p is prime'), '1000', '*');
}

sub Tk::eText::exampleOpLimits {
  shift->blockInsert(shift, 
		     opLimitsPrimes(), " f(p) + ",
		     # \int_0^{1/2}: a leaf (not a node) as the lower limit,
		     # a fraction in the upper one, no index.
		     mkBlock('OpLimits', mkTagged("\x{222B}", 'bigop'), '0',
			     [mkBlock('Fraction', '1', '2')]),
		     " g + ",
		     # Three lines below, empty upper limit and index.
		     mkBlock('OpLimits', mkTagged("\x{220F}", 'bigop'),
			     mkNode('i=1', 'i odd', 'i<n'), '', ''),
		     " h");
}

# What editing can leave: the operator alone (a single leaf), an empty
# operator and lower limit, a lower limit with nodes in it, children
# after the index.
sub Tk::eText::exampleOpLimitsOdd {
  my ($widget, $pos) = @_;
  $widget->blockInsert($pos,
		       mkBlock('OpLimits', mkTagged("\x{2211}", 'bigop')), " ",
		       mkBlock('OpLimits', '', mkNode(''), 'n'), " ",
		       mkBlock('OpLimits', mkTagged("\x{22C3}", 'bigop'),
			       mkNode('k', mkNode('a', 'b')), 'N', '2',
			       'extra', mkNode('more', 'lines')),
		       " ");
}

# Two tables.  The first has a header of two rows: "Name" spans them,
# "Results" spans the two columns of "A" and "B" (the second row lists
# only "A" and "B": "Name" covers its first slot).  In the second, the
# note spans two short rows and is taller than both: they grow.
sub Tk::eText::exampleSpanTables {
  my ($widget, $pos) = @_;
  $widget->blockInsert($pos,
    mkBlock(['SpanTable', newSpanTableKey()],
	    mkNode(mkValued('Name', { rows => 2 }),
		   mkValued('Results', { cols => 2 })),
	    mkNode('A', 'B'),
	    mkNode('alpha', '1', '2'),
	    mkNode('beta', '3', [mkBlock('Fraction', '1', '2')])),
    "  ",
    mkBlock(['SpanTable', newSpanTableKey()],
	    mkNode('Item', 'Note'),
	    mkNode('x', mkValued(mkNode('This note', 'is four lines',
					'tall: the rows', 'it spans grow'),
				 '1x2')),
	    mkNode('y'),
	    mkNode('z', 'short')));
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
$text->bind( "<F6>", ['exampleOpLimits', 'insert']);
$text->bind( "<F7>", ['exampleSpanTables', 'insert']);
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
$text->tag('configure', 'bigop', -font => $bigopfont);
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
  
  # "Stolen" lines (block addline) used by the layout procedures below
  # as pictures: the delimiters of LR and the backgrounds.  (Originally
  # glyph codes of the X11 "symbol" font; Perl/Tk 804 wants Unicode.)
  # The strokes (the radical sign, the bars of fractions, the rules of
  # tables, the lines of Std) are ornaments since 2.08: see rule() and
  # layoutRadical, and the -ornaments of Fraction.
  foreach $symb (split '', ' {}[]()<>|') {
    $text->insert('1.0', "$symb\n", [qw()]);
    $LR{$symb} = $text->block('addline', '1.0');
    $text->delete('1.0', '2.0');	# whole ornament line (indices count bytes)
  }
  $text->insert('1.0', "\x{239C}\x{239C}\n", [qw(symbol)]); # paren extensions
  $LR{'\\'} = $text->block('addline', '1.0'); # Douple |
  $text->delete('1.0', '2.0');	# whole ornament line (indices count bytes)
  
  $text->insert('1.0', " \n", [qw(backgr3)]);
  $LR{' '} = $text->block('addline', '1.0'); # Douple |
  $text->delete('1.0', '2.0');	# whole ornament line (indices count bytes)
  
  foreach (0 .. 3) {		# Floor and ceiling
    $text->insert('1.0', substr("\x{23A3}\x{23A6}\x{23A1}\x{23A4}", $_, 1) . "\n", 
		  [qw(symbol)]);
    $LR{substr("FfCc", $_, 1)} = $text->block('addline', '1.0');
    $text->delete('1.0', '2.0');	# whole ornament line (indices count bytes)
  }
  
  $LR{'['} = [undef, $LR{'C'}, $LR{'F'}];
  
  $text->insert('1.0', "\n", [qw(backgr1)]);
  $backgrId1 = $text->block('addline', '1.0');
  $text->delete('1.0', '2.0');	# whole ornament line (indices count bytes)
  
  $text->insert('1.0', "\n", [qw(backgr2)]);
  $backgrId2 = $text->block('addline', '1.0');
  $text->delete('1.0', '2.0');	# whole ornament line (indices count bytes)
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
  $text->insert('1.0', "\x{239C}\x{239C}\n", [qw(backgr3 symbol)]);
}

# The examples of the big operators and the tables, below the rest.
sub init_contents2 {
  $text->insert('end', "\nA starred sum over primes: ");
  $text->blockInsert('end - 1 c', opLimitsPrimes());
  $text->insert('end', ".\nMore: ");
  $text->exampleOpLimits('end - 1 c');
  $text->insert('end', "\nTables:\n");
  $text->exampleSpanTables('end - 1 c');
}

sub init_contents1 {
  my @abc;
  splice @abc, 0,0, ();		# To be able to set a breakpoint
  $text->TeX_insert('insert', ' a^b_c ');
}

init_contents1();
init_contents2();

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

# A rule: a black box (x, y, width, height), as an ornament returned
# by a layout callback (a filled rectangle, in block coordinates).
sub rule {
  my ($x, $y, $w, $h) = map int, @_;	# Whole pixels, as stolen lines.
  ['rectangle', $x, $y, $x + $w, $y + $h, -fill => 'black', -outline => undef];
}

# Moves an additional element of a layout result: an ornament (its
# coordinates, up to its options) or a stolen line (its x and y).
sub shiftEntry {
  my ($e, $dx, $dy) = @_;
  if ($e->[0] =~ /^[a-z]/) {
    for (my $i = 1; $i + 1 < @$e and $e->[$i] !~ /^-[a-z]/; $i += 2) {
      $e->[$i] += $dx;
      $e->[$i + 1] += $dy;
    }
  } else {
    $e->[1] += $dx;
    $e->[2] += $dy;
  }
  $e;
}

sub descendTree {
  my ($dx, $dy, $res, $add, @tree) = @_;
  #dumpValue (\@_);
  for (@$add) {
    shiftEntry($_, $dx, $dy);
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
    push(@addl, rule(0, $trow->[2] + $trow->[5]/2, $treelineLen, $treeline));
  }
  push(@addl, rule(0, $uppermid, $treeline, $lowermid - $uppermid));
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
	    );			# The bar: the -ornaments of Fraction.
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

# The radical sign is a broken line drawn by the callback (ornaments):
# a short tick rising to the right, a stroke down to the bottom of the
# block (thicker), a long one up to the top left of the contents, and
# the bar over them.  It grows with the contents: the tick stays near
# the bottom, the sign gets a little wider with the height.
sub layoutRadical {		# block x row
  my ($block, $x, $row) = (shift, shift, shift);
  my ($w, $h) = @$row[2, 4];
  my $addHeight = 3;		# Room above the contents for the bar.
  my $H = $h + $addHeight + 1;	# The block; the stroke ends at $H - 1.
  my $sw = 8 + int($H / 12);	# The width of the sign.
  my $xoff = $sw + 2;		# The contents.
  my $wtot = $xoff + $w + 1;
  my $b = $row->[5] + $addHeight;
  my $tickY = $H - 1 - ($H * 0.45 < 9 ? int($H * 0.45) : 9);
  my @tick = (0, $tickY + 3);
  my @peak = (int($sw * 0.3), $tickY);
  my @bottom = (int($sw * 0.55), $H - 1);
  my @top = ($sw, 1);
  $row->[1] = $xoff;
  splice @$row, 2, 0, $addHeight;
  $#$row = 6;
  ([-1, 0, 0, $wtot, $wtot, $H, $b],
   $row,
   ['line', @tick, @peak, @bottom, @top, $wtot - 1, 1, -width => 1],
   ['line', @peak, @bottom, -width => 2]);
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
  if ($linew) {			# The rules: ornaments.
    push @addrows, rule(0, 0, $tw, $linew);
    push @addrows, rule(0, $h - $linew, $tw, $linew);
    push @addrows, rule(0, 0, $linew, $h);
    push @addrows, rule($tw - $linew, 0, $linew, $h);
    foreach $col (0 .. $#colw - 1) {
      push @addrows, rule($xmiddles[$col] + ($colw[$col] + $xgap - $linew)/2,
			  0, $linew, $h);
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
    if ($linew and $row < $#rows) {
      push @addrows, rule(0, $baselines[$row] + $rowdec[$row] + ($ygap - $linew)/2,
			  $tw, $linew);
    }
  }
  ([-1, 0, 0, $tw, $tw, $h, $h/2 + $stdAscentHalf], @outrows, @addrows);
}

# Boxes, for the layouts of OpLimits and SpanTable, which get the tree
# as it is (ragged, a single leaf, any number of children).  A box is
# { w => width, h => height, b => baseline (from its top),
#   leaves => [[1, x, y, w, w, h, b], ...]	# its leaves, in order
#   add => [[id, x, y, w, w, h, b], ...] }	# lines and ornaments
# with the coordinates relative to its upper-left corner.

sub leafBox {			# An argument of a layout callback: a leaf.
  my $l = shift;
  my ($w, $h, $b) = map { int($_ || 0) } @$l[2, 4, 5];
  { w => $w, h => $h, b => $b, leaves => [[1, 0, 0, $w, $w, $h, $b]],
    add => [], leaf => 1 };
}

sub moveBox {
  my ($box, $dx, $dy) = @_;
  for (@{$box->{leaves}}, @{$box->{add}}) {
    shiftEntry($_, $dx, $dy);
  }
  $box;
}

sub stackBox {			# One under another, centered; the
				# baseline is the first one's.
  my @kids = @_;
  my $w = 0;
  for (@kids) { $w = $_->{w} if $w < $_->{w} }
  my $y = 0;
  my $box = { w => $w, b => (@kids ? $kids[0]{b} : 0),
	      leaves => [], add => [] };
  for (@kids) {
    moveBox($_, int(($w - $_->{w})/2), $y);
    $y += $_->{h};
    push @{$box->{leaves}}, @{$_->{leaves}};
    push @{$box->{add}}, @{$_->{add}};
  }
  $box->{h} = $y;
  $box;
}

# An argument: a leaf, or a node (a list); with $empty, its empty
# leaves get squares of this size (see placeholder).
sub argBox {
  my ($arg, $empty) = @_;
  return placeholder(leafBox($arg), $empty) unless ref $arg->[0];
  stackBox(map argBox($_, $empty), @$arg);
}

sub mergeBox {			# Add the leaves and ornaments of boxes
  my $box = shift;		# placed inside $box.
  for (@_) {
    push @{$box->{leaves}}, @{$_->{leaves}};
    push @{$box->{add}}, @{$_->{add}};
  }
  $box;
}

# An empty leaf gets a small raised square of $size pixels, to see
# where to type.
sub placeholder {
  my ($box, $size) = @_;
  return $box unless $size and $box->{leaf} and $box->{w} == 0;
  my $h = $size + 2;
  $h = $box->{h} if $h > $box->{h};
  $box->{w} = $size;
  my $y = int(($box->{h} - $h)/2);
  push @{$box->{add}}, [$backgrId2, 0, $y, $size, $size, $h, $h];
  $box;
}

# OpLimits: R( op | lower | upper | index | extra ... ).  The operator is
# centered in a column, the upper limit above it, the lower limit below
# it (a node: its lines stacked, centered), the index to the right of
# the operator at superscript height; children after the fourth go to
# the right, on the baseline.  Missing children are not drawn, a node
# where a leaf is expected is a stack of its leaves, an empty limit is
# a small square.  The baseline is on the operator's axis.
sub layoutOpLimits {
  my ($data, $x, @kids) = @_;
  my $gap = 2;
  my ($op, $lower, $upper, $index, @extra) = map argBox($_, 8), @kids;
  $op = argBox($kids[0], 14);
  my $colw = 0;
  for (grep defined, $op, $lower, $upper) { $colw = $_->{w} if $colw < $_->{w} }
  my $y = 0;
  if ($upper) {
    moveBox($upper, int(($colw - $upper->{w})/2), 0);
    $y = $upper->{h} + $gap;
  }
  my $opy = $y;
  my $opx = int(($colw - $op->{w})/2);
  moveBox($op, $opx, $opy);
  $y += $op->{h};
  if ($lower) {
    $y += $gap;
    moveBox($lower, int(($colw - $lower->{w})/2), $y);
    $y += $lower->{h};
  }
  my ($top, $bottom, $right) = (0, $y, $colw);
  if ($index) {
    my $ix = $opx + $op->{w} + $gap;
    # Its baseline at 2/5 of the ascent of the operator, but not into
    # an upper limit that reaches over it.
    my $iy = $opy + int($op->{b} * 2/5) - $index->{b};
    $iy = $opy if $upper and $iy < $opy
      and int(($colw - $upper->{w})/2) + $upper->{w} > $ix;
    moveBox($index, $ix, $iy);
    $top = $iy if $top > $iy;
    $bottom = $iy + $index->{h} if $bottom < $iy + $index->{h};
    $right = $ix + $index->{w} if $right < $ix + $index->{w};
  }
  my $base = $opy + int($op->{h}/2) + $stdAscentHalf;	# The axis.
  for (@extra) {
    my ($ex, $ey) = ($right + $gap + 2, $base - $_->{b});
    moveBox($_, $ex, $ey);
    $right = $ex + $_->{w};
    $top = $ey if $top > $ey;
    $bottom = $ey + $_->{h} if $bottom < $ey + $_->{h};
  }
  my $all = mergeBox({ leaves => [], add => [] },
		     grep defined, $op, $lower, $upper, $index, @extra);
  moveBox($all, 0, -$top) if $top;
  $base -= $top;
  $bottom -= $top;
  $bottom = $base if $bottom < $base;
  ([-1, 0, 0, $right, $right, $bottom, $base],
   @{$all->{leaves}}, @{$all->{add}});
}

# SpanTable: R( Row( cell | cell ... ) | Row( ... ) ... ).  A cell may
# span columns and rows: its value (block nodedata, at level 0 for a
# cell that is a leaf) is { cols => 2, rows => 3 } or the string "2x3"
# (columns x rows).  As in HTML, a slot covered by a cell spanning from
# above is not in the later rows: the cells of a row take the next
# free slots from the left, and a row may be shorter than others (the
# slots left are holes, without rules).  A span reaching past the last
# row stops there.  The columns are as wide and the rows as tall as
# their widest and tallest cell, and a cell spanning several of them
# that does not fit makes them wider (taller), equally.  The cells of
# a row share its baseline; a cell spanning rows is centered in them.
# Rules go between the cells and around the table, not across a cell.
# Degenerate trees: a row that is a leaf is a row of one cell; a cell
# that is a node (block sprout) is a cell of its leaves stacked (its
# span is the node's value); a block that is a single leaf is a table
# of one cell.
#
# The layout callback gets no values: it finds them in "block list" of
# the text, as the node values of the SpanTable block whose instance
# data is the very reference it got (insertSpanTable gives every table
# a hash of its own; a table without instance data has no spans).  And
# setting a value does not redisplay: setSpan sets the instance data
# again, which does.

sub spanTableValues {
  my $data = shift;
  my ($widget, $key) = @$data[1, 2];
  return undef unless ref $key;
  my @todo = $widget->block('list', '1.0', 'end');
  while (@todo) {
    my $e = shift @todo;
    next unless ref $e eq 'Tk::Text::Block';
    my $head = $e->[0];
    return $head->[3] if $head->[0] eq 'SpanTable' and ref $head->[2]
      and $head->[2] == $key;	# The same reference.
    push @todo, @$e[1 .. $#$e];
  }
  undef;
}

sub cellSpan {			# An element of the tree of values.
  my $v = shift;
  my $s = ref $v eq 'ARRAY' ? $v->[0] : undef;
  my ($c, $r) = (1, 1);
  if (ref $s eq 'HASH') {
    ($c, $r) = ($s->{cols}, $s->{rows});
  } elsif (defined $s and !ref $s and $s =~ /^\s*(\d+)\s*x\s*(\d+)\s*$/) {
    ($c, $r) = ($1, $2);
  }
  map { (defined $_ and /^\d+$/ and $_ >= 1) ? ($_ > 100 ? 100 : $_) : 1 }
    $c, $r;
}

sub layoutSpanTable {
  my ($data, $x, @rows) = @_;
  my ($padx, $pady, $lw) = (4, 2, 1);
  my $values = spanTableValues($data);
  # A single leaf has the tree of values [value].
  $values = [undef, $values] if $values and @$values == 1;
  my (@cells, @owner);
  my $nrows = @rows;
  my $ncols = 0;
  foreach my $r (0 .. $#rows) {
    my $row = $rows[$r];
    my $rv = $values ? $values->[$r + 1] : undef;
    my @kids = ref $row->[0] ? @$row : ($row);
    my @kv = ref $row->[0] ? (ref $rv ? @$rv[1 .. $#$rv] : ()) : ($rv);
    my $c = 0;
    foreach my $k (0 .. $#kids) {
      $c++ while defined $owner[$r][$c];
      my ($cs, $rs) = cellSpan($kv[$k]);
      $rs = $nrows - $r if $r + $rs > $nrows;
      my $cell = { box => argBox($kids[$k]), r => $r, c => $c,
		   cs => $cs, rs => $rs, n => scalar @cells };
      push @cells, $cell;
      foreach my $rr ($r .. $r + $rs - 1) {
	foreach my $cc ($c .. $c + $cs - 1) {
	  $owner[$rr][$cc] = $cell->{n};
	}
      }
      $c += $cs;
      $ncols = $c if $ncols < $c;
    }
  }
  # Sizes: first the cells in one column (row), then the others, the
  # narrow (short) spans first.
  my (@colw, @rowa, @rowd);
  $colw[$_] = 0 for 0 .. $ncols - 1;
  $rowa[$_] = $rowd[$_] = 0 for 0 .. $nrows - 1;
  my $sep = $lw + 2*$padx;	# Between two columns' contents.
  foreach my $cell (sort { $a->{cs} <=> $b->{cs} } @cells) {
    my ($c, $cs, $w) = (@$cell{qw(c cs)}, $cell->{box}{w});
    my $have = ($cs - 1) * $sep;
    $have += $colw[$_] for $c .. $c + $cs - 1;
    next if $have >= $w;
    my $more = $w - $have;
    $colw[$_] += int($more/$cs) for $c .. $c + $cs - 1;
    $colw[$c + $cs - 1] += $more % $cs;
  }
  foreach my $cell (grep $_->{rs} == 1, @cells) {
    my ($r, $b) = ($cell->{r}, $cell->{box}{b});
    my $d = $cell->{box}{h} - $b;
    $rowa[$r] = $b if $rowa[$r] < $b;
    $rowd[$r] = $d if $rowd[$r] < $d;
  }
  my $vsep = $lw + 2*$pady;
  foreach my $cell (sort { $a->{rs} <=> $b->{rs} } grep $_->{rs} > 1, @cells) {
    my ($r, $rs, $h) = (@$cell{qw(r rs)}, $cell->{box}{h});
    my $have = ($rs - 1) * $vsep;
    $have += $rowa[$_] + $rowd[$_] for $r .. $r + $rs - 1;
    next if $have >= $h;
    my $more = $h - $have;
    $rowd[$_] += int($more/$rs) for $r .. $r + $rs - 1;
    $rowd[$r + $rs - 1] += $more % $rs;
  }
  # The grid lines (their left or upper edges).
  my (@xl, @yl) = (0);
  $xl[$_ + 1] = $xl[$_] + $sep + $colw[$_] for 0 .. $ncols - 1;
  $yl[0] = 0;
  $yl[$_ + 1] = $yl[$_] + $vsep + $rowa[$_] + $rowd[$_] for 0 .. $nrows - 1;
  my ($tw, $th) = ($xl[$ncols] + $lw, $yl[$nrows] + $lw);
  my $table = { leaves => [], add => [] };
  foreach my $cell (@cells) {
    my ($r, $c, $rs, $cs, $box) = @$cell{qw(r c rs cs box)};
    my $aw = $xl[$c + $cs] - $xl[$c] - $sep;
    my $ah = $yl[$r + $rs] - $yl[$r] - $vsep;
    my $cx = $xl[$c] + $lw + $padx + int(($aw - $box->{w})/2);
    my $cy = $yl[$r] + $lw + $pady
      + ($rs == 1 ? $rowa[$r] - $box->{b} : int(($ah - $box->{h})/2));
    mergeBox($table, moveBox($box, $cx, $cy));
  }
  # Rules: where the slots on the two sides of a grid line belong to
  # different cells (outside the table: 'o', a hole: 'h').
  my $slot = sub {
    my ($r, $c) = @_;
    return 'o' if $r < 0 or $c < 0 or $r >= $nrows or $c >= $ncols;
    defined $owner[$r][$c] ? $owner[$r][$c] : 'h';
  };
  foreach my $i (0 .. $nrows) {	# Horizontal rules, in runs.
    my $from;
    foreach my $c (0 .. $ncols) {
      my $draw = $c < $ncols && $slot->($i - 1, $c) ne $slot->($i, $c);
      if ($draw and !defined $from) {
	$from = $c;
      } elsif (!$draw and defined $from) {
	my $len = $xl[$c] + $lw - $xl[$from];
	push @{$table->{add}}, rule($xl[$from], $yl[$i], $len, $lw);
	undef $from;
      }
    }
  }
  foreach my $j (0 .. $ncols) {	# Vertical rules, in runs.
    my $from;
    foreach my $r (0 .. $nrows) {
      my $draw = $r < $nrows && $slot->($r, $j - 1) ne $slot->($r, $j);
      if ($draw and !defined $from) {
	$from = $r;
      } elsif (!$draw and defined $from) {
	push @{$table->{add}}, rule($xl[$j], $yl[$from], $lw,
				    $yl[$r] + $lw - $yl[$from]);
	undef $from;
      }
    }
  }
  ([-1, 0, 0, $tw, $tw, $th, int($th/2) + $stdAscentHalf],
   @{$table->{leaves}}, @{$table->{add}});
}

# The Ornaments menu.  The indices are plain ones (the selection's
# ends resolved now): each becomes a private mark of the ornament, so
# that it follows its characters, and goes with them when they are
# deleted.

sub Tk::eText::ornSelection {	# The ends of the selection, or ().
  my $w = shift;
  my @r = $w->tagRanges('sel');
  @r ? ($w->index($r[0]), $w->index($r[-1])) : ();
}

# A light box under the selected text, a little larger than its range.
sub Tk::eText::ornBoxSelection {
  my $w = shift;
  my ($f, $l) = $w->ornSelection or return $w->bell;
  $w->ornamentCreate('rectangle', [offset => [range => $f, $l, 'nw'], -2, -1],
		     [offset => [range => $f, $l, 'se'], 2, 1],
		     -fill => '#fff2a8', -outline => undef, -layer => 'under');
}

# First use: the start of the selection becomes the origin of an arrow
# (the mark ornArrowFrom).  Second use: an arched red arrow from there
# to the top of the selection; the origin is forgotten.
sub Tk::eText::ornArrowFromMark {
  my $w = shift;
  my ($f, $l) = $w->ornSelection or return $w->bell;
  unless (grep { $_ eq 'ornArrowFrom' } $w->markNames) {
    $w->markSet(ornArrowFrom => $f);
    return;
  }
  my $from = $w->index('ornArrowFrom');
  $w->markUnset('ornArrowFrom');
  my ($a, $b) = ([at => $from, 'n'], [range => $f, $l, 'n']);
  $w->ornamentCreate('line', $a, [offset => [mix => 1, $a, 1, $b], 0, '-1.5em'], $b,
		     -smooth => 1, -arrow => 'last', -fill => 'red', -width => 2);
}

# An underbrace under the selection: a smoothed line from its left end
# down and across to the middle, a point down there, and back up to its
# right end; the sizes in em of the largest font of the selection.
sub Tk::eText::ornBraceSelection {
  my $w = shift;
  my ($f, $l) = $w->ornSelection or return $w->bell;
  my $p = sub { [offset => [range => $f, $l, $_[0]], $_[1], $_[2]] };
  # A point twice: the line passes through it (a corner).
  $w->ornamentCreate('line',
		     $p->('sw', 0, '0.1em'), $p->('sw', 0, '0.5em'),
		     $p->('sw', '0.5em', '0.5em'), $p->('s', '-0.5em', '0.5em'),
		     $p->('s', 0, '0.5em'), $p->('s', 0, '1em'), $p->('s', 0, '1em'),
		     $p->('s', 0, '0.5em'), $p->('s', '0.5em', '0.5em'),
		     $p->('se', '-0.5em', '0.5em'), $p->('se', 0, '0.5em'),
		     $p->('se', 0, '0.1em'),
		     -smooth => 1, -fill => 'blue', -width => 1);
}

sub Tk::eText::ornRemoveAll {
  my $w = shift;
  $w->ornamentDelete($w->ornamentNames);
  $w->markUnset('ornArrowFrom') if grep { $_ eq 'ornArrowFrom' } $w->markNames;
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

# A big operator with empty limits and index (or, with a selection, an
# OpLimits block around it, as the other types).
sub Tk::eText::insertOpLimits {
  my ($widget, $pos, $break) = @_;
  if ($widget->tag('nextrange','sel','0.0')) {
    $widget->insertBlock('OpLimits');
  } else {
    $widget->mark('set', 'opLimits', $pos);
    $widget->mark('gravity', 'opLimits', 'left');
    $widget->blockInsert($pos, mkBlock('OpLimits', mkTagged("\x{2211}", 'bigop'),
				       mkNode(''), '', ''));
    $widget->SetCursor('opLimits + 3 c');	# In the lower limit.
    $widget->mark('unset', 'opLimits');
  }
  $widget->break if $break;
}

$spanTables = 0;
sub newSpanTableKey { { table => ++$spanTables } }

# An empty table of $rows rows and $cols columns.
sub Tk::eText::insertSpanTable {
  my ($widget, $pos, $rows, $cols, $break) = @_;
  $widget->blockInsert($pos, mkBlock(['SpanTable', newSpanTableKey()],
				     map mkNode(('') x $cols), 1 .. $rows));
  $widget->break if $break;
}

# The cell of a SpanTable at an index (or around the block holding the
# index): the index of a position naming it and its level, or ().
sub Tk::eText::spanCell {
  my ($widget, $index) = @_;
  my $at = $widget->index($index);
  while (1) {
    my ($start, $len, $name) = $widget->block('of', $at);
    return () unless defined $start;
    if ($name eq 'SpanTable') {
      # The child of a row (-3), a row that is a leaf (-2), a table
      # that is a leaf (-1).
      for my $level (-3, -2, -1) {
	return ($at, $level)
	  if eval { $widget->block('nodedata', $at, $level); 1 };
      }
      return ();
    }
    $at = $start;		# The head of a nested block: in its leaf.
  }
}

# Sets the span of the cell at $index: $cols columns, $rows rows (1 and
# 1: no span), and redisplays the table.
sub Tk::eText::setSpan {
  my ($widget, $index, $cols, $rows, $break) = @_;
  my ($at, $level) = $widget->spanCell($index);
  if (defined $at) {
    $widget->block('nodedata', $at, $level,
		   ($cols > 1 || $rows > 1) ? { cols => $cols, rows => $rows }
		   : undef);
    # The callback finds the values by the instance data; setting it
    # again redisplays the block.
    my $key = $widget->block('data', $at);
    $widget->block('data', $at, ref $key ? $key : newSpanTableKey());
  }
  $widget->break if $break;
}

sub Tk::eText::growSpan {
  my ($widget, $index, $dcols, $drows, $break) = @_;
  my ($at, $level) = $widget->spanCell($index);
  if (defined $at) {
    my ($c, $r) = cellSpan([$widget->block('nodedata', $at, $level)]);
    $c += $dcols; $r += $drows;
    $widget->setSpan($at, ($c < 1 ? 1 : $c), ($r < 1 ? 1 : $r));
  }
  $widget->break if $break;
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

# Takes widget, position, and a list of elements to insert there one
# after another.  An element may be:
# 
# a) a string to insert;
#
# b) a tagged string: bless [string, [tags...]], 'Tk::Text::Tagged';
# 
# c) a block: bless [type, child, child...], 'Tk::Text::Block', where
#    type is a block name or [name, instance data], and a child (a
#    child of the root) is
#    - a string, a tagged string or a block: one leaf;
#    - an array of such elements: one leaf holding all of them;
#    - a node: bless [child, child...], 'Tk::Text::Node', whose
#      children are children as here (so trees of any shape, ragged
#      trees included, can be written down);
#    - a child with a value (block nodedata): bless [child, value],
#      'Tk::Text::Valued'.
#
# The tree is built as a user would: newlines make the siblings of a
# leaf, and a node is a leaf given a node of its own by "block
# sprout" and then split by newlines.

$biMark = 0;
$bfMark = 0;

# Constructors for the elements above.
sub mkBlock { my $type = shift; bless [$type, @_], 'Tk::Text::Block' }
sub mkNode { bless [@_], 'Tk::Text::Node' }
sub mkValued { bless [@_[0, 1]], 'Tk::Text::Valued' }
sub mkTagged { my $s = shift; bless [$s, [@_]], 'Tk::Text::Tagged' }

sub Tk::eText::blockInsert {
  my ($widget, $pos) = (shift,shift);
  my $mark = "bim" . $biMark++;
  $widget->mark('set',$mark, $pos);
  foreach $elt (@_) {
    if (!ref $elt) {	# String to insert
      $widget->insert($mark, $elt);
    } elsif (ref $elt eq 'Tk::Text::Tagged') {
      $widget->insert($mark, $elt->[0], $elt->[1]);
    } elsif (ref $elt eq 'Tk::Text::Block') {
      my ($type, $data) = ref $elt->[0] ? @{$elt->[0]} : ($elt->[0]);
      $widget->block('insert', $type, $mark);
      $widget->block('data', "$mark -1 c", $data) if defined $data;
      # The block has one empty leaf; its tail is just before $mark.
      fillLeaf($widget, "$mark -1 c", @$elt[1 .. $#$elt]) if @$elt > 1;
    } else {
      warn "Unknown data type `" . (ref $elt) . "' given to blockInsert";
    }
  }
  $biMark--;
  $widget->mark('unset',$mark);
  return;
}

# Fills the empty leaf at $pos (where the leaf ends) with the children
# (see blockInsert), one leaf for each, siblings of that leaf.
sub fillLeaf {
  my ($widget, $pos, @kids) = @_;
  my $at = "bif" . $bfMark++;		# Moves on with what is inserted.
  $widget->mark('set', $at, $pos);
  my (@nodes, @values);
  my $first = 1;
  for my $kid (@kids) {
    $widget->insert($at, "\n") unless $first;	# A sibling leaf.
    $first = 0;
    my ($what, $value, $valued) = ($kid);
    if (ref $what eq 'Tk::Text::Valued') {
      ($what, $value) = @$what;
      $valued = 1;
    }
    my $here;
    if ($valued or ref $what eq 'Tk::Text::Node') {
      $here = "bif" . $bfMark++;	# Stays at the start of this leaf.
      $widget->mark('set', $here, $at);
      $widget->mark('gravity', $here, 'left');
    }
    if (ref $what eq 'Tk::Text::Node') {
      push @nodes, [$here, $what];	# An empty leaf, a node later.
    } else {
      $widget->blockInsert($at, ref $what eq 'ARRAY' ? @$what : ($what));
    }
    if ($valued) {
      # A node's value goes to the node: as many levels up from its
      # first leaf as there are nodes on the way down to that leaf.
      my ($level, $n) = (0, $what);
      while (ref $n eq 'Tk::Text::Node' and @$n) {
	$level++;
	$n = $n->[0];
	$n = $n->[0] if ref $n eq 'Tk::Text::Valued';
      }
      push @values, [$here, $level, $value];
    }
  }
  for my $node (@nodes) {
    my ($here, $n) = @$node;
    # The leaf is empty: $here is at the separator (or the tail) after
    # it, which names it.
    $widget->block('sprout', $here);
    fillLeaf($widget, $widget->index($here), @$n) if @$n;
  }
  for my $v (@values) {
    my ($here, $level, $value) = @$v;
    $widget->block('nodedata', $here, $level, $value);
  }
  $widget->mark('unset', $at, map $_->[0], @nodes, @values);
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
  my $file = shift || "$FindBin::Bin/save.tsf";
  # The strings are Unicode (and freeze() records their lengths in
  # characters), so the file is UTF-8.
  open(SAVE, ">:utf8", $file) or die "Cannot open $file for write: $!\n";
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
  my $file = shift || "$FindBin::Bin/save.tsf";
  open(SAVE, "<:utf8", $file) or die "Cannot open $file for read: $!\n";
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
  @chars = map { $state->{by_table}->[-1]->{$_} || '\unknown' } @chars
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
  unless (ref $next eq 'Tk::Text::BlockSeparator' and sepDepth($next) >= $depth) {
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
	   or ref $next eq 'Tk::Text::BlockSeparator' and sepDepth($next) >= $depth) {
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

sub Eq2TeX {
  my $self = shift;
  my $state = shift;
  my $sep = 1;
  ++$sep until $sep > $#$self or ref $self[$sep] eq 'Tk::Text::BlockSeparator';
  undef $sep if $sep > $#$self;
  my @out = flashTags($state);
  $state->{atBeg} = 1;
  push @out, '\left' . $l;
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

# The stored depth of a separator of "block list": a number, or the
# pair [depth, defect] before a leaf with padding (a ragged tree), where
# [undef, defect] stands before a padded first leaf (no separator).
sub sepDepth {
  my ($d, $defect) = UNIVERSAL::isa($_[0], 'ARRAY') ? @{$_[0]} : (${$_[0]}, 0);
  $d // -1;
}

sub Tk::Text::BlockSeparator::insertSelfTeX {
  my ($self, $state) = (shift, shift);
  return () if sepDepth($self) < 0;	# Not a separator: [undef, defect].
  my $level = $ {$state->{depths}}[-1] - sepDepth($self);
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

# A TagOn element of "block list" is a reference to the tag's name, or,
# for a run that has a value (tag data), a list [name, value].
sub Tk::Text::TagOn::name {
  my $self = shift;
  UNIVERSAL::isa($self, 'ARRAY') ? $self->[0] : $$self;
}

# The same for marks: a MarkLeft or MarkRight element is a reference to
# the mark's name, or, for a mark that has a value (mark data), a list
# [name, value].  (Export and paste leave marks out, values included.)
sub Tk::Text::MarkLeft::name { Tk::Text::TagOn::name(@_) }
sub Tk::Text::MarkRight::name { Tk::Text::TagOn::name(@_) }

sub Tk::Text::TagOn::insertSelfTeX {
  my ($obj, $state) = (shift, shift);
  my $name = $obj->name;
  my $self = \$name;
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
  $widget->{tags}{$self->name} = $widget->index($pos);
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
  # The header [type, depth, instance data, node values] (block list,
  # in the manual under dump): give the values back, then the instance
  # data (setting it redisplays the block, as setSpan relies on).
  setNodeValues($widget, $pos, $type->[3]) if @$type > 3 and ref $type->[3];
  $widget->block('data', "$pos + 1c", $type->[2])
    if @$type > 2 and defined $type->[2];
}

# Give the node values of a block's header back to the block whose head
# is at $pos.  The values are the nested form of "block list" (a node as
# a list of its value followed by its children, a leaf as a list of its
# value); "block at" gives the same tree as nested lists of leaf lengths,
# from which each leaf's start follows (a separator or the tail after
# each leaf).  A node is set at the start of its first leaf, with its
# distance up from that leaf as the level (as "block nodedata" counts).
sub setNodeValues {
  my ($widget, $pos, $vals) = @_;
  my $struct = ($widget->block('at', $pos))[4];
  my $first = $widget->index("$pos + 1c");
  my $off = 0;
  my $walk;
  $walk = sub {
    my ($s, $v) = @_;
    my ($start, $height);
    if (!ref $s) {			# A leaf of $s positions.
      ($start, $height) = ($off, 0);
      $off += $s + 1;
    } else {
      for my $i (0 .. $#$s) {
	my @r = $walk->($s->[$i], ref $v ? $v->[$i + 1] : undef);
	($start, $height) = ($r[0], $r[1] + 1) if $i == 0;
      }
    }
    $widget->block('nodedata', "$first + $start c", $height, $v->[0])
      if ref $v and defined $v->[0];
    return ($start, $height);
  };
  $walk->($struct, $vals);
  undef $walk;
}

sub Tk::Text::Empty::insertSelf {	# [type, ?instance data?]
  my $self = shift;
  my $widget = shift;
  my $pos = $widget->index(shift || 'insert');
  $widget->block('insert', $self->[0], $pos);
  $widget->block('data', "$pos + 1c", $self->[1]) if @$self > 1;
}

sub Tk::Text::BlockSeparator::insertSelf {
  my $self = shift;
  my $widget = shift;
  my $pos = shift || 'insert';
  my $depth = sepDepth($self);
  return if $depth < 0;			# [undef, defect]: no separator.
  if ($depth) {
    $widget->block('split', $pos, $depth);
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
      $text->update;
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
  my $file = new Text::TeX::OpenFile "$FindBin::Bin/test.tex", 'defaultact' => \&Tk::eText::TeXinsert;
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
		   $txt->TeX_insert('insert', $w_t->get('0.0','end'))};
    $w_t->bind('<Control-Return>', $sub);
    my $w_ok = $w->Button(-text => 'OK', 
			  -width => 8, 
			  -command => $sub,
			 )->pack(-side => 'bottom');

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

