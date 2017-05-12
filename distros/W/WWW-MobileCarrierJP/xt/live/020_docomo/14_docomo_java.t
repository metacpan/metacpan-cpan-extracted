use strict;
use warnings;
use Test::Base;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
use WWW::MobileCarrierJP::DoCoMo::Java;

plan tests => 2 + 2 * blocks;

my $dat = WWW::MobileCarrierJP::DoCoMo::Java->scrape;
is ref($dat), 'ARRAY';
is join(',', sort(keys %{$dat->[0]})), 'default_font,display,heap,model,profile,size';

filters { info => [qw/yaml/] };

run {
    my $block = shift;
    check($block->info);
};

sub check {
    my ($info, ) = @_;
    my ($model, ) = grep { $_->{model} eq $info->{model} } @$dat;
    ok $model, "got a $info->{model} phone info";
    is_deeply $model => $info, "check the $info->{model}";
}

__END__

===
--- info
model   : F-01A
profile : Star-1.0
size :
    jar : 2048
    scratchpad : 0
display :
    panel :
        width : 480
        height : 864
    canvas :
        width : 480
        height : 864
heap :
    full_appli :
        java : 23552
        native : 8192
    widget : 2503
default_font :
    width : 24
    height : 24

===
--- info
model   : N-04A
profile : Star-1.0
size :
    jar : 2048
    scratchpad : 0
display :
    panel :
        width : 480
        height : 854
    canvas :
        width : 480
        height : 854
heap :
    full_appli :
        java : 32768
        native : 0
    widget : 3527
default_font :
    width : 24
    height : 24

===
--- info
model   : P-07A
profile : Star-1.1
size :
    jar : 2048
    scratchpad : 0
display :
    panel :
        width : 480
        height : 854
    canvas :
        width : 480
        height : 854
heap :
    full_appli :
        java : 20480
        native : 4608
    widget : 2048
default_font :
    width : 24
    height : 24

===
--- info
model   : N-03B
profile : Star-1.1
size :
    jar : 2048
    scratchpad : 0
display :
    panel :
        width : 480
        height : 854
    canvas :
        width : 480
        height : 854
heap :
    full_appli :
        java : 32768
        native : 0
    widget : 3527
default_font :
    width : 24
    height : 24

===
--- info
model   : SH-01B
profile : Star-1.2
size :
    jar : 2048
    scratchpad : 0
display :
    panel :
        width : 480
        height : 854
    canvas :
        width : 480
        height : 854
heap :
    full_appli :
        java : 16384
        native : 25088
    widget : 1600
default_font :
    width : 24
    height : 24

===
--- info
model   : N-02B
profile : Star-1.2
size :
    jar : 2048
    scratchpad : 0
display :
    panel :
        width : 480
        height : 854
    canvas :
        width : 480
        height : 854
heap :
    full_appli :
        java : 32768
        native : 0
    widget : 3527
default_font :
    width : 24
    height : 24

===
--- info
model   : F503I
profile : DoJa-1.0
size :
    jar : 10
    scratchpad : 10
display :
    panel :
        width : 120
        height : 130
    canvas :
        width : 120
        height : 130
heap :
    full_appli :
        java : 600
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : SO503IS
profile : DoJa-1.0
size :
    jar : 10
    scratchpad : 10
display :
    panel :
        width : 120
        height : 120
    canvas :
        width : 120
        height : 120
heap :
    full_appli :
        java : 350
        native : 0
default_font :
    width : 14
    height : 14

===
--- info
model   : NM850IG
profile : DoJa-1.5OE
size :
    jar : 30
    scratchpad : 100
display :
    panel :
        width : 176
        height : 144
    canvas :
        width : 176
        height : 144
heap :
    full_appli :
        java : 555
        native : 455
default_font :
    width : 12
    height : 12

===
--- info
model   : N600I
profile : DoJa-1.5OE
size :
    jar : 30
    scratchpad : 100
display :
    panel :
        width : 176
        height : 180
    canvas :
        width : 176
        height : 180
heap :
    full_appli :
        java : 1024
        native : 2048
default_font :
    width : 12
    height : 12

===
--- info
model   : D504I
profile : DoJa-2.0
size :
    jar : 30
    scratchpad : 100
display :
    panel :
        width : 132
        height : 144
    canvas :
        width : 132
        height : 144
heap :
    full_appli :
        java : 1024
        native : 524
default_font :
    width : 12
    height : 12

===
--- info
model   : F504IS
profile : DoJa-2.0
size :
    jar : 30
    scratchpad : 100
display :
    panel :
        width : 132
        height : 136
    canvas :
        width : 132
        height : 136
heap :
    full_appli :
        java : 1500
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : FOMA F2051
profile : DoJa-2.1
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 176
        height : 182
    canvas :
        width : 176
        height : 182
heap :
    full_appli :
        java : 600
        native : 700
default_font :
    width : 12
    height : 12

