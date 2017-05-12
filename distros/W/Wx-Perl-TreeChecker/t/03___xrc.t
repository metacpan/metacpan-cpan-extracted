#!/usr/bin/perl
# $Id: 03___xrc.t,v 1.2 2005/03/25 13:44:30 simonflack Exp $

use strict;
use Test::More tests => 8;

use Wx ':treectrl';
use Wx::Perl::TreeChecker;
use File::Basename;
use File::Spec;
use Getopt::Std;

BEGIN {package My::Test::App; @My::Test::App::ISA = 'Wx::App';}

my $xrc_file = File::Spec->catfile(dirname(__FILE__), 'treechecker.xrc');
my $res_handler;
getopts('i', \my %opt);

SKIP: {
    skip "XRC not supported", 8, unless eval "use Wx::XRC; 1";

    use_ok('Wx::Perl::TreeChecker::XmlHandler');

    $res_handler = Wx::Perl::TreeChecker::XmlHandler ->new ();
    ok($res_handler &&
       $res_handler -> isa ('Wx::Perl::TreeChecker::XmlHandler'),
       'created a resource handler for Wx::Perl::TreeChecker');

    my $app = new My::Test::App();
    isa_ok($app, 'My::Test::App', 'created a test app');

    my $treectrl_id = Wx::XmlResource::GetXRCID('test_treectrl');
    ok ($treectrl_id, "Got tree id $treectrl_id");

    my $treechecker_id = Wx::XmlResource::GetXRCID('test_treechecker');
    ok ($treechecker_id, "Got tree id $treechecker_id");

    my $window = $app -> GetTopWindow ();
    my $treectrl = $app -> GetTopWindow -> FindWindow($treectrl_id);
    isa_ok ($treectrl, 'Wx::TreeCtrl', 'test_treectrl is a Wx::TreeCtrl');

    my $treechkr = $app -> GetTopWindow -> FindWindow($treechecker_id);
    isa_ok ($treechkr, 'Wx::Perl::TreeChecker',
            'test_treechecker is a TreeChecker');

    # promote treectrl to a treechecker
    Wx::Perl::TreeChecker->Convert($treectrl);
    isa_ok ($treectrl, 'Wx::Perl::TreeChecker',
            'converted TreeCtrl to a TreeChecker');

    if ($opt{i}) {
        $app -> GetTopWindow() -> Show (1);
        $app -> MainLoop;
        exit
    }
}



package My::Test::App;

sub OnInit {
    my $self = shift;

    my $xrc = Wx::XmlResource -> new;
    $xrc -> InitAllHandlers;
    $xrc -> AddHandler ($res_handler);
    $xrc -> Load ($xrc_file);

    my $frame = $xrc -> LoadFrame (undef, 'xrc_test');
    $self -> SetTopWindow ($frame);
    1;
}
