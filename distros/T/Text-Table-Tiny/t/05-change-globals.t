use strict;
use Test::More tests => 4;
use Text::Table::Tiny qw/ generate_table /;

$Text::Table::Tiny::COLUMN_SEPARATOR = '!';
$Text::Table::Tiny::ROW_SEPARATOR = '_';
$Text::Table::Tiny::CORNER_MARKER = '*';
$Text::Table::Tiny::HEADER_ROW_SEPARATOR = '#';
$Text::Table::Tiny::HEADER_CORNER_MARKER = '8';

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
