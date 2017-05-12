
# $Id: sizer.t,v 1.2 2008/01/22 03:51:54 Daddy Exp $

use strict;
use warnings;

my $VERSION = do { my @r = ( q$Revision: 1.2 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Cwd;
use Data::Dumper;
use ExtUtils::testlib;
use IO::Capture::Stdout::Extended;
use Test::More ;
use Tk;

my @asClass;

BEGIN
  {
  @asClass = qw( Tk::Wizard::Sizer Tk::Wizard::Installer::Sizer );
  if ($^O =~ m!win32!i)
    {
    push @asClass, 'Tk::Wizard::Installer::Win32::Sizer';
    } # if
  my $mwTest;
  eval { $mwTest = Tk::MainWindow->new };
  if ($@)
    {
    plan skip_all => 'Test irrelevant without a display';
    }
  else
    {
    plan tests => (scalar(@asClass) * 9) + ($ENV{TEST_INTERACTIVE} ? 30 : 0);
    }
  $mwTest->destroy if Tk::Exists($mwTest);
  print Dumper(\@asClass);
  map { use_ok($_) } @asClass;
  print Dumper(\@asClass);
  } # end of BEGIN block
my $oICS =  IO::Capture::Stdout::Extended->new;
my $sStyle = 'top';
foreach my $sClass (@asClass)
  {
  my $self = new $sClass(
                         # -debug => 3,
                         -title => "Sizer Test",
                         -style => $sStyle,
                        );
  isa_ok($self, 'Tk::Wizard::Sizer');
  isa_ok($self, 'Tk::Wizard');
  isa_ok($self, $sClass);
  our $WAIT = $ENV{TEST_INTERACTIVE} ? 0 : 222;
  my $s1 = "This is the long horizontal text for the Sizer TextFrame Page.  It is wider than the default Wizard width.";
  my $s2 = "It is stored in a string variable, and a reference to this string variable is passed to the addTextFramePage() method.";
  my $s3 = "This
 is
 the
 long
 vertical
 text
 for
 the
 Sizer
 TextFrame
 Page.  
It 
is 
 taller 
than 
the 
default 
Wizard 
height.";
  $self->addPage(sub
                   {
                   $self->blank_frame(
                                      -wait => $WAIT,
                                      -title => "Intro Page Title ($sStyle style)",
                                      -subtitle => "Intro Page Subtitle ($sStyle style)",
                                      -text => "This is the text of the Sizer TextFrame Intro Page ($sStyle style)",
                                     );
                   } # sub
                ); # add_page
  $self->addTextFramePage(
                          -wait => $WAIT,
                          -title => "Sizer TextFrame Page Title ($sStyle style)",
                          -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style)",
                          -text => $s1,
                          -boxedtext => \$s2,
                         );
  $self->addTextFramePage(
                          -wait => $WAIT,
                          -title => "Sizer TextFrame Page Title ($sStyle style)",
                          -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style)",
                          -text => $s3,
                          -boxedtext => \$s2,
                         );
  $self->addPage(sub
                   {
                   $self->blank_frame(
                                      -wait => $WAIT,
                                      -title => "Finish Page Title ($sStyle style)",
                                      -subtitle => "Finish Page Subtitle ($sStyle style)",
                                      -text => "This is the text of the Sizer TextFrame Finish Page ($sStyle style)",
                                     );
                   } # sub
                ); # add_page
  pass('before Show');
  $oICS->start;
  $self->Show;
  pass('before MainLoop');
  MainLoop;
  pass('after MainLoop');
  $oICS->stop;
  my $iGot = $oICS->matches(qr(final dimensions were));
  is($iGot, 4, 'reported dimensions for 4 pages');
  is($oICS->matches(qr/smallest area/), 1, 'reported overall best size');
  if ($ENV{TEST_INTERACTIVE})
    {
    # Show the same Wizard with the sizes we determined empirically:
    my $self = new Tk::Wizard::Sizer(
                                     # -debug => 3,
                                     -title => "Sizer Test",
                                     -style => $sStyle,
                                    );
    isa_ok( $self, "Tk::Wizard" );
    isa_ok( $self, "Tk::Wizard::Sizer" );
    $self->addPage(sub
                     {
                     $self->blank_frame(
                                        -wait => $WAIT,
                                        -title => "Intro Page Title ($sStyle style), 300x300",
                                        -subtitle => "Intro Page Subtitle ($sStyle style), 300x300",
                                        -text => "This is the text of the Sizer TextFrame Intro Page ($sStyle style), 300x300",
                                        -width => 300, -height => 300,
                                       );
                     } # sub
                  ); # add_page
    $self->addTextFramePage(
                            -wait => $WAIT,
                            -title => "Sizer TextFrame Page Title ($sStyle style), 655x220",
                            -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style), 655x220",
                            -text => $s1 . ", 655x220",
                            -boxedtext => \$s2,
                            -width => 655, -height => 220,
                           );
    $self->addTextFramePage(
                            -wait => $WAIT,
                            -title => "Sizer TextFrame Page Title ($sStyle style), 207x422",
                            -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style), 207x422",
                            -text => $s3. ", 207x422",
                            -boxedtext => \$s2,
                            -width => 207, -height => 422,
                           );
    $self->addPage(sub
                     {
                     $self->blank_frame(
                                        -wait => $WAIT,
                                        -title => "Finish Page Title ($sStyle style), 362x315",
                                        -subtitle => "Finish Page Subtitle ($sStyle style), 362x315",
                                        -text => "This is the text of the Sizer TextFrame Finish Page ($sStyle style), 362x315",
                                        -width => 362, -height => 315,
                                       );
                     } # sub
                  ); # add_page
    pass('before Show');
    $self->Show;
    pass('before MainLoop');
    MainLoop;
    pass('after MainLoop');
    # Show the same Wizard with the overall max size we determined empirically:
    $self = new Tk::Wizard::Sizer(
                                  # -debug => 3,
                                  -title => "Sizer Test, 655x422",
                                  -style => $sStyle,
                                  -width => 655, -height => 422,
                                 );
    isa_ok( $self, "Tk::Wizard" );
    isa_ok( $self, "Tk::Wizard::Sizer" );
    $self->addPage(sub
                     {
                     $self->blank_frame(
                                        -wait => $WAIT,
                                        -title => "Intro Page Title ($sStyle style), 655x422",
                                        -subtitle => "Intro Page Subtitle ($sStyle style), 655x422",
                                        -text => "This is the text of the Sizer TextFrame Intro Page ($sStyle style), 655x422",
                                       );
                     } # sub
                  ); # add_page
    $self->addTextFramePage(
                            -wait => $WAIT,
                            -title => "Sizer TextFrame Page Title ($sStyle style), 655x422",
                            -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style), 655x422",
                            -text => $s1. ", 655x422",
                            -boxedtext => \$s2,
                           );
    $self->addTextFramePage(
                            -wait => $WAIT,
                            -title => "Sizer TextFrame Page Title ($sStyle style), 655x422",
                            -subtitle => "Sizer TextFrame Page Subtitle ($sStyle style), 655x422",
                            -text => $s3. ", 655x422",
                            -boxedtext => \$s2,
                           );
    $self->addPage(sub
                     {
                     $self->blank_frame(
                                        -wait => $WAIT,
                                        -title => "Finish Page Title ($sStyle style), 655x422",
                                        -subtitle => "Finish Page Subtitle ($sStyle style), 655x422",
                                        -text => "This is the text of the Sizer TextFrame Finish Page ($sStyle style), 655x422",
                                       );
                     } # sub
                  ); # add_page
    pass('before Show');
    $self->Show;
    pass('before MainLoop');
    MainLoop;
    pass('after MainLoop');
    } # if
  } # foreach

__END__

