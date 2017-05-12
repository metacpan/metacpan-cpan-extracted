use strict;
use warnings;
use Test::Base;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
use WWW::MobileCarrierJP::Softbank::Flash;

plan tests => 1 + 2*blocks;

my $res;
if ($ENV{YAML}) {
    require YAML;
    $res = YAML::LoadFile($ENV{YAML});
} else {
    $res = WWW::MobileCarrierJP::Softbank::Flash->scrape();
}

cmp_ok scalar(@$res), '>', 100, 'thirdforce has many phones';

if ( $ENV{DEBUG_DUMP} ) {
    require Data::Dumper;
    Data::Dumper->import;
    warn Dumper($res);
}

filters { info => [qw/yaml/] };
run {
    my $block = shift;
    check($block->info);
};

sub check {
    my ($info, ) = @_;
    my ($model, ) = grep { $_->{model} eq $info->{model} } @$res;
    ok $model, "got a $info->{model} phone info";
    is_deeply $model => $info, "check the $info->{model}";
}

#   do {
#       my $disney_mobile = grep { $_->{model} eq 'DM001SH' } @$res;
#       ok $disney_mobile, "got a disney mobile phone's info";
#   #  is_deeply {felica => 1, 
#   #  - felica: 0
#   #  flashlite: 2.0
#   #  gps_agps: 0
#   #  gps_basic: 0
#   #  model: 820SC
#   #  pc_browser: 1
#   #  sappli: 1
#   };


__END__

===
--- info
flashlite: 3.1
model: 945SH
support_embedded_flv: 1
support_flash9: 1
support_progressive_flv: 1

===
--- info
flashlite: ~
model: 702MO
support_embedded_flv: 0
support_flash9: 0
support_progressive_flv: 0

===
--- info
flashlite: 3.0
model: DM006SH
support_embedded_flv: 1
support_flash9: 0
support_progressive_flv: 0

===
--- info
flashlite: 2.0
model: DM001SH
support_embedded_flv: 0
support_flash9: 0
support_progressive_flv: 0

