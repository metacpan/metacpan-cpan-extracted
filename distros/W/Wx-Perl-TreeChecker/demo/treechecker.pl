#############################################################################
## Name:        treechecker.pl
## Purpose:     Wx::Perl::TreeChecker Sample
## Author:      Simon Flack
## Modified by: $Author: simonflack $ on $Date: 2003/08/30 15:39:31 $
## Created:     12/04/2003
## RCS-ID:      $Id: treechecker.pl,v 1.1.1.1 2003/08/30 15:39:31 simonflack Exp $
#############################################################################

use strict;
use Wx;
use Wx::Perl::Carp;

package MyTreeChecker_App;
use vars '@ISA';
@ISA = 'Wx::App';

sub OnInit {
    my $self = shift;
    my $frame = MyTreeChecker_Frame->new('Wx::Perl::TreeChecker Sample',
                                         Wx::wxDefaultPosition(), [450,350]);
    $self -> SetTopWindow ($frame);
    $frame -> Show(1);
    1;
}

package MyTreeChecker_Frame;
use vars '@ISA';
@ISA = 'Wx::Frame';
use Wx qw(:sizer :misc);
use Wx::Perl::TreeChecker;

sub new {
    my $class = shift;
    my ($title, $pos, $size) = @_;

    my $self = $class->SUPER::new (undef, -1, $title, $pos, $size);
    $self -> SetIcon (Wx::GetWxPerlIcon());

    my $filemenu = new Wx::Menu;
    my $optsmenu = new Wx::Menu;
    my $helpmenu = new Wx::Menu;
    my $menubar = new Wx::MenuBar;
    $filemenu -> Append (1, 'E&xit');
    $optsmenu -> AppendCheckItem (2, 'Allow Multiple Selection');
    $optsmenu -> AppendSeparator ();
    $optsmenu -> AppendRadioItem (3, 'Select Items only');
    $optsmenu -> AppendRadioItem (4, 'Select Containers only');
    $optsmenu -> AppendRadioItem (5, 'Select Items and Containers');
    $optsmenu -> Check(2, 1);
    $optsmenu -> Check(5, 1);
    $helpmenu -> Append (6, '&About');
    $menubar -> Append ($filemenu, '&File');
    $menubar -> Append ($optsmenu, '&Options');
    $menubar -> Append ($helpmenu, '&Help');
    $self -> SetMenuBar ($menubar);

    use Wx::Event 'EVT_MENU', 'EVT_BUTTON';
    EVT_MENU ($self, 1, \&OnQuit);
    EVT_MENU ($self, 2, \&OnToggleMultiple);
    EVT_MENU ($self, 3, \&OnToggleItems);
    EVT_MENU ($self, 4, \&OnToggleContainers);
    EVT_MENU ($self, 5, \&OnToggleSelectAll);
    EVT_MENU ($self, 6, \&OnAbout);

    my $panel = new Wx::Panel ($self);
    my $sizer = new Wx::BoxSizer (wxVERTICAL);
    $self -> {treechecker} = new Wx::Perl::TreeChecker ($panel, -1,
                                                        wxDefaultPosition,
                                                        wxDefaultSize);
    $self -> {textctrl} = new Wx::TextCtrl($panel, -1, '', wxDefaultPosition,
                                          wxDefaultSize, Wx::wxTE_MULTILINE());
    $self -> {button} = new Wx::Button ($panel, -1, 'GetSelection');
    $sizer -> Add ($self -> {treechecker}, 1, wxGROW);
    $sizer -> Add ($self -> {button});
    $sizer -> Add ($self -> {textctrl}, 1, wxGROW);
    $panel -> SetSizer ($sizer);

    $self -> fill_treechecker();
    EVT_BUTTON($self, $self -> {button}, \&OnClick);

    Wx::Log::SetActiveTarget (new Wx::LogTextCtrl ($self -> {textctrl}));
    return $self;
}

