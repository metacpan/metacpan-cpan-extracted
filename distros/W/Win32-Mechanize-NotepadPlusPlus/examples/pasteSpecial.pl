#!/usr/bin/env perl
################################################
# PasteSpecial for Notepad++
#   List formats currently on the clipboard
#   Allows you to choose one of those formats
#   Will paste the selected type (UTF8-encoded)
#   at the current location in the active file
################################################
# HISTORY
#   v0.1: STDIN-based choice
#   v1.0: DialogBox choice
#   v2.0: Add REFRESH button to update the ListBox
#         Defaults to selecting/displaying the first Clipboard variant
#         Persist checkbox allows dialog to stay open for multiple pastes
################################################

use 5.010;
use warnings;
use strict;
use Win32::Clipboard;
use Win32::GUI;
use Win32::GUI::Constants qw/CW_USEDEFAULT/;
use Encode;
use Win32::Mechanize::NotepadPlusPlus 0.004 qw/:main/;   # this works even with v0.004, even without bugfix for prompt()

our $VERSION = 'v2.0';

BEGIN {
    binmode STDERR, ':utf8';
    binmode STDOUT, ':utf8';
}

my %map = (
    CF_TEXT()           => 'CF_TEXT',
    CF_BITMAP()         => 'CF_BITMAP',
    CF_METAFILEPICT()   => 'CF_METAFILEPICT',
    CF_SYLK()           => 'CF_SYLK',
    CF_DIF()            => 'CF_DIF',
    CF_TIFF()           => 'CF_TIFF',
    CF_OEMTEXT()        => 'CF_OEMTEXT',
    CF_DIB()            => 'CF_DIB',
    CF_PALETTE()        => 'CF_PALETTE',
    CF_PENDATA()        => 'CF_PENDATA',
    CF_RIFF()           => 'CF_RIFF',
    CF_WAVE()           => 'CF_WAVE',
    CF_UNICODETEXT()    => 'CF_UNICODETEXT',
    CF_ENHMETAFILE()    => 'CF_ENHMETAFILE',
    CF_HDROP()          => 'CF_HDROP',
    CF_LOCALE()         => 'CF_LOCALE',
);
my %rmap; @rmap{values %map} = keys %map;

my $CLIP = Win32::Clipboard;

my $answer = runDialog();
#editor->addText(Encode::encode("UTF8", $answer)) if defined $answer;   #v1.3: moved to the PASTE button, below
exit;

sub formats {
    my @f = $CLIP->EnumFormats();
    foreach my $format (sort {$a <=> $b} @f) {
        $map{$format} //= $CLIP->GetFormatName($format) // '<unknown>';
        $rmap{ $map{$format} } = $format;
    }
    return @f;
}

sub runDialog {
    my $clipboard;
    my $persist = 1;

    my $dlg = Win32::GUI::Window->new(
        -title          => sprintf('Notepad++ Paste Special %s', $VERSION),
        -left           => CW_USEDEFAULT,
        -top            => CW_USEDEFAULT,
        -size           => [580,300],
        -resizable      => 0,
        -maximizebox    => 0,
        -hashelp => 0,
        -dialogui => 1,
    );
    my $icon = Win32::GUI::Icon->new(100);              # v1.1: change the icon
    $dlg->SetIcon($icon) if defined $icon;

    my $update_preview = sub {
        my $self = shift // return -1;
        my $value = $self->GetText($self->GetCurSel());
        my $f=$rmap{$value};
        $clipboard = $CLIP->GetAs($f);
        $clipboard = Encode::decode('UTF16-LE', $clipboard) if $f == CF_UNICODETEXT();
        (my $preview = $clipboard) =~ s/([^\x20-\x7F\r\n])/sprintf '\x{%02X}', ord $1/ge;
        $preview =~ s/\R/\r\n/g;
        $self->GetParent()->PREVIEW->Text( $preview );
        return 1;
    };
    my $lb = $dlg->AddListbox(
        -name           => 'LB',
        -pos            => [10,10],
        -size           => [230, $dlg->ScaleHeight()-10],
        -vscroll        => 1,
        -onSelChange    => $update_preview,             # v1.2: externalize this callback so it can be run from elsewhere
    );

    my $refresh_formats = sub {
        my $lb = $dlg->LB;
        my $selected_idx = $lb->GetCurSel() // 0;
        my $selected_txt = ((0<=$selected_idx) && ($selected_idx < $lb->Count)) ? $lb->GetText($selected_idx) : '';
        $lb->RemoveItem(0) while $lb->Count;
        $lb->Add( @map{ sort {$a<=>$b} formats() } );
        my $new_idx = $selected_txt ? $lb->FindStringExact($selected_txt) : undef;
        $new_idx = undef unless defined($new_idx) && (0 <= $new_idx) && ($new_idx < $lb->Count);
        $lb->Select( $new_idx//0 );
        $update_preview->( $lb );
    };

    my $button_top = $dlg->LB->Top()+$dlg->LB->Height()-25;

    $dlg->AddButton(                                    # v1.2: add this button
        -name    => 'REFRESH',
        -text    => 'Refresh',
        -size    => [80,25],
        -left    => $dlg->ScaleWidth()-90*3,
        -top     => $button_top,
        -onClick => sub{
            $refresh_formats->();
            1;
        },
    );

    $dlg->AddButton(
        -name    => 'OK',
        -text    => 'Paste',
        -size    => [80,25],
        -left    => $dlg->ScaleWidth()-90*2,
        -top     => $button_top,
        -onClick => sub{                # v1.3: allow to persist after paste: TODO: move the editor->addText here
            editor->addText( Encode::encode("UTF8", $clipboard) ) if defined $clipboard;
            return $persist ? 1 : -1;
        },
    );

    $dlg->AddButton(
        -name    => 'CANCEL',
        -text    => 'Cancel',
        -size    => [80,25],
        -left    => $dlg->ScaleWidth()-90*1,
        -top     => $button_top,
        -onClick => sub{ $clipboard=undef; -1; },
    );

    $dlg->AddGroupbox(
        -name  => 'GB',
        -title => 'Preview',
        -pos   => [250,10],
        -size  => [$dlg->ScaleWidth()-260, $button_top-20],
    );

    $dlg->AddLabel(
        -name           => 'PREVIEW',
        -left           => $dlg->GB->Left()+10,
        -top            => $dlg->GB->Top()+20,
        -width          => $dlg->GB->ScaleWidth()-20,
        -height         => $dlg->GB->ScaleHeight()-40,
    );

    $dlg->AddCheckbox(
        -name => 'CB',
        -text => 'Persist',
        -pos => [$dlg->GB->Left(), $button_top],
        -onClick => sub {
            $persist = !$persist;
            1;
        },
    );

    $dlg->CB->SetCheck($persist);
    $refresh_formats->();
    $dlg->Show();
    Win32::GUI::Dialog();
    return $clipboard;
}
