#!perl -w
use strict;
use warnings;

#
# Application to display control information, demosntrating AxWindow
# usage for Webbrowser, as well as providing useful information for
# anyone wanting to use other controls
#
# If you're randomly browsing controls, don't be surprised to find some
# that crash perl.
#
# Select an AxtiveX Object from the dropdown ...
#
# Author: Robert May
#

use Win32::GUI qw(WS_CLIPCHILDREN WS_EX_CLIENTEDGE);
use Win32::GUI::AxWindow();
use Win32::OLE();
use Win32::TieRegistry();

# Info about the currently inspected control
my %INFO;

# main Window
my $mw = new Win32::GUI::Window (
    -name     => "MW",
    -title    => "Win32::GUI::AxWindow Control Navigator",
    -size     => [600,400],
    -addstyle => WS_CLIPCHILDREN,
    -onResize => \&mwResize,
) or die "new Window";
$mw->Center();

$mw->AddLabel(
    -name   => "PROGID_Prompt",
    -pos    => [10,13],
    -height => 20,
    -text   => "Select PROGID :",
) or die "new Label";

$mw->AddCombobox(
    -name     => "PROGID",
    -top      => 10,
    -left     => $mw->PROGID_Prompt->Left()+$mw->PROGID_Prompt->Width()+10,
    -size     => [300,200],
    -vscroll  => 1,
    -onChange => \&loadInfo,
    -dropdownlist => 1,
) or die "new Combobox";

$mw->AddTreeView(
    -name        => 'TV',
    -top         => $mw->PROGID_Prompt->Height()+20,
    -width       => 180,
    -height      => $mw->ScaleHeight()-$mw->PROGID_Prompt->Height()-20,
    -rootlines   => 1,
    -lines       => 1,
    -buttons     => 1,
    -onNodeClick => \&dispInfo,
) or die "new TreeView";

Win32::GUI::AxWindow->new(
    -parent     => $mw,
    -control    => "Shell.Explorer",
    -name       => 'BW',
    -left       => $mw->TV->Left() + $mw->TV->Width()+5,
    -top        => $mw->PROGID_Prompt->Height()+20,
    -width      => $mw->ScaleWidth()-$mw->TV->Width()-5,
    -height     => $mw->ScaleHeight()-$mw->PROGID_Prompt->Height()-20,
    -addexstyle => WS_EX_CLIENTEDGE,
) or die "new AxWindow";

# Load a blank page
$mw->BW->CallMethod("Navigate", "about:blank");

$mw->Show();
$mw->Disable();

# Ref to list of controls
my $controls = getInstalledControls();
exit(0) if not defined $controls;  # Abort

#Populate combo selection
$mw->PROGID->Add(sort {lc $a cmp lc $b} @{$controls});

$mw->Enable();
$mw->BringWindowToTop();
Win32::GUI::Dialog();
$mw->Hide();
undef $mw;
exit(0);

sub mwResize {
    my $win = shift;
    my ($width, $height) = ($win->GetClientRect())[2..3];

    $win->TV->Height($height-$win->TV->Top());

    $win->BW->Width($width-$win->BW->Left());
    $win->BW->Height($height-$win->BW->Top());

    return 1;
}

sub loadInfo {
    Update_Treeview($mw->TV);
    return 1;
}

sub Update_Treeview {
    my $tv = shift;

    # reset information
    %INFO = ();
    $tv->DeleteAllItems();
    Display("");

    $INFO{progid} = $mw->PROGID->Text();
    $INFO{progid} =~ s/\s.*$//;

    # Determine if we can create the object:
    # This is pretty heavy handed, but I can't think of a better
    # way to prevent us falling back on Shell.Explorer if we can't
    # load the requested ActiveX object
    {
        my $oleobj;
        {
            local $SIG{__WARN__} = sub {};
            $oleobj = Win32::OLE->new($INFO{progid});
        }
        if (not defined $oleobj) {
            Display("<p style='color:red;'>ERROR creating $INFO{progid} (OLE)</p>");
            return 0;
        }
    }

    # Create invisible AxWindow control
    my $C = new Win32::GUI::AxWindow(
        -parent  => $mw,
        -name    => "Control",
        -control => $INFO{progid},
    );
    if (not defined $C) {
        Display("<p style='color:red;'>ERROR creating $INFO{progid} (Control)</p>");
        return 0;
    }

    # Get Property info
    foreach my $id ($C->EnumPropertyID()) {
        my %property = $C->GetPropertyInfo($id);
        $INFO{Properties}->{$property{-Name}} = \%property;
    }

    # Get Method info
    foreach my $id ($C->EnumMethodID()) {
        my %method = $C->GetMethodInfo($id);
        $INFO{Methods}->{$method{-Name}} = \%method;
    }

    # Get Event info

    foreach my $id ($C->EnumEventID()) {
        my %event = $C->GetEventInfo ($id);
        $INFO{Events}->{$event{-Name}} = \%event;
    }

    # Update the tree view

    # Insert the nodes
    for my $pnode_text qw(Properties Methods Events) {
        next if not defined $INFO{$pnode_text};

        my $pnode = $tv->InsertItem(-text => $pnode_text);

        for my $prop_name (sort keys %{$INFO{$pnode_text}}) {
            $tv-> InsertItem(
                -parent => $pnode,
                -text   => $prop_name,
            );
        }
    }

    return 1;
}

