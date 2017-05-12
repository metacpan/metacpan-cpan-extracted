use strict;
use warnings;

package Subclass;

use lib '../lib'; # For test context
use Video::Dumper::QuickTime;
use base qw(Video::Dumper::QuickTime);

sub name_smhd {
    my $self = shift;
    return 'The smhd atom';
}


sub dump_smhd {
    my $self = shift;
    my ( $pos, $len ) = @_;
}


package main;

use Tk;
use Tk::Tree;
use Tk::ProgressBar;
use Tk::Clipboard;

my $filename = shift;
my $tree;
my $main;
my $progressBar;

unless ( defined $filename ) {
    print <<HELP;
DumpQuickTime parses a QuickTime movie file and dumps a report of the file's
structure to STDOUT.

Run DumpQuickTime as:

DumpQuickTime filename
HELP

    exit -1;
}

my $file = Subclass->new( -filename => $filename, -progress => \&showProgress );

$main = MainWindow->new(
    -title => "QuickTime dump of $file->{'filename'} - loading" );
$main->geometry('400x25');

$progressBar = $main->ProgressBar(
    -from   => 0,
    -to     => 100,
    -blocks => 400,
)->pack( -fill => 'both', -expand => 1 );

my $errors;

open ERRORS, '>', \$errors;

my $oldSel = select ERRORS;

eval {$file->Dump ()};
select $oldSel;
close ERRORS;

my $str = $file->Result ();

$progressBar->destroy();

print $errors if $errors;

$main->configure( -title => "QuickTime dump of $file->{'filename'}" );
$tree = $main->ScrlTree(
    -font       => 'FixedSys 8',
    -itemtype   => 'text',
    -separator  => '/',
    -scrollbars => "se",
    -selectmode => 'single',
    -command    => \&copyItemText
);
$tree->pack( -fill => 'both', -expand => 1 );

my @pathStack;
my $lastLine = 0;
my $savedTail;
my $catchIndented;
my $maxLineLenght = 0;
my $maxNesting    = 0;
my $totalLines    = 0;
my $currIndent    = '';
my $indentStr     = $file->IndentStr ();

push @pathStack, 0;

for my $line ( split "\n", $str ) {
    chomp $line;
    next if length($line) == 0;    # Skip blank lines

    my ( $newIndent, $nodeText ) = $line =~ /^((?:\Q$indentStr\E)*)(.*)/;

    while ( length($newIndent) > length($currIndent) ) {
        # new project
        push @pathStack, 0;
        $currIndent .= $indentStr;
    }

    while ( length($newIndent) < length($currIndent) ) {
        # new project
        pop @pathStack;
        substr $currIndent, 0, length $indentStr, '';
    }

    $pathStack[-1]++;
    $maxNesting = @pathStack if $maxNesting < @pathStack;
    my $currPath = join "/", @pathStack;
    $tree->add( $currPath, -text => $nodeText, -state => 'normal' );

    ++$totalLines;
    $maxLineLenght = length($nodeText)
      if length($nodeText) > $maxLineLenght;
}

$totalLines    = 40  if $totalLines > 40;
$totalLines    = 10  if $totalLines < 10;
$maxLineLenght = 120 if $maxLineLenght > 130;
$maxLineLenght = 80  if $maxLineLenght < 80;
$main->geometry( ( $maxLineLenght + $maxNesting * 4 ) * 5 . 'x'
      . ( 40 + $totalLines * 20 ) );
closeTree( $tree, '' );

MainLoop;

sub showProgress {
    my ( $pos, $total ) = @_;
    my $progress = 100 * $pos / $total;

    $progressBar->value($progress);
    $main->update();
}

sub copyItemText {
    my $path = shift;
    my $text = $tree->itemCget( $path, 0, '-text' );

    $tree->Busy( -recurse => 1 );
    if ( $tree->info( children => $path ) ) {
        openTree( $tree, $path, 1 );
    }
    else {
        $tree->clipboardClear ();
        $tree->clipboardAppend ($text);
    }

    $tree->Unbusy();
}

sub openTree {
    my $tree = shift;
    my ( $entryPath, $openChildren ) = @_;
    my @children = $tree->info( children => $entryPath );

    return if !@children;

    for (@children) {
        openTree( $tree, $_, 1 );
        $tree->show( 'entry' => $_ ) if $openChildren;
    }
    $tree->setmode( $entryPath, 'close' ) if length $entryPath;
}

sub closeTree {
    my $tree = shift;
    my ( $entryPath, $hideChildren ) = @_;
    my @children = $tree->info( children => $entryPath );

    return if !@children;

    for (@children) {
        closeTree( $tree, $_, 1 );
        $tree->hide( 'entry' => $_ ) if $hideChildren;
    }
    $tree->setmode( $entryPath, 'open' ) if length $entryPath;
}
