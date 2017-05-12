#!/usr/local/bin/perl5 -I../blib/lib -w

use Tk::SlideShow;
use strict;

my $p = Tk::SlideShow->init(1024,768) or die;

$p->save;

my ($mw,$c,$h,$w) = ($p->mw, $p->canvas, $p->h, $p->w);
my $d;

$p->steps(10);
$mw->Tk::bind('Tk::SlideShow','<Up>', sub { $c->move($p->current_item,0,-1);});
$mw->Tk::bind('Tk::SlideShow','<Down>', sub { $c->move($p->current_item,0,1);});
$mw->Tk::bind('Tk::SlideShow','<Right>', sub { $c->move($p->current_item,1,0);});
$mw->Tk::bind('Tk::SlideShow','<Left>', sub { $c->move($p->current_item,-1,0);});

sub title {
  $p->Image('ti',"Xcamel.gif");
  $p->Text('title',shift,-font,$p->f3);
}

sub items {
  my ($id,$items,@options) = @_;
  my @ids;
  for (split (/\n/,$items)) {
    s/^\s*//;
    s/\s*$//;
    $p->Text($id,$_,@options);
    push @ids,$id;
    $id++;
  }
  return @ids;
}
$d = $p->add('summary',sub {
	  title('Tk::SlideShow');
	  my $c = 'a0';
	  items('a0',"What ?\nWhy ?\nHow ?",
		-font => $p->f2,-fill, 'red');
	  items('b0',"a TkPerl alternative to PowerPoint\nPerl power\nBy examples",
		-font => $p->f2,-fill, 'blue');
	  $p->TickerTape('help',"Press q to quit, h for key help, button 3 to progress in slide, space for next slide .... ",
			 70,-font,$p->f1,-fill,'red',
			-delay, 300, -chunk, 20);
	  $p->load;
	  for (0..2) {$p->a_top("a$_"); $p->a_bottom("b$_");}
});

