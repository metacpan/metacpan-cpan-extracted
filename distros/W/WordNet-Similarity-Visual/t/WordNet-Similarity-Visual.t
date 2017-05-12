# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WordNet-Similarity-Visual.t'

#########################

use Test::More tests => 7;

BEGIN { use_ok('WordNet::Similarity::Visual') };


#########################
use WordNet::QueryData;
use WordNet::Similarity::path;
use WordNet::Similarity::wup;
use WordNet::Similarity::hso;
use WordNet::Similarity::lch;
use Gtk2;

$wn = WordNet::QueryData->new;
    ok( defined $wn, "QueryData Installed");
$path = WordNet::Similarity::path->new($wn);
    ok( defined $path, "Wordnet::Similarity::path Object succesfully created");
$hso = WordNet::Similarity::hso->new($wn);
    ok( defined $hso, "Wordnet::Similarity::hso Object succesfully created");
$wup = WordNet::Similarity::wup->new($wn);
    ok( defined $wup, "Wordnet::Similarity::wup Object succesfully created");
$lch = WordNet::Similarity::lch->new($wn);
    ok( defined $lch, "Wordnet::Similarity::lch Object succesfully created" );
$window = Gtk2::Window->new("toplevel");
    ok( defined $window, "Gtk2 installed");
