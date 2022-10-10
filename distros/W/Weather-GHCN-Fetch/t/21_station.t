# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Weather::GHCN::Station;

package Weather::GHCN::Station;

use Test::More tests => 23;
use Test::Exception;

use Const::Fast;

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';

my $stn_obj = Weather::GHCN::Station->new( 
    id      => 'CA006105976', 
    country => 'CA', 
    state   => 'ON', 
    active  => '1889-2022', 
    lat     => '45.3833', 
    long    => '-75.7167', 
    elev    => '79', 
    name    => 'OTTAWA CDA', 
    gsn     => ''
);

isa_ok $stn_obj, 'Weather::GHCN::Station';

can_ok $stn_obj, qw(
    Headings
    headings
    add_note
    row
    coordinates
    description
    error_count
    grid
    selected
    url
);


my $got;
my $expected;

my @headings = Weather::GHCN::Station->Headings;
my $hdr = join ',', @headings;
like $hdr, qr/StationId, .*? Location/xms, 'Headings result';

@headings = $stn_obj->headings;
$hdr = join ',', @headings;
like $hdr, qr/StationId, .*? Location/xms, 'headings list result';

my $aref = $stn_obj->headings;
$hdr = join ',', $aref->@*;
like $hdr, qr/StationId, .*? Location/xms, 'headings scalar result';

$stn_obj->add_note('456', 'note number 456');
ok $stn_obj->note_nrs->contains(456), 'note 456 added';

$stn_obj->add_note('789');
ok $stn_obj->note_nrs->contains(789), 'note 789 added without message';

is $stn_obj->note_nrs->cardinality(), 2, 'now there are three notes';

ok !$stn_obj->note_nrs->contains(999), 'notes do not include 999';

my @row_list = $stn_obj->row;
my $row = join ',', map { $_ //= '' } @row_list;
like $row, qr/CA006105976, .*? OTTAWA\sCDA/xms, 'row list result';

$aref = $stn_obj->row;
$row = join ',', map { $_ //= '' } $aref->@*;
like $row, qr/CA006105976, .*? OTTAWA\sCDA/xms, 'row scalar result';
like $row, qr/ \[ (\d+) ( [,] (\d+) )* \] /xms, 'row contains note references';

my $coord = $stn_obj->coordinates;
like $coord, qr/45.383300 -75.716700/, 'coordinates result';

my $desc = $stn_obj->description;
like $desc, qr/ \A Id: \s* CA006105976 \n Name: /xms, 'description result';

is $stn_obj->error_count, 0, 'error count result';

is $stn_obj->grid, '45.4N 75.7W', 'grid result';

is $stn_obj->selected, '', 'selected result';

like $stn_obj->url, qr{ \A https://www }xms, 'url result';

# capture stderr so we can check that notes < $NOTE_THRESHOLD (50)
# and which are deemed to be errors are automatically sent to STDERR
# and when the 3rd argument to add_note (verbose) is true, that
# warnings are also sent to STDERR.
do {
    my $stderr;
    local *STDERR;
    # uncoverable branch true
    open STDERR, '>>', \$stderr or die;
    my $verbose = $TRUE;

    $stn_obj->add_note('3', 'error note number 3 added');
    ok $stn_obj->note_nrs->contains(3), 'note 3 found';
    like $stderr, qr/error note number 3 added/, 'error message went to STDERR';
    $stderr = $EMPTY;
    $stn_obj->add_note('50', 'warning note number 50 added (verbose = 1)', $verbose);   
    like $stderr, qr/warning note/, 'verbose - warning message went to STDERR';
};

# new object, so we can test row() when there are no notes
$stn_obj = Weather::GHCN::Station->new( 
    id      => 'CA006105976', 
    country => 'CA', 
    state   => 'ON', 
    active  => '1889-2022', 
    lat     => '45.3833', 
    long    => '-75.7167', 
    elev    => '79', 
    name    => 'OTTAWA CDA', 
    gsn     => ''
);

@row_list = $stn_obj->row;
$row = join ',', map { $_ //= '' } @row_list;
like $row, qr/ OTTAWA \s CDA,,,45 /xms, 'row contains note references';

# for test coverage
subtest 'field accessors' => sub {
    ok $stn_obj->id,           'detail';
    ok $stn_obj->country,      'country';
    ok $stn_obj->state,        'state';
    ok $stn_obj->active,       'active';
    ok $stn_obj->lat,          'lat';
    ok $stn_obj->long,         'long';
    ok $stn_obj->elev,         'elev';
    ok $stn_obj->name,         'name';
    is $stn_obj->gsn, $EMPTY,  'gsn';
    ok $stn_obj->elems_href,   'elems_href';
    is $stn_obj->idx, undef,   'idx';
};