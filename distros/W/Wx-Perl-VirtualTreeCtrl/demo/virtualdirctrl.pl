#!/usr/local/bin/perl
use strict;
#!/usr/bin/perl
# $Id: virtualdirctrl.pl,v 1.2 2006/04/07 09:13:28 johnl Exp $

package TestApp;
use strict;
use vars qw(@ISA);
@ISA=qw(Wx::App);

use Wx ':id';
use Wx::Perl::VirtualDirSelector;
use Wx::Perl::VirtualTreeCtrl;
use File::Spec;

use constant TRACING_ENABLED => 0;
if (TRACING_ENABLED) {
    require Log::Trace;
    import Log::Trace print => \*STDERR, { Verbose => 1 };
}


sub OnInit {
    my ($this) = @_;

    my ($frame) = Wx::Frame->new(
        undef, -1, "Minimal wxPerl app", [50,50], [450,350]
    );
    $this->SetTopWindow($frame);
    $frame->Show(0); # don't show the frame, we just want to see the selector

    my $vd = new Wx::Perl::VirtualDirSelector(
        undef, -1, \&OnDirPopulate, 'Please select a folder', 'c:\\'
    );

    $vd->SetRootLabel('c:\\');
    $vd->SetRootItemSelectable(0);
    $vd->ExpandRoot();
    if ($vd->ShowModal() == wxID_OK) {
        Wx::MessageBox(sprintf "you selected '%s'", $vd->GetSelection);
    }
    $this->ExitMainLoop;
    exit;
    1;
}


sub OnDirPopulate {
    my ($dirselector, $event) = @_;
    my $tree   = $event->GetEventObject;
    my $parent = $event->GetItem;
    my $parent_folder = $tree->GetPlData($parent);


    my $child = $tree->GetFirstChild($parent);
    if ($child && $child != -1) {
        # update existing folder listing ...
    } else {
        # Add folders
        my $children = list_dir($parent_folder);
        DUMP("adding children to $parent_folder", $children);
        if ($children && @$children > 0) {
            foreach (@$children) {
                my $this_folder = File::Spec->catfile($parent_folder, $_);
                next unless -d $this_folder && $_ !~ /^\.\.?$/;
                $child = $tree->AppendItem($parent, $_, 0, 0);
                TRACE("Adding <$_>");
                $tree->SetPlData($child, $this_folder);
                TRACE("\t-Setting Image");
                $tree->SetItemImage($child, 0);
                # make item expandable if it's a folder
                TRACE("\t-Setting 'HasChildren'");
                $tree->SetItemHasChildren($child, 1);
            }
        }

        # remove [+] icon from empty folders
        my ($first_child, $cookie) = $tree->GetFirstChild($parent);
        if (!$first_child || $first_child == -1) { # nothing added
            # no children, reflect that in user interface
            $tree->SetItemHasChildren($parent, 0);
        }
        TRACE("[Done adding from $parent_folder]");
    }
    $event->Skip;
}

# could use File::Slurp, but why add another dependency for this demo?
sub list_dir {
    my ($folder) = @_;
    local *DH;
    opendir DH, $folder or die "error listing dir $folder -- $!";
    my @files = readdir DH;
    closedir DH;
    return \@files;
}

# Log::Trace stubs
sub TRACE { print STDERR "@_\n" }
sub DUMP  { require Data::Dumper; TRACE(Data::Dumper::Dumper(@_)) }


package main;

# create an instance of the Wx::App-derived class
my ($app) = TestApp->new();
$app->MainLoop();
