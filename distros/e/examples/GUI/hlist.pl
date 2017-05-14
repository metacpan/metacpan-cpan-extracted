use Tk;
require Tk::HList;
$top = MainWindow->new();
$h = $top->Scrolled('HList', 
                    '-drawbranch'     => 1, 
                    '-separator'      => '/',
                    '-indent'         => 15,
                    '-command'        => \&show_or_hide_dir,
                    )->pack('-fill'   => 'both',
                            '-expand' => 'y');

$icons{"open"}   = $top->Bitmap(-file => './open_folder.xbm');
$icons{"closed"} = $top->Bitmap(-file => './folder.xbm');

show_or_hide_dir("/");
MainLoop();

#-----------------------------------------------------------------------
sub show_or_hide_dir {    # Called when an entry is double-clicked
    my $path = $_[0];
    return if (! -d $path);  # Not a directory.
    if ($h->info('exists', $path)) { 
        # Toggle the directory state. 
        # We know that a directory is open by examining the next
        # entry: it is open if it is a substring of the current path
        $next_entry = $h->info('next', $path);
        if (!$next_entry || (index ($next_entry, "$path/") == -1)) {
            # No. open it
            $h->entryconfigure($path, '-image' => $icons{"open"});
            add_dir_contents($path);
        } else {
            # Yes. Close it by changing the icon, and deleting its subnode.
            $h->entryconfigure($path, '-image' => $icons{"closed"});
            $h->delete('offsprings', $path);
        }
    } else {
        die "'$path' is not a directory\n" if (! -d $path);
        $h->add($path, '-itemtype' => 'imagetext',
                '-image' => $icons{"open"}, '-text' => $path);
        add_dir_contents($path);
    }
}

sub add_dir_contents {
    my $path = $_[0];
    my $oldcursor = $top->cget('-cursor');
    $top->configure('-cursor' => 'watch');
    $top->update();
    my @files = <$path/*>;
    foreach $file (@files) {
        $file =~ s|//|/|g;
        ($text = $file) =~ s|^.*/||g;
        if (-d $file) {
            $h->add($file, '-itemtype' => 'imagetext',
                    '-image' => $icons{"closed"}, '-text' => $text);
        } else {
            $h->add($file, -itemtype => 'text',
                    '-text' => $text);
        }
    }
    $top->configure('-cursor' => $oldcursor);
}