sub fill_treechecker {
    my $self = shift;
    my $treechecker = $self -> {treechecker};
    my $root_id = $treechecker -> AddRoot('CPAN', td('CPAN'));
    _populate_tree($treechecker, $root_id,
    {
      'Archiving, Compression, Conversion' => {
        'Archive::' => ['Archive::Ar', 'Archive::Parity',
                        'Archive::Tar', 'Archive::Zip'],
        'Compress::' => ['Compress::Bzip2', 'Compress::LZO', 'Compress::Zlib'],
        'Convert::' => ['Convert::Base', 'Convert::Morse', 'Convert::UU'],
        'RPM::' => ['RPM', 'RPM::Constants', 'RPM::Database', 'RPM::Headers']
    },
      'Miscellaneous' => [qw(AI::Fuzzy Astro::MoonPhase CPAN CompBio
                             Games::Crosswords Games::Worms Hints
                             Penguin::Easy)],
      'String Processing' => {
        'Lingua::' => ['Lingua::Conjunction', 'Lingua::EN::Cardinal'],
        'PDF::' => ['PDF', 'PDF::Core', 'PDF::Create'],
        'RDF::' => ['RDF::Core'],
        'String::' => ['Sting::Approx', 'String::Edit'],
        'XML::' => ['XML::Parser', 'XML::Simple', 'XML::Twig', 'XML::LibXML'],
        'Text::' => ['Text::Balanced', 'Text::CSV', 'Text::TeX'],
      },
    });
    $treechecker -> Expand ($root_id);
}

sub _populate_tree {
    my ($tree, $id, $data) = @_;
    # recursively build a tree control
    return unless $data && ref $data;
    if (ref $data eq 'HASH') {
        foreach (sort keys %$data) {
            my $container = $tree -> AppendContainer($id, $_, td($_));
            _populate_tree($tree, $container, $data -> {$_});
        }
    } elsif (ref $data eq 'ARRAY') {
        $tree -> AppendItem($id, $_, td($_)) foreach @$data;
    }
}

sub td {
    return new Wx::TreeItemData(shift);
}

sub OnQuit {
    my ($self, $evt) = @_;
    $self -> Close (1);
}

sub OnAbout {
    my ($self, $evt) = @_;
    my $about = <<ABOUT;
    Wx::Perl::TreeChecker $Wx::Perl::TreeChecker::VERSION
    Author:  Simon Flack
    CPAN ID: SIMONFLK
ABOUT
    Wx::MessageBox ($about,"Wx::Perl::TreeChecker sample", Wx::wxOK(), $self);
}

sub OnClick {
    my ($self, $evt) = @_;

    Wx::LogMessage('%s', '---------------------------------');
    Wx::LogMessage('%s', 'The following items were checked:');
    my $treechecker = $self -> {treechecker};
    my @sel = $treechecker -> GetSelections;
    Wx::LogMessage('    %s', $_) for map {$treechecker -> GetPlData($_)}
                    grep {!$treechecker -> IsContainer($_)} @sel;
}

sub OnToggleMultiple {
    my ($self, $evt) = @_;
    my $tree = $self -> {treechecker};
    $tree -> UnselectAll();
    $tree -> allow_multiple($evt->IsChecked);
}

sub OnToggleItems {
    my ($self, $evt) = @_;
    my $tree = $self -> {treechecker};
    $tree -> UnselectAll();
    $tree -> containers_only(0);
    $tree -> items_only(1);
}

sub OnToggleContainers {
    my ($self, $evt) = @_;
    my $tree = $self -> {treechecker};
    $tree -> UnselectAll();
    $tree -> items_only(0);
    $tree -> containers_only(1);
}

sub OnToggleSelectAll {
    my ($self, $evt) = @_;
    my $tree = $self -> {treechecker};
    $tree -> UnselectAll();
    $tree -> items_only(0);
    $tree -> containers_only(0);
}

##############################################################################

package main;
use vars '$VERSION';
$VERSION = sprintf'%d.%02d', q$Revision: 1.1.1.1 $ =~ /: (\d+)\.(\d+)/;

my $sample = new MyTreeChecker_App;
$sample -> MainLoop;
