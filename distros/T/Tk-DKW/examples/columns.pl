#! /usr/bin/perl

use Tk;

use Tk::Columns;

my $l_MainWindow = Tk::MainWindow->new();

my $l_Columns = $l_MainWindow->Columns
   (
    '-columnlabels' => [qw (Permissions Links Owner Group Size Month Day Time Name)],
    '-command' => sub {printf ("Selected [%s]\n", join ('|', @_));},
    '-image' => $l_MainWindow->Pixmap ('-file' => 'mini-doc.xpm'),
    '-listforeground' => 'blue4',
    '-listbackground' => 'beige',
    '-buttonbackground' => 'brown',
    '-buttonforeground' => 'white',
    '-selectmode' => 'extended',
    '-sort' => 'true',
   );

  $l_Columns->indexedbutton (4)->configure
     (
      '-sortcommand' => '{$a <=> $b}',
      '-buttonbackground' => 'orange',
      '-buttonforeground' => 'blue',
     );

$l_Columns->indexedbutton ('Day')->configure
   (
    '-sortcommand' => '{$a <=> $b}',
   );

$l_Columns->pack
   (
    '-expand' => 'true',
    '-fill' => 'both',
   );

$l_MainWindow->Button
   (
    '-text' => 'DoIt',

    '-command' => sub
       {
        $l_Columns->configure
           (
            '-listselectmode' => 'browse',
            '-buttonbackground' => 'cyan',
            '-buttonforeground' => 'black',
            '-foreground' => 'green4',
            '-background' => 'violet',
            '-zoom' => true,
           );

        $l_Columns->indexedbutton ('Name')->configure
           (
            '-image' => $l_MainWindow->Pixmap ('-file' => 'mini-folder.xpm'),
            '-background' => 'lavender',
            '-foreground' => 'yellow',
           );

        $l_Columns->indexedbutton (0)->configure
           (
            '-image' => $l_MainWindow->Pixmap ('-file' => 'mini-folder.xpm'),
            '-background' => 'blue',
            '-foreground' => 'grey',
            '-listforeground' => 'red',
            '-listbackground' => 'green',
           );
       }
   )->pack();

if (open (FILE, '<testfile.txt'))
   {
    while (<FILE>)
       {
        chomp;
        $_ =~ s/[\r\n]*$//;
        $l_Columns->insert ('end', split());
       }

    close (FILE);
   }

Tk::MainLoop();
