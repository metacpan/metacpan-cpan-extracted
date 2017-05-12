use strict;
use warnings;
use Test::Base;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
use WWW::MobileCarrierJP::Softbank::Java;

plan tests => 2 + 2 * blocks;

my $dat = WWW::MobileCarrierJP::Softbank::Java->scrape;
is ref($dat), 'ARRAY';
if ( $ENV{DEBUG_DUMP} ) {
    require Data::Dumper;
    Data::Dumper->import;
    warn Dumper($dat);
}
is join(',', sort(keys %{$dat->[0]})), 'cldc,felica_api,heap,limit,location_api,midp,model,profile,size';

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
model   : 740SC
profile : ''
heap    :
    base : 0
    ex   : 0
location_api : ''
midp : ''
cldc : ''
limit : ''
felica_api : ''
size :
    rs : 0
    jad : 0
    jar : 0

===
--- info
model   : 940SH
profile : MEXA
heap    :
    base : 8388608
    ex   : 16777216
location_api : 1
midp : 2.0
cldc : 1.1
limit : 4194304
felica_api : 2.0
size :
    rs : 3145728
    jad : 6144
    jar : 1048576

===
--- info
model   : 840SH
profile : MEXA
heap    :
    base : 4194304
    ex   : 0
location_api : ''
midp : 2.0
cldc : 1.1
limit : 4194304
felica_api : ''
size :
    rs : 3145728
    jad : 6144
    jar : 1048576

===
--- info
model   : 904T
profile : JSCL 1.2.2
heap    :
    base : 4194304
    ex   : 0
location_api : 1
midp : 2.0
cldc : 1.1
limit : 4194304
felica_api : 1.0
size :
    rs : 3145728
    jad : 6144
    jar : 1048576

===
--- info
model   : DM004SH
profile : MEXA
heap    :
    base : 4194304
    ex   : 0
location_api : ''
midp : 2.0
cldc : 1.1
limit : 4194304
felica_api : 2.0
size :
    rs : 3145728
    jad : 6144
    jar : 1048576