sub dispInfo {
    my ($tv, $node) = @_;

    my $pnode = $tv->GetParent($node);

    # Don't do anything for the top level nodes
    return 1 if $pnode == 0;

    my %pitem_info = $tv->GetItem($pnode);
    my $type = $pitem_info{-text};

    my %item_info = $tv->GetItem($node);
    my $name = $item_info{-text};

    my $info = $INFO{$type}->{$name};

    my $html;
    if ($type eq "Properties") {
       $html = property_html($info);
    }
    elsif ($type eq "Methods") {
       $html = method_html($info);
    }
    elsif ($type eq "Events") {
       $html = event_html($info);
    }
    else {
       $html = "<p>Unknown type: $type (you shouldn't see this)</p>";
    }

    Display($html);

    return 1;
}

sub Display{
    my $html = shift;

    # Clear the document window and send the new contents
    # Ask Microsoft why they don't support the
    # document.clear method
    $mw->BW->GetOLE()->{Document}->open("about:bank", "_self");
    $mw->BW->GetOLE()->{Document}->write($html);
    $mw->BW->GetOLE()->{Document}->close();
}

sub property_html {
    my $prop = shift;

    my $html = "<h2>Property: $prop->{-Name}</h2>";
    $html .= "<p>$prop->{-Description}</p>";
    $html .= "<table>";
    $html .= "<tr><td>Name:</td><td>$prop->{-Name}</td></tr>";
    $html .= "<tr><td>Prototype:</td><td>$prop->{-Prototype}</td></tr>";
    $html .= "<tr><td>VarType:</td><td>$prop->{-VarType}</td></tr>";
    $html .= "<tr><td>Readonly:</td><td>".($prop->{-ReadOnly}?"Yes":"No")."</td></tr>";
    $html .= "<tr><td>ID:</td><td>$prop->{-ID}</td></tr>";
    $html .= "</table>";

    my $enumstr = $prop->{-EnumValue};
    if (length($enumstr) > 0) {
        $html .= "<h3>Enumerated values</h3>";
        $html .= "<table border='1' cellspacing='0'>";
        for my $pair (split /,/, $enumstr) {
            my ($name, $value) = split /=/, $pair;
            $html .= "<tr><td>$name</td><td>$value</td></tr>";
        }
        $html .= "</table>";
    }

    return $html;
}

sub method_html {
    my $prop = shift;

    my $html = "<h2>Method: $prop->{-Name}</h2>";
    $html .= "<p>$prop->{-Description}</p>";
    $html .= "<table>";
    $html .= "<tr><td>Name:</td><td>$prop->{-Name}</td></tr>";
    $html .= "<tr><td>Prototype:</td><td>$prop->{-Prototype}</td></tr>";
    $html .= "<tr><td>ID:</td><td>$prop->{-ID}</td></tr>";
    $html .= "</table>";

    return $html;
}

sub event_html {
    my $prop = shift;

    my $html = "<h2>Event: $prop->{-Name}</h2>";
    $html .= "<p>$prop->{-Description}</p>";
    $html .= "<table>";
    $html .= "<tr><td>Name:</td><td>$prop->{-Name}</td></tr>";
    $html .= "<tr><td>Prototype:</td><td>$prop->{-Prototype}</td></tr>";
    $html .= "<tr><td>ID:</td><td>$prop->{-ID}</td></tr>";
    $html .= "</table>";

    return $html;
}

# Enumerate registry key HKCR\CLSID.  All classes with a 'Control'
# subkey are ActiveX controls
sub getInstalledControls {
    my $abort = 0;
    LoadingWindow::Show($mw);

    my @controls = ();

    my $clsidkey = Win32::TieRegistry->new(
        "HKEY_CLASSES_ROOT/CLSID/",
        { Access => "KEY_READ", Delimiter => '/', }
    );
    my $r = $clsidkey->TiedRef();

    LoadingWindow::SetRange(scalar keys %$r);

    while(my ($key, $value) = each %$r) {
       $abort = LoadingWindow::Step();
       last if $abort;

       # next, unless we have an ActiveX control
       next unless ref($value) and exists $value->{Control};

       my $ProgID = $value->{ProgID}->{'/'};

       # Some controls appear to have an empty name
       next unless defined $ProgID and length $ProgID > 0;

       my $VIProgID = $value->{VersionIndependentProgID}->{'/'};
       $ProgID .= " ($VIProgID)" if defined $VIProgID and length $VIProgID > 0;

       push @controls, $ProgID;
    }
    
    LoadingWindow::Close();
    return $abort ? undef : \@controls;
}

# package to wrap the progress bar that we show while
# loading stuff from the registry
package LoadingWindow;
our ($win,$terminate);

# Initialise and show the progress bar mini-window
sub Show {
    my $parent = shift;

    $terminate = 0;

    $win = Win32::GUI::Window->new(
        -parent      => $parent,        
        -title       => "Loading ...",
        -size        => [200,50],
        -toolwindow  => 1,
        -onTerminate => sub {$terminate = 1; 1;},
    ) or die "new Lwindow";
    $win->Center($parent);

    $win->AddProgressBar(
        -name => 'PB',
        -size => [$win->ScaleWidth(),$win->ScaleHeight()],
        -smooth => 1,
    ) or die "new Lprogress";
    $win->PB->SetStep(1);

    $win->Show();
    Win32::GUI::DoEvents();

    return 1;
}

# Set the max ranges of the progress bar
# (to the number of itertations of the
# loop we will do)
sub SetRange {
    $win->PB->SetRange(0, shift) if $win;
    return 1;
}

# Step the progress bar.  Return 1 if we expect
# the caller to abort
sub Step {
    return 1 if $terminate;

    $win->PB->StepIt() if $win;
    Win32::GUI::DoEvents();
    return 0;
}

# Hide the min-window, and free any resources
# it is using;  prepare for it to be used again
sub Close {
    if($win) {
        Win32::GUI::DoEvents();
        $win->Hide();
        Win32::GUI::DoEvents();
        undef $win;
        undef $terminate;
    }
    return 1;
}
