#!perl -w
use strict;
use warnings;

use Win32::GUI();
use Win32::GUI::Constants qw(CW_USEDEFAULT);

my $num_constants = @{Win32::GUI::Constants::_export_ok()};

my $mw = Win32::GUI::Window->new(
    -title => "Win32::GUI::Constants",
    -left  => CW_USEDEFAULT,
    -size  => [580,300],
    -resizable => 0,
    -maximizebox => 0,
);

$mw->AddListbox(
    -name    => 'LB',
    -pos     => [10,10],
    -size    => [230,$mw->ScaleHeight()-10],
    -vscroll => 1,
    -onSelChange => \&newSelection,
);

$mw->LB->Add(sort @{Win32::GUI::Constants::_export_ok()});

$mw->AddButton(
    -name    => 'BT',
    -text    => 'Exit',
    -size    => [80,25],
    -left    => $mw->ScaleWidth()-90,
    -top     => $mw->LB->Top()+$mw->LB->Height()-25,
    -onClick => sub{-1;},
);

$mw->AddGroupbox(
    -name  => 'GB',
    -title => 'Information',
    -pos   => [250,10],
    -size  => [$mw->ScaleWidth()-260, $mw->BT->Top()-20],
);
$mw->AddLabel(
    -name   => 'LBL',
    -left   => $mw->GB->Left()+10,
    -top    => $mw->GB->Top()+20,
    -width  => $mw->GB->ScaleWidth()-20,
    -height => $mw->GB->ScaleHeight()-40,
);

$mw->LBL->Text(get_label_text());

$mw->Show();
Win32::GUI::Dialog();
$mw->Hide();

exit(0);

sub newSelection
{
    my $lb = shift;

    # Set the label text to reflect the change
    my $item = $lb->GetCurSel();
    my $text = $lb->GetText($item);
    $lb->GetParent()->LBL->Text(get_label_text($text));

    return 1;
}
	
sub get_label_text
{
    my $name = shift;

    my $text = "Select one of the $num_constants constants from the list to the left to see details about it below.\r\n\r\n";

    $name = 'Not selected' unless defined $name;
    $text .= sprintf("%-*s\t%s\r\n\r\n", 10, "Constant:", $name);

    my $value = Win32::GUI::Constants::constant($name);
    if(defined $value) {
	    $text .= sprintf("%-*s\t%d\r\n", 10, "Decimal:", $value);
	    $text .= sprintf("%-*s\t0x%08X\r\n", 10, "Hex:", $value);
	    $text .= sprintf("%-*s\t0b%032b\r\n", 10, "Binary:", $value);
    }

    return $text;
}
