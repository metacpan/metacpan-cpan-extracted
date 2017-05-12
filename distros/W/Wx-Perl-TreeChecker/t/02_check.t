#!/usr/bin/perl
# $Id: 02_check.t,v 1.2 2004/08/09 19:09:00 simonflack Exp $

use strict;
use Test::More tests => 7;

use Wx ':treectrl';
use File::Basename;
use File::Spec;
use Getopt::Std;

BEGIN {package My::Test::App; @My::Test::App::ISA = 'Wx::App';}

getopts('i', \my %opt);

BEGIN { use_ok('Wx::Perl::TreeChecker', ':status'); }

my $app = new My::Test::App;
my $treechecker = $app -> add_treechecker();
isa_ok($treechecker, 'Wx::Perl::TreeChecker', 'created a treechecker object');

my $root = $treechecker -> AddRoot('/', '/');
my %tree_layout = (
    'Makefile.PL' => 1,
    lib => {
        Wx => {
            Perl => {
                'TreeChecker.pm' => 1,
                 TreeChecker => {
                    'XmlHandler.pm' => 1,
                 },
            },
        },
    },
);

my $lookup = build_tree($treechecker, $root, '', \%tree_layout);
ok(!$treechecker -> GetSelections(), 'no selections');
$treechecker -> SelectItem ($root);
my @selections = $treechecker -> GetSelections;
is_selection (\@selections, [qw(/ /lib /lib/Wx /lib/Wx/Perl
                                /lib/Wx/Perl/TreeChecker Makefile.PL
                TreeChecker.pm XmlHandler.pm)]);
$treechecker -> UnselectAll();

# test compact selection
$treechecker->SelectItem($lookup->{'/lib/Wx/Perl/TreeChecker/XmlHandler.pm'});
@selections = $treechecker -> GetSelections(TC_SEL_COMPACT);
is_selection(\@selections, ['/lib/Wx/Perl/TreeChecker']);

$treechecker->SelectItem($lookup->{'/lib/Wx/Perl/TreeChecker.pm'});
@selections = $treechecker -> GetSelections(TC_SEL_COMPACT);
is_selection(\@selections, ['/lib']);

# UnSelectItem
$treechecker->UnSelectItem($lookup->{'/lib/Wx/Perl/TreeChecker.pm'});
@selections = $treechecker -> GetSelections(TC_SEL_COMPACT);
is_selection(\@selections, ['/lib/Wx/Perl/TreeChecker']);




sub is_selection {
    my ($selections, $compare) = @_;
    my @sel_data;
    push @sel_data, $treechecker -> GetPlData($_) foreach @$selections;
    is_deeply([sort @sel_data], $compare, 'correct selection');
}

if ($opt{i}) {
    $app -> GetTopWindow() -> Show (1);
    $app -> MainLoop;
    exit
}

sub tdata ($) {
  return new Wx::TreeItemData(shift);
}
sub build_tree {
    my ($tree, $parent, $path, $layout) = @_;

    my $lookup = {};
    foreach (sort keys %$layout) {
        my $this_path = $path . '/' . $_;
        if (ref $layout -> {$_}) {
            $lookup -> {$this_path} = $tree -> AppendContainer ($parent, $_,
                                                                tdata $this_path);
            my $sub_lookup = build_tree ($tree, $lookup->{$this_path},
                                         $this_path, $layout -> {$_});
            %$lookup = (%$lookup, %$sub_lookup);
        } else {
            $lookup -> {$this_path} = $tree -> AppendItem ($parent, $_,
                                                           tdata $_);
        }
    }
    return $lookup;
}

package My::Test::App;
use Wx qw/:misc :sizer/;

sub OnInit {
    my $self = shift;

    my $frame = new Wx::Frame (undef, -1, 'Wx::Perl::TreeChecker unit test',
                               wxDefaultPosition, [500,300]);

    $self -> {panel} = new Wx::Panel ($frame, -1);

    my $static_box = new Wx::StaticBox ($self -> {panel}, -1, 'TreeChecker');
    $self -> {sizer} = new Wx::StaticBoxSizer ($static_box, wxVERTICAL);
    $self -> {panel} -> SetSizer ($self -> {sizer});

    $self -> SetTopWindow ($frame);
    1;
}

sub add_treechecker {
    my $self = shift;
    my (@args) = @_;

    $self -> {tree} = new Wx::Perl::TreeChecker ($self -> {panel}, -1, @args);
    $self -> {sizer} -> Add ($self -> {tree}, 1, wxGROW);
    return $self -> {tree};
}
