#!perl -w

# Show all the standard images that can be loaded using
# Win32::GUI::Icon->new(ID)
# Win32::GUI::Cursor->new(ID)  and
# Win32::GUI::Bitmap->new(ID)
#
# Robert May, May 2006
#

use strict;
use warnings;
use Win32::GUI 1.03_03, qw(CW_USEDEFAULT :icon :cursor :bitmap);

my ($icon, $cursor, $bitmap);

my @icons   = sort grep /^IDI_|^OIC_/, @{Win32::GUI::Constants::_export_ok()};
my @cursors = sort grep /^IDC_|^OCR_/, @{Win32::GUI::Constants::_export_ok()};
my @bitmaps = sort grep /^OBM_/,       @{Win32::GUI::Constants::_export_ok()};


my @menu_defn = (
    "File"  => "File",
    ">Exit" => { -name => "Exit", -onClick => sub{-1}, },
);

push @menu_defn, "Icons", "Icon";
for my $i (@icons) {
    push @menu_defn, ">$i", { -name => $i, -onClick => eval "sub {showIcon(\"$i\")}", };
}
push @menu_defn, "Cursors", "Cursor";
for my $i (@cursors) {
    push @menu_defn, ">$i", { -name => $i, -onClick => eval "sub {showCursor(\"$i\")}", };
}
push @menu_defn, "Bitmaps", "Bitmap";
for my $i (@bitmaps) {
    push @menu_defn, ">$i", { -name => $i, -onClick => eval "sub {showBitmap(\"$i\")}", };
}

my $menu = Win32::GUI::Menu->new(@menu_defn);

my $mw = Win32::GUI::Window->new(
    -title => "Standard Win32 Icons, Cursors and Bitmaps",
    -size  => [400,300],
    -left  => CW_USEDEFAULT,
    -menu  => $menu,
);

$mw->AddLabel(
    -name => 'ICO',
    -pos  => [30,10],
    -size => [32, 32],
    -icon => 0,
);

$mw->AddLabel(
    -name => 'CUR',
    -pos  => [80,10],
    -size => [32, 32],
    -icon => 0,
);

$mw->AddLabel(
    -name   => 'BMP',
    -pos    => [130,10],
    -size   => [100, 100],
    -bitmap => 0,
);

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();
undef $mw;
exit(0);

sub showIcon {

    $menu->{$icon->{_current}}->Checked(0) if($icon);
    my $new = shift;
    $menu->{$new}->Checked(1);
    
    $icon = Win32::GUI::Icon->new(eval $new) or die "No icon: $new";
    $icon->{_current} = $new;

    $mw->ICO->Change(-icon => $icon);
    $mw->SetIcon($icon);

    return 0;
}

sub showCursor {

    $menu->{$cursor->{_current}}->Checked(0) if($cursor);
    my $new = shift;
    $menu->{$new}->Checked(1);
    
    $cursor = Win32::GUI::Cursor->new(eval $new) or die "No icon: $new";
    $cursor->{_current} = $new;

    $mw->CUR->Change(-icon => $cursor);
    $mw->ChangeCursor($cursor);

    return 0;
}

sub showBitmap {

    $menu->{$bitmap->{_current}}->Checked(0) if($bitmap);
    my $new = shift;
    $menu->{$new}->Checked(1);
    
    $bitmap = Win32::GUI::Bitmap->new(eval $new) or die "No icon: $new";
    $bitmap->{_current} = $new;

    $mw->BMP->Change(-bitmap => $bitmap);

    return 0;
}
