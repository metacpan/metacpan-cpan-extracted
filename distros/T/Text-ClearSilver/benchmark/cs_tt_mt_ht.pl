#!perl
use strict;
use warnings;
use Config;
use Text::ClearSilver;
use Template;
use Text::MicroTemplate 'build_mt';
use HTML::Template::Pro;
use Benchmark ':all';

my $cs = Text::ClearSilver->new(VarEscapeMode => 'html');

my $n = shift(@ARGV) || 100;

my $tt_tmpl  = q{ [% foo  %] }            x $n;
my $mst_tmpl = q{ $= h:foo $ }            x $n;
my $cs_tmpl  = q{ <?cs var:foo ?> }       x $n;
my $mt_tmpl  = q{ <?=  $_[0]->{foo} ?> }  x $n;
my $ht_tmpl  = q{ <tmpl_var name="foo"> } x $n;

my $mt = build_mt($mt_tmpl);
my $ht = HTML::Template::Pro->new(
    scalarref => \$ht_tmpl,
);
my $tt = Template->new();

my $has_mst = eval { require MobaSiF::Template };

my %vars = (foo => 'bar');

printf "%vd on %s\n", $^V, $Config{archname};
foreach my $mod(qw(Template Text::MicroTemplate
    HTML::Template::Pro Text::ClearSilver),
    $has_mst ? 'MobaSiF::Template' : ()) {
    print $mod, ": ", $mod->VERSION, "\n";
}

my $mst_bin = 'mst.bin';
if($has_mst) {
    MobaSiF::Template::Compiler::compile(\$mst_tmpl, $mst_bin);
    eval q{ END{ unlink $mst_bin } };
}

if(0){
    warn _cs();
    warn _tt();
    warn _mt();
    warn _ht();
    warn _mst();
    exit;
}

cmpthese( -1, => {
        'CS'  => \&_cs,
        'TT'  => \&_tt,
        'MT'  => \&_mt,
        'HT'  => \&_ht,
        $has_mst ? ('MST' => \&_mst) : (),
    },
);

sub _cs {
    $cs->process(\$cs_tmpl, \%vars, \my $out );
    $out;
}
sub _tt {
    $tt->process(\$tt_tmpl, \%vars, \my $out) or die;
    $out;
}
sub _mt {
    $mt->(\%vars);
}
sub _ht {
    $ht->param(%vars);
    my $out = $ht->output();
}
sub _mst {
    MobaSiF::Template::insert($mst_bin, \%vars);
}