$d->html("
<h1>What's Tk::SlideShow ? </h1>

Tk::SlideShow is a module that will help perl to be a very
	  powerfull tool for building presentation

<p>

<h2>Why using perl for that purpose </h2>

There are good reason for using Tk::SlideShow :

<ul>

<li> Filling the lack of free tools for building presentation like
what you can do with PowerPoint.

<li> Simply building simple slide,

<li> Being able to build very elaborated slides, up to real GUI
interface,

<li> Structured your presentations using a structured language,

<li> Or even a OO presentation using a OO language,

</ul>

When using a tool like PowerPoint, you have 2 types of interaction :

<ul>

<li> description of what you want to see thru menus, dialog box and
templates and typing text. This is roughly programming with a mouse ;

<li> interactive and approximative placement of what you want to see
: this is Art !

</ul>

Tk::SlideShow will try to target the former with perl script rather than a
two buttons mouse, and will probably be much more powerful. Tk::SlideShow
will try to target the later with Tk interaction. It will probably not
reach the Artistic Quality of a PowerPoint like tools. But one never
know !

<h2>How to use it ? </h2>

Well, mostly by examples, because perl folks don't like having to
learn another theory when explaining their's
");

$d = $p->add('principles',sub {
	  title('Principles');
	  my @a = items('a0',"Take advantage of your computer knowledge
Be nearly unlimited in expression
Solicite Architect & Artist that's in yourself
Be coherent with your OpenSource choices",-font,$p->f2,-fill,'red');
	  $p->load;
	  $p->a_left(@a);
});



sub example {
  my ($id,$t,@options) = @_;
  $t =~ s/^\s+//; $t =~ s/\s+$//;
  my $s = $p->newSprite($id);
  my $f = $c->Font('family'  => "courier", point => 250, -weight => 'bold');
  $c->createText(0,0,-text,'Example',
		 -font => $f, -tags => $id, 
		 -fill,'red',
		 -anchor => 'sw');
  my $idw = $c->createText(0,0,-text,$t,@options, -tags => $id,
			   -fill,'yellow', -font => $f,
			  -anchor => 'nw');
  $c->createRectangle($c->bbox($idw), -fill,'black',-tags => $id);
  $c->raise($idw);
  $s->pan(1);
  return $s;
}


#############################################################

$d = $p->add('prerequisite',sub {
	  title('Prerequisite');
	  example('ex',"use Tk::SlideShow;\nmy \$p= Tk::SlideShow->init(1024,768);\n\$p->save;",
		  -font => $p->ff2
		 );
	  items('t0',"You have to : ",-font, $p->f3);
	  items('a0',"Know Perl and Tk !
                      Tell what your screen size is.
                      Ask for your Art to be saved.",
		-font => $p->f2,-fill, 'red');
	  $p->load;
	  for (0..2) {$p->a_bottom("a$_")}
	});

$d->html("
<h1>You have to know Perl/Tk</h1>

Yes, there is no power in Tk::SlideShow. The power is in Perl and in Tk. You
will reuse all what you have learn. That's the trick : Tk::SlideShow only takes
advantage of what you already know. Leave now this reading,
un(til\|less) you know a little bit perl/Tk.

<h1>Tell what your screen size is</h1>

Sometimes, you are developping your application on 21~inch screen with
a resolution of \$1600 \\times 1280\$ and the projector will only be
able to have \$ 1024 \\times 768\$. This, Perl cannot know, you have
to tell it. If you don't Tk::SlideShow will use the maximum size of you X11
root.

To short the examples given there, I assume that these lines will be
at the beginning of each example.

<h1>Ask for your Art to be saved </h1>

When building your presentation, you will be able to place visual
object with the mouse. This has to be saved so that when restarting
the presentation, objets will be positionned where you have previously
specified it. The class method \\texttt{\\bf save} is there to allow
to save your interactive modification.

");




$d = $p->add('first-slide',sub {
	  title('My first slide');
	  items('aaa','As an architect',-font,$p->f2);
	  example('ex',
		  q{$p->add('first-slide',
 sub {

  $p->Text('t1',"My first Tk::SlideShow slide");
  $p->Text('t2',"This is simple");
  $p->Text('t3',"This is simplist");

  $p->load;
 }
)},
		  -font => $p->ff1
		 );
	  items('a0',"Add a slide
Give it a name,
Give the sub
Describe the texts
Load the positions",
		-font => $p->f2,-fill, 'blue');
	  for (0..4) {
	    $p->newLink("a$_",$p->Oval("o$_",-width,3,-outline,'red'),'',-fill,'red',-width,2);
	  }
	  $p->load;
	  for (0..4) {$p->a_bottom(["a$_","o$_"])}
	});

$d->html("
<h2>Your first slide</h2>
OK, now, you are dying to know how to build a first
slide. That's simple, if what you want is simple.

<h2>paragraph{Add a slide</h2>
A presentation is a pile of slides. You just have to add
a slide to the presentation by using the method \\texttt{\\bf add}

<h2>Give it a name</h2>
Because your slide is probably something you will reference in the
future, your had better to give it a name. If not, Tk::SlideShow will find one
for you. In this example, this is {\\it first-slide}. This name will also
be used to store positions of the objets you will place interactively
on the screen.

<h2>Give the sub </h2>
Well, a slide for Tk::SlideShow is rougly a sub reference. This sub will be call 
when Tk::SlideShow has to show the slide. That's all.

<h2>Describe the text</h2>

Here, you see a new method.
\\texttt{\\bf Text}, that is used to place a text on the screen. You do not
know where the text will be place. This will be done with your mouse,
dragging the text with button one. When the artisitic position are
good for you, then just press key \\texttt{\\bf s} to save the position 
in a file.

<h2>Load the positions</h2>

 Then, you can load the positions of your texts, you have previously
saved.

");
$d = $p->add('first-slide2',sub {
	  title('My first slide');
	  items('aaa','As an artist',-font,$p->f2);
	  $p->Text('t1',"My first Tk::SlideShow slide");
	  $p->Text('t2',"This is simple");
	  $p->Text('t3',"This is simplist");
	  
	  $p->load;
	});

if (grep (/-html/,@ARGV)) {
  $p->html("doc");
  exit 0;
}

$p->current(shift || 0);
$p->play;
