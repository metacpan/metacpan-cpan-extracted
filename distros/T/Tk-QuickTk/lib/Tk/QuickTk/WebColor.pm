#            file:  Tk::QuickTk::WebColor  -- for pickhues
package Tk::QuickTk::WebColor;

use strict;
use vars qw(@ISA $VERSION @EXPORT_OK);

require Exporter;
@ISA=qw(Exporter);

$VERSION=0.5;
@EXPORT_OK=qw(app);

require 5.002;
# use English;
use Carp;
use FileHandle;
use File::Basename;
use Cwd;
use Tk;
use Tk::FileSelect;
use Text::TreeFile;
use Tk::QuickTk;

sub app {
  my ($gen,$gname)=@_;
  my $name=$ARGV[0]
    or carp "Tk::QuickTk::WebColor::app() found no filename on the command line\n";
  my $iname=$name;
  my $oname;
  if(defined $gen and $gen ne 'nogen') {
    $oname=(defined $gname)?$gname:$name.'.pl';
    print STDERR "Tk::QuickTk::WebColor::app() logging generated perl-tk code";
    print STDERR " to file: $oname\n";
  }
  my $app=(defined $oname)?Tk::QuickTk->new($iname,$oname)
                          :Tk::QuickTk->new($iname);
  hsblayers($app);
  MainLoop;croak "fell through MainLoop";
}

sub hsblayers { my ($gl)=@_;my $cf=51;$$gl{colorval}=[map $cf*$_,(0..5)];
  my ($x,$y,$z,$u,$v,$w,@c,@d,%ln,$ln,$lc);$$gl{color}=[];$$gl{cube}=\@c;
  my $size=6;my ($umax,$vmax,$wmax)=($size,$size,$size);
  my ($d2,$d3)=(sqrt(2)/2,sqrt(3)/3);
  for($w=0;$w<$wmax;++$w) { for($v=0;$v<$vmax;++$v) { for($u=0;$u<$umax;++$u) {
        $x=($w+$u)*$d2;$y=$v;$z=($w-$u)*$d2;
        $c[$u][$v][$w]=[($x        -$y*sqrt(2))*$d3,
                        ($x*sqrt(2)+$y        )*$d3,$z,
                        [$u,$v,$w]]; } } } $lc=0;
  for($v=0;$v<$vmax;++$v) { $d[$lc++]=$c[ 0][$v][ 0][1]; }
  for($w=1;$w<$wmax;++$w) { $d[$lc++]=$c[ 0][ 5][$w][1]; }
  for($u=1;$u<$umax;++$u) { $d[$lc++]=$c[$u][ 5][ 5][1]; }
  for($ln=0;$ln<$lc;++$ln) { $ln{$d[$ln]}=$ln;$$gl{color}[$ln]=[]; }
  for($w=0;$w<$wmax;++$w) { for($v=0;$v<$vmax;++$v) { for($u=0;$u<$umax;++$u) {
        push @{$$gl{color}[$ln{$c[$u][$v][$w][1]}]},$c[$u][$v][$w]; } } } }

sub Tk::QuickTk::c_layer { my ($gl,$ln)=@_;my $w=$$gl{widgets};
  $$w{mc}->delete('visobj') if($$gl{layermode} ne 'Multiple');
  $gl->layer($ln); }

sub Tk::QuickTk::layer { my ($gl,$ln)=@_;
  my $l=$$gl{color}[$ln];
  for my $c (@$l) { my ($r,$g,$b)=(51*$$c[3][0],51*$$c[3][1],51*$$c[3][2]);
    my $rgb=sprintf("#%02x%02x%02x",$r,$g,$b);
    my $i="[$$c[3][0],$$c[3][1],$$c[3][2]]";
    colorcircle($gl,$$c[0],$$c[2],$rgb,'mc',$ln,$i); } }

sub Tk::QuickTk::clabel { my ($gl)=@_;my $w=$$gl{widgets};my $l;
  if($$gl{labelmode} eq 'Nolabel') { for($l=0;$l<16;++$l) {
      my ($ctag,$ltag)=(sprintf("cl%02d",$l),sprintf("ll%02d",$l));
      $$w{mc}->lower($ltag,$ctag); } }
  else                             { for($l=0;$l<16;++$l) {
      my ($ctag,$ltag)=(sprintf("cl%02d",$l),sprintf("ll%02d",$l));
      $$w{mc}->raise($ltag,$ctag); } } }

sub colorcircle { my ($gl,$x,$y,$c,$w,$l,$i)=@_;my $wd=$$gl{widgets};
  my $xce=320;my $yce=240;my $xsc=50;my $ysc=50;my $xra=25;my $yra=25;
  my $xul=$xce+($x*$xsc+$xra);my $yul=$yce-($y*$ysc+$yra);
  my $xlr=$xce+($x*$xsc-$xra);my $ylr=$yce-($y*$ysc-$yra);
  my ($ctag,$ltag)=(sprintf("cl%02d",$l),sprintf("ll%02d",$l));
#   print "l: $l, i: $i, ctag: $ctag, ltag: $ltag\n";
  $$wd{$w}->createOval($xul,$yul,$xlr,$ylr,-fill=>$c,
    -tags=>['color','visobj',"h$c",$ctag,$i]);
  my ($xc,$yc)=($xce+$x*$xsc,$yce-$y*$ysc);
  $$wd{$w}->createText($xc,$yc,-text=>"$c",-fill=>($l<=7)?'white':'black',
    -tags=>['label','visobj',$ltag,$i]);
  $$wd{$w}->lower($ltag,$ctag) if($$gl{labelmode} eq 'Nolabel'); }

1;

__END__
