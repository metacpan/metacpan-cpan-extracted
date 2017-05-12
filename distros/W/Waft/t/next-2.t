
use Test;
BEGIN { plan tests => 6 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

{ package Waft::Test::A;  use vars qw( @ISA ) }
{ package Waft::Test::A2; use vars qw( @ISA ) }
{ package Waft::Test::B;  use vars qw( @ISA ) }
{ package Waft::Test::B2; use vars qw( @ISA ) }
{ package Waft::Test::C;  use vars qw( @ISA ) }
{ package Waft::Test::D;  use vars qw( @ISA ) }
{ package Waft::Test::E;  use vars qw( @ISA ) }
{ package Waft::Test::F;  use vars qw( @ISA ) }
{ package Waft::Test::G;  use vars qw( @ISA ) }
{ package Waft::Test::H;  use vars qw( @ISA ) }
{ package Waft::Test::I;  use vars qw( @ISA ) }

{ package Waft::Test::A;  sub html_escape { $_[1] . $_[0]->next('A') } }
{ package Waft::Test::A2; sub html_escape { $_[1] . $_[0]->next('A') } }
{ package Waft::Test::B;  sub html_escape { $_[1] . $_[0]->next('B') } }
{ package Waft::Test::B2; sub html_escape { $_[1] . $_[0]->next('B') } }
{ package Waft::Test::C;  sub html_escape { $_[1] . $_[0]->next('C') } }
{ package Waft::Test::D;  sub html_escape { $_[1] . $_[0]->next('D') } }
{ package Waft::Test::E;  sub html_escape { $_[1] . $_[0]->next('E') } }
{ package Waft::Test::F;  sub html_escape { $_[1] . $_[0]->next('F') } }
{ package Waft::Test::G;  sub html_escape { $_[1] . $_[0]->next('G') } }
{ package Waft::Test::H;  sub html_escape { $_[1] . $_[0]->next('H') } }
{ package Waft::Test::I;  sub html_escape { $_[1] . $_[0]->next('I') } }

{ package Waft::Test::I; @ISA = qw( ) }
{ package Waft::Test::H; @ISA = qw( Waft::Test::I ) }
{ package Waft::Test::F; @ISA = qw( Waft::Test::H ) }
{ package Waft::Test::G; @ISA = qw( Waft::Test::H ) }
{ package Waft::Test::C; @ISA = qw( ) }
{ package Waft::Test::D; @ISA = qw( Waft::Test::F Waft::Test::G ) }
{ package Waft::Test::E; @ISA = qw( ) }
{ package Waft::Test::B; @ISA = qw( Waft::Test::C Waft::Test::D
                                    Waft::Test::E Waft ) }
{ package Waft::Test::A; @ISA = qw( Waft::Test::B ) }
{ package Waft::Test::B2; @ISA = qw( Waft::Test::E Waft::Test::D
                                     Waft::Test::C Waft ) }
{ package Waft::Test::A2; @ISA = qw( Waft::Test::B2 ) }
#     I                  I
#     |                  |
#     H                  H
#    / \                / \
#   F   G              F   G
#    \ /                \ /
# C - D - E - Waft   E - D - C - Waft
# |                  |
# B                  B2
# |                  |
# A                  A2

ok( Waft::Test::A->html_escape('') eq 'ABCDFHIGHIE' );
ok( Waft::Test::A2->html_escape('') eq 'ABEDFHIGHIC' );

BEGIN { if ( eval { require warnings } ) { 'warnings'->unimport } } # 5.10
{
    local $^W;                                                      # 5.00503
    if ( eval { require warnings } ) { 'warnings'->unimport }       # 5.6

    package Waft::Test::H;
    eval q{ sub html_escape { $_[1] . $_[0]->next('H') .  $_[0]->next('h')} };

    if ( eval { require warnings } ) { 'warnings'->import }         # 5.6
}
BEGIN { if ( eval { require warnings } ) { 'warnings'->import } }   # 5.10

ok( Waft::Test::A->Waft::Test::G::html_escape('') eq 'GHIEhIE' );
ok( Waft::Test::A2->Waft::Test::G::html_escape('') eq 'GHIChIC' );

ok( Waft::Test::A->html_escape('') eq 'ABCDFHIGHIE' );

{
    local $Waft::Cache = $Waft::Cache && 0;
    ok( Waft::Test::A->html_escape('') eq 'ABCDFHIGHIEhIEhIGHIEhIE' );
}
