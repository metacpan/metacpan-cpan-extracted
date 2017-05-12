@comment off

// macro variable definition, replacement, conditional output (ifdef/else/endif)
@mark 2_BEGIN
@define TEST2 ok 2
@ifdef TEST2
TEST2
@else
error 2
@endif
@mark 2_END

// as above, but using ifndef
@mark 3_BEGIN
@eval TEST3 "ok 3"
@ifndef TEST3
error 3
@else
TEST3
@mark 3_END

// "enum" directive, "if" directive
@mark 4_BEGIN
@enum TEST4A, TEST4B, 15, TEST4C
@if TEST4C == 15
   @if TEST4A != 0
error 4
   @else
ok 4
   @endif
@else
error 4
@endif
@mark 4_END

// "elif" directive
@mark 5_BEGIN
@if 1==0
error 5
@elif 1==1
ok 5
@else
error 5
@endif
@mark 5_END

// embedded perl macro definition code
@mark 6_BEGIN
@perl_begin
sub OK6 {
print "ok 6\n";
}
@perl_end
@OK6
@mark 6_END

// comment removal
@mark 7_BEGIN
@comment off
//error 7
@comment on
//ok 7
@comment default
@mark 7_END

// protection of comments from macro substitution OFF
@mark 8_BEGIN
@define error ok
@protect off
//error 8
@mark 8_END

// protection of comments from macro substitution ON
@mark 9_BEGIN
@define ok error
@protect on
//ok 9
@mark 9_END
@protect default

@mark 10_BEGIN
@include "t/ep3.tst" INCLUDE
@mark 10_END

@mark INCLUDE_BEGIN
ok 10
@mark INCLUDE_END

@mark 11_BEGIN
@macro TEST11(B,A) A B
TEST11(11,ok)
@mark 11_END
