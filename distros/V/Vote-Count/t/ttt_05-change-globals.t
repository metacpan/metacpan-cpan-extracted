use strict;
use Test::More tests => 4;
use Vote::Count::TextTableTiny qw/ generate_table /;

$Vote::Count::TextTableTiny::COLUMN_SEPARATOR = '!';
$Vote::Count::TextTableTiny::ROW_SEPARATOR = '_';
$Vote::Count::TextTableTiny::CORNER_MARKER = '*';
$Vote::Count::TextTableTiny::HEADER_ROW_SEPARATOR = '#';
$Vote::Count::TextTableTiny::HEADER_CORNER_MARKER = '8';

my $rows = [
   [ 'Elvis', 'Priscilla' ],
   [ 'Liquor', 'Beer', 'Wine' ],
   [ undef, undef, undef, "That's showbiz!" ],
];

my $t0 = generate_table( rows => $rows );
is($t0, q%*________*___________*______*_________________*
! Elvis  ! Priscilla !      !                 !
! Liquor ! Beer      ! Wine !                 !
!        !           !      ! That's showbiz! !
*________*___________*______*_________________*%,
'just rows'
);

my $t1 = generate_table( rows => $rows, header_row => 1 );
is($t1, q%*________*___________*______*_________________*
! Elvis  ! Priscilla !      !                 !
*________*___________*______*_________________*
! Liquor ! Beer      ! Wine !                 !
!        !           !      ! That's showbiz! !
*________*___________*______*_________________*%,
'rows and header row');

my $t2 = generate_table( rows => $rows, separate_rows => 1 );
is($t2,q%*________*___________*______*_________________*
! Elvis  ! Priscilla !      !                 !
*________*___________*______*_________________*
! Liquor ! Beer      ! Wine !                 !
*________*___________*______*_________________*
!        !           !      ! That's showbiz! !
*________*___________*______*_________________*%,
'separate rows');

my $t3 = generate_table( rows => $rows, header_row => 1, separate_rows => 1 );
is($t3,q%*________*___________*______*_________________*
! Elvis  ! Priscilla !      !                 !
8########8###########8######8#################8
! Liquor ! Beer      ! Wine !                 !
*________*___________*______*_________________*
!        !           !      ! That's showbiz! !
*________*___________*______*_________________*%,
'header and separate rows');