===
--- info
model   : FOMA N2701
profile : DoJa-2.1
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 176
        height : 198
    canvas :
        width : 176
        height : 198
heap :
    full_appli :
        java : 760
        native : 1228
default_font :
    width : 12
    height : 12

===
--- info
model   : FOMA F2102V
profile : DoJa-2.2
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 176
        height : 182
    canvas :
        width : 176
        height : 182
heap :
    full_appli :
        java : 1536
        native : 1024
default_font :
    width : 12
    height : 12

===
--- info
model   : FOMA N2102V
profile : DoJa-2.2
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 176
        height : 198
    canvas :
        width : 176
        height : 198
heap :
    full_appli :
        java : 760
        native : 1488
default_font :
    width : 12
    height : 12

===
--- info
model   : L600I
profile : DoJa-2.5OE
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 176
        height : 189
    canvas :
        width : 176
        height : 189
heap :
    full_appli :
        java : 1500
        native : 3072
default_font :
    width : 12
    height : 12

===
--- info
model   : NM706I
profile : DoJa-2.5OE
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 232
        height : 227
    canvas :
        width : 232
        height : 227
heap :
    full_appli :
        java : 2000
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : D505I
profile : DoJa-3.0
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 240
        height : 270
    canvas :
        width : 240
        height : 270
heap :
    full_appli :
        java : 1536
        native : 2048
default_font :
    width : 12
    height : 12

===
--- info
model   : P506IC
profile : DoJa-3.0
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 240
        height : 266
    canvas :
        width : 240
        height : 266
heap :
    full_appli :
        java : 3750
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : F900I
profile : DoJa-3.5
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 2048
        native : 3584
default_font :
    width : 12
    height : 12

===
--- info
model   : N900IG
profile : DoJa-3.5
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 3000
        native : 4700
default_font :
    width : 12
    height : 12

===
--- info
model   : L704I
profile : DoJa-3.5LE
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 4500
        native : 3500
default_font :
    width : 12
    height : 12

===
--- info
model   : L-03A
profile : DoJa-3.5LE
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 4500
        native : 3500
default_font :
    width : 12
    height : 12

===
--- info
model   : SH901IC
profile : DoJa-4.0
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 8000
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : P901ITV
profile : DoJa-4.0
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 8192
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : F700I
profile : DoJa-4.0LE
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 3000
        native : 5000
default_font :
    width : 12
    height : 12

===
--- info
model   : M702IG
profile : DoJa-4.0LE
size :
    jar : 100
    scratchpad : 200
display :
    panel :
        width : 240
        height : 267
    canvas :
        width : 240
        height : 267
heap :
    full_appli :
        java : 4000
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : F902I
profile : DoJa-4.1
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 4500
        native : 3500
default_font :
    width : 12
    height : 12

===
--- info
model   : N902IX
profile : DoJa-4.1
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 9216
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : P702I
profile : DoJa-4.1LE
size :
    jar : 30
    scratchpad : 200
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 8192
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : L-01A
profile : DoJa-4.1LE
size :
    jar : 100
    scratchpad : 400
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 4500
        native : 3500
default_font :
    width : 12
    height : 12

===
--- info
model   : SH903I
profile : DoJa-5.0
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 240
        height : 320
    canvas :
        width : 240
        height : 320
heap :
    full_appli :
        java : 12800
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : SH706IE
profile : DoJa-5.0
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 240
        height : 320
    canvas :
        width : 240
        height : 320
heap :
    full_appli :
        java : 9216
        native : 4096
default_font :
    width : 12
    height : 12

===
--- info
model   : N703ID
profile : DoJa-5.0LE
size :
    jar : 500
    scratchpad : 0
display :
    panel :
        width : 240
        height : 240
    canvas :
        width : 240
        height : 240
heap :
    full_appli :
        java : 8192
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : F-05A
profile : DoJa-5.0LE
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 240
        height : 432
    canvas :
        width : 240
        height : 432
heap :
    full_appli :
        java : 6144
        native : 6144
default_font :
    width : 12
    height : 12

===
--- info
model   : SH905I
profile : DoJa-5.1
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 480
        height : 854
    canvas :
        width : 480
        height : 854
heap :
    full_appli :
        java : 15360
        native : 10240
default_font :
    width : 12
    height : 12

===
--- info
model   : P-03B
profile : DoJa-5.1
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 240
        height : 426
    canvas :
        width : 240
        height : 426
heap :
    full_appli :
        java : 10240
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : P705I
profile : DoJa-5.1LE
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 240
        height : 426
    canvas :
        width : 240
        height : 426
heap :
    full_appli :
        java : 10240
        native : 0
default_font :
    width : 12
    height : 12

===
--- info
model   : L-02B
profile : DoJa-5.1LE
size :
    jar : 1024
    scratchpad : 0
display :
    panel :
        width : 480
        height : 800
    canvas :
        width : 480
        height : 800
heap :
    full_appli :
        java : 12288
        native : 3072
default_font :
    width : 12
    height : 12

