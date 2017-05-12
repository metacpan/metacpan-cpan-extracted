package Text::Glob::DWIW;

use v5.10; # /\d/a => /[0-9]/, _-prototype-trouble, no s///r, range-op-bug
use warnings; use strict;   use Exporter (); use Carp;
use List::Util qw'sum min max first reduce'; use Scalar::Util qw'blessed reftype';
use Hash::Util 'lock_keys'; use overload (); use re 'taint';
#no autovivification 'strict'; no indirect;  no bareword::filehandles; no multidimensional;
BEGIN{ eval{ require Data::Alias;'Data::Alias'->import('alias');1} or *alias=sub{@_} }

my $ns ='{textglob,tg,tglob}';
my $fun='{explode,expand{,_lazy},re,match,grep,glob,foreign,options}';
our @EXPORT_OK  =<${ns}{,_$fun}>;       # ^- rm: star-,starless-,domestic- expand
our %EXPORT_TAGS=('use'=>[],'all'=>\@EXPORT_OK,(map {$_=>[<${_}{,_$fun}>]} <"$ns">),
                                                map { $_=>[<${_}{$fun}>] } <$ns\_>);
our $VERSION="0.01";

sub textglob_expand; sub textglob_grep ($@);

# ----------------------------------------------------------------------------
# helper classes
{ package _19TGD_tiefun; sub TIEHASH { bless pop }; sub FETCH { goto &{+shift} } }
{ package Text::Glob::DWIW::IterBase;            use strict; use warnings; use Carp;
  use overload '0+' => 'size', 'int' => 'size', 'bool' => 'has_next',
               '@{}' => sub {[$_[0]->get]}, '${}' => sub { \scalar $_[0]->get },
               '&{}' => sub ($) { $_[0]->can('__iter__')//$_[0] }, '""' => 'get',
               #'""' => sub { scalar $_[0]->get },
               '<>' => 'next', '++' => 'next', '=' => '_iter_cp';
  sub get ($)  :method {$_[0]->next}; sub _iter_cp ($) :method {$_[0]}#post=pre
  sub last ($) :method {croak "peek not implemented"};#sub is_done ($) {!$_[0]->has_next}
  sub get_next ($) :method {$_[0]->next}; sub has_next ($) :method {defined $_[0]->last}
  sub __next__ ($) :method {$_[0]->next}; sub __more__ ($) :method {$_[0]->has_next}
} # needed: size, next, has_next(or last); optional: last, get, __iter__,_iter_cp,...
#~~ constants
my $pkg        =__PACKAGE__;                     my $keyH="$pkg/key";
my $nobackslash=qr{(?<!\\)(?:\\\\)*};
my $pure       =qr/^(?:[a-z]+|[A-Z]+|[0-9]+)\z/; # unmixed
my $fine       =qr/^[[:print:]\s\v\h\a]+\z/;     # no \b (backspace), but alarm
my $int        =qr/^[-+]?[0-9]+$/;
my $nat        =qr/0*[1-9][0-9]*/;               # N(>0), 0* because easy to describe.
my $natrange   =qr/$nat+(?:-$nat*)?|-$nat+/; my $natset=qr/$natrange(?:,$natrange)*/;
sub    _ch (;$) { my ($not)=@_; my $c=$not?"[^\Q$not\E]":'.'; qr/\\.|$c/s }
tie my %ch,'_19TGD_tiefun',\&_ch; my $ch=_ch; # fine enough, but look at 'Interpolation'
my %dcc=do { my $_d='0123456789'; my$_u=join'','A'..'Z'; my$_l=lc $_u; # preDefined
  sub __ccc ($$) { join '',map chr,$_[0]..$_[0]+$_[1]-1 }              # CharClasses
  (digit=>$_d,xdigit=>$_d.'abcdef',punct=>'[-!"#$%&\'()*+,./:;<=>?@[\\\]^_`{|}~]',
   upper=>$_u,lower=>$_l,alpha=>$_u.$_l, alnum=>$_u.$_l.$_d,alphanum=>$_u.$_l.$_d,
   lowernum=>$_l.$_d, uppernum=>$_u.$_d, word=>"$_u$_l${_d}_", space=>" \t\r\n\f\cK",
   blank=>"\t ",note=>__ccc(0x1d15d,8), zodiac=>__ccc(0x2648,12), die=>__ccc(0x2680,6),
   cardsym=>"\x{2660}\x{2665}\x{2666}\x{2663}\x{2664}\x{2661}\x{2662}\x{2667}",
   card=>(join'',map __ccc(0x1f0a1+16*$_,14),0..3)."\x{1f0cf}\x{1f0df}",
   mahjong=>__ccc(0x1f000,43), trigram=>__ccc(0x2630,8), hexagram=>__ccc(0x4dc0,64),
   polygon=>"\x{25B3}\x{25FB}\x{2B20}\x{2B21}",
   endmark=>".?!\x{203D}\x{2048}\x{2049}\x{203C}\x{2047}",#"\x{2e19}",
   legal=>"\x{00a9}\x{00ae}\x{2117}\x{2120}\x{2122}",#copy,reg,phonorec,sm,tm
   roman=>__ccc(0x2160,16).__ccc(0x2180,3).__ccc(0x2187,2), chess=>__ccc(0x2654,12),
   smiley=>__ccc(0x2639,3).__ccc(0x1f600,56), planet=>"\x{263c}".__ccc(0x263E,10)  ),
   luck=>"\x{1f320}\x{1f340}\x{1f3b0}\x{1f41e}"
   # ^- maybe: pig, dragon, not-found: horseshoe,chimney-sweeper
}; my $dcc=join'|',keys %dcc;  $dcc=qr/\[:(?:$dcc)(?:$natset|-)?:\]/;
my $charclass=qr/\[ (?:$dcc | $ch{']'})*+ \]/x;
tie my %esc,'_19TGD_tiefun',sub { qr{(?:\\(?=\\*[@_]))} }; my $esc=$esc{'0-9'};
sub _b2 ($$$)             ## ^- \ as explicit end if needed ((?:\\\\)* vs. \\* vs. no)
{ state @cache; my ($qua,$rep,$cc)=map {$_?1:0} @_; my $k=ord pack 'b3',$qua.$rep.$cc;
  return $cache[$k] if exists $cache[$k];
  $rep=$rep ? qr/\#\#[0-9]+$esc?/ : ''; $cc=$cc ? "$dcc|" : '';
  $qua=$qua ? qr/\#[0-9]+(?:$esc{'-0-9'}|-[0-9]+$esc?)?/ : '';
  $qua= $qua||$rep ? '(?:'.(join'|',$esc{'#'},grep$_,$rep,$qua).')?+' : '';
  $cache[$k]=qr{( (?:\[ (?:$cc $ch{']'})*+ \] | \{ (?: $ch{'{}'}++ | (?-1) )* \} ) $qua)}sx;
} # the outer capture needs latter a few tricks to work around, but less tricky as (??{})
  # with doesn't work inside subs, needs nasty tricks and/or explicitly violating DRY.

$Carp::Internal{$pkg}++ unless $ENV{DEBUG}//''=~/\bTGDWIW\b|\b\Q$pkg/;

#~~ low-level helper
sub _r     (&$) { $_[0]->(local $_=$_[1]);$_ } # missing s///r under 5.10
sub _map_r (&@) { my $f=shift; map { $f->(local $_=$_);$_ } @_ }
sub _reft  (_)  { my$t=$_[0]//$_; (!defined $t)||overload::Method($t,'""') ? '' :
                    ref($t)&&overload::Method($t,'&{}') ? 'CODE' : reftype($t)//'' }
sub _deref ($)  { my$t=_reft(my$a=$_[0]); $t eq'ARRAY'?@$a : $t=~/SCAL|REF/?$$a :$a}
#                 # ^- option hash can pass unchanged
sub _doref (@)  { @_==0 ? () : @_==1 ? \$_[0] : [@_] }
sub _nth (&$@)  { my ($f,$n)=splice@_,0,2; first { $f->($_)&&--$n<0 } @_ }
sub _addparens  { $_[0]=~/^$ch{'('}*[|] | [|]$ch{')'}*$ | \).*\(/xs ? "(?:$_[0])" : $_[0] }
sub __funwa(;$) { my ($name,$wa)=(caller 1+($_[0]//0))[3,5];$name=~s/^.*:://;($name,$wa)}
#~~ element count & guess
sub __mlen ($$) { my@l=map length,@_; my$r= $l[0] ne $l[1] ? max @l :
        length +("$_[0]$_[1]"=~/^(.*)(.*)(?=.{$l[0]}$)(?:\1).*$/s)[1];--$r if $r>0&&$r<4; }
# ^- mattered length, ignore same start, => 26**_mlen(...) = a roughly guess for range size
#~~ errors
sub _2wide ($$) { my($mx,$v)=@_;croak"Step size too wide (>$mx)." if$mx&&$mx>0&&$v&& $mx<$v}
sub _2much($$;$){ my($br,$v,$d)=@_;croak "Too much (>$br)." if$br&& $br<abs $v/max 1,$d//1 }
sub _2void ()   { my($n,$wa)=__funwa 1; $wa//croak "Useless call of '$n' in void context." }
sub _2opt (;$)  { croak join ': ','Error in option setting',grep $_,@_ }
#~ option handling
sub _hinthash() { my($l,$f,$hh)=0; do{($f,$hh)=(caller++$l)[3,10]} while $f=~/^_|::_/; $hh }
sub _uuid ()    { int rand max ~0,2**32 };
sub _hval ($$)  {exists$_[0]->{$_[1]}&&$_[0]->{$_[1]}} # (+$) not under 5.10
sub _opt_get { @_ ? (_reft($_[0])eq'HASH' ?shift : _reft($_[$#_])eq'HASH' ?pop : ()) : () }
sub _opt_def { +{qw'anchored 1  capture 0  tree 0  chunk 0   range 1  star 1  invert 0
                    anchors  0  pattern 0  case 1  minus 1   break 0  twin 1  quant  1
                   backslash 0 stepsize 0  last 1 greedy 0            mell 0 default 0',
                 (map {$_=>''} qw'unhead unchar charclass'), rewrite=>undef, tilde=>undef} }
             # not planned: braces 1  parens/parentheses 0  sort 0  brackets 1?
sub _opt_chk ($;$$)
{ my ($opt,$adef,$fillup)=@_; $adef||=_opt_def; $fillup//=1;
  eval { lock_keys %$opt, keys %$adef; %$opt=(%$adef,%$opt) if $fillup; $opt } or do
     { croak "Unknown option '$1'." if $@=~/^Hash\s*has\s*key\s*'(.*?)'/; _2opt $@ }
}
our (%_prv,%_opt); # inside-out, lexical
sub _opt_lex (;$)
{ my $hh=$_[0]||_hinthash; my $hv=_hval $hh,$keyH;                         my @ohist;
  for (my$i=$hv; $i; $i=_hval\%_prv,$i) { unshift @ohist,$_opt{$i} if _hval \%_opt,$i }
  my $lexcfg={ map %$_,_opt_def,@ohist };
  wantarray ? %$lexcfg : $lexcfg; # X: silent fallback to _opt_def if lex-scope...
}
sub textglob_options
{ my $new=@_<2?shift:{@_}; my $hh=_hinthash; my $hv; _2void unless $new;
  croak "Options must be given as hash(ref)." if $new && _reft($new) ne 'HASH';
  _2opt 'Scope of use declaration not found.' unless $hv=_hval $hh,$keyH;
  my $lexcfg=_opt_lex $hh if defined wantarray;
  $_opt{$hv}={$_opt{$hv}?%{$_opt{$hv}}:(),%$new} if $new; # ensure copy of $new
  wantarray ? %$lexcfg : $lexcfg;
}
sub _opt     # use: my %o=&_opt; => shift/pop;  _opt @_ => don't shift/pop
{ my $opt=&_opt_get//{};
  if (keys %$opt==keys %{+_opt_def}  || $opt->{default}) { _opt_chk $opt }
  else                                         { _opt_chk($opt,_opt_lex) }
  for ($opt->{greedy})   { $_||=0; $_=1 if /[^0-9]/; $_=2 if $_>2 } # only 0,1,2
  for ($opt->{stepsize}) { $_=0 if $_ && /[^-+0-9]/ }
  for (qw'range{[ anchored^$az anchors^$az twin***** star******?','quant#,##')
     { my($k,$v)=split/\b/,$_,2; $_= $_&&!/[\Q$v\E]|^[0,\s]*$/ ? $v : $_//'' for$opt->{$k} }
  for (@$opt{qw'unchar unhead backslash'})
     { $_//=''; $_=join'',textglob_expand $_,{default=>1} if /.../&&/^$charclass$/ }
  wantarray ? %$opt : $opt;
}
sub _opt_fmt     # use: my %o=&_opt; => shift/pop;  _opt @_ => don't shift/pop
   { my $opt=&_opt_get//{}; _opt_chk $opt,{qw'paired 0'}; wantarray ? %$opt : $opt }

#~~ import-export                           # v- every 'use' hold a option hash forever
{ sub import   { $INC{'TGDWIW.pm'}=__FILE__ if first {/^:use$/} @_; # use-abbr
                 splice @_,0,1,$pkg if $_[0] eq 'TGDWIW';   my $opt=&_opt_get;
                 my $p=$^H{$keyH}; $^H{$keyH}=my$dk=_uuid;   $_prv{$dk}=$p if $p;
                 $_opt{$dk}=_opt_chk $opt,0,0 if $opt; goto &Exporter::import }
  sub unimport { undef $^H{$keyH} }           # at compile-time: so we can't free any data;
  *TGDWIW::import=\&import; *TGDWIW::unimport=\&unimport; #\ also not called often anyway
}                                                # i: refaddr \%^H is same for same scope
#~~ inner of range
sub _succ ($;$) # wrapping magic++ => # 1a..12g, 1a1..2b2 works (test: {9y-10b})
{ my($val,$to)=@_; $^R=[]; my $carry=1; #use re 'eval';
  return ++$val if $val!~/^(?:([a-z]+[0-9]*|[0-9]+)(?{ [@{$^R},$^N] }))*$/xis; #<< fallback
  my $r=join '',reverse               # ^- no ...|| @{$^R}<=1 optimization,because of carry
    map { my $p=$_;++$p if $carry; $carry=substr $p,0,my$d=length($p)-length; substr$p,$d }
    reverse @{$^R};                                 return "$carry$r" unless $to && $carry;
    no warnings 'substr';    my $t=substr $to,-1-length$r,1; $carry=__toA($t,$carry) if $t;
    "$carry$r"
}
sub __le   ($$) { (length($_[0])<=>length($_[1])||$_[0]cmp$_[1])<=0 }
sub __toA       { (local$_,my$q)=@_;"$_$q"=~/$pure/?$q:/[0-9]/?1:/[a-z]/?'a':/[A-Z]/?'A':$q}
sub __toZ  ($$) { (local$_,my$q)=@_;"$_$q"=~/$pure/?$q:/[0-9]/?9:/[a-z]/?'z':/[A-Z]/?'Z':$q}
sub _prep  ($$) { my($f,$t)=@_;for my $p (1..length$f)   #\ a-9 aa-b9 0-a => a-z aa-bz 0-9
                                 { $_=__toZ substr($f,-$p,1),$_ for substr$t,-$p,1 }; $t }
sub __formnumber{ $_[0]=~/^[+-]?(0\d*)/ ? '%0'.length($1).'s' : '%s' }
sub __formpat ($) # so ranges can have punctation in it...
{ my ($inp)=@_; my @def=($inp,sub{$_[0]});                    my $pu='[[:punct:]]';
  return @def if $inp=~/\\/ || $inp=~/^.$/s; # don't know how to handle '\' reliable
  my $beg= $inp=~s/^($pu++)//sg ? $1 : '';   # $3-$5000, (0)-(1000) ...
  (my $val=$inp)=~s/$pu++//sg;                            my $pat=$inp; my $wrap=0;
  $pat=~s{([^[:punct:]]++)$pu*}{++$wrap; my$l=length $1; my$l2=$l<3?'':'{1,'.($l-1).'}';
                  !pos $pat ? '(.+))?' : "(.{$l})|(^.$l2))?" }seg;
  $pat=('(?:' x $wrap).$pat;                      my $re=qr/^(?:\Q$beg\E)?$pat\z/s;
  (my $frm=$inp)=~s/(%|[^[:punct:]]++)/$1 eq'%' ? '%%' : '%s'/seg; $beg=~s/%/%%/sg;
  return $val eq $def[0] || $val eq '' ? @def :
    ($val,sub{ my$c=my@parts=grep defined$_, $_[0]=~/$re/;   # 1_1_1-1
               (my $f=$frm)=~s/.*( (?:$pu*? (?<!%)(?:%%)*?%s $pu*?){$c} )$/$1/xsg if $c;
               $c ? sprintf $beg.$f,@parts : undef })
}
sub _updwn ($$$$;$)
{ my ($br,$ssz, $f,$t,$step)=@_; $step||=1; my @r; return $f if $f eq $t;
  if ("$f$t"=~/^([[:punct:]])\1*\z/)
  { if (($f=length$f)<=($t=length$t)) # *****-*
         {while ($f<=$t) { push @r,$1 x$f; $f+=$step; _2much$br,@r } }
    else {while ($t<=$f) { push @r,$1 x$f; $f-=$step; _2much$br,@r } }
  }
  elsif ($f=~/$int/ && $t=~/$int/)
  { my $x=__formnumber abs($f)<abs($t)?$f:$t; # 01..10 vs. 1..10
    if ($f<=$t)
         {while ($f<=$t) { push @r,sprintf$x,$f;$f+=$step; _2much$br,@r } }
    else {while ($t<=$f) { push @r,sprintf$x,$f;$f-=$step; _2much$br,@r } }
  } else
  { my ($f1,$pf)=__formpat($f); my ($t1,$pt)=__formpat($t);
    return $step>1 ? $f : ($f,$t) if ($f1 eq $t1 && $f ne $t); # 1#1,1'1
    my $mod=0; my $last; my $fnext;
    my ($f2,$t2,$do)=(__le $f1,$t1)
       ?($f1,$t1, sub{ push    @r,$fnext->($_[0],$pf,$pt) if !($mod%=$step)++ })
       :($t1,$f1, sub{ unshift @r,$fnext->($_[0],$pt,$pf) if !($mod%=$step)++ });
    my $chlen=length($f2) - (length($f2)==length$t2);
    $fnext=sub{ my($v,$f,$g)=@_; _2much$br,@r,$ssz; # only here, doesn't matter 4 int
                $last=(defined$last && length($v)>$chlen ? $g->($v):()) // $f->($v) };
    my $nm=$f2=~/$int/; my $t3=_prep $f2, $t2; $t3=$t2 if $t3 eq $f2; # aa-z9
    while (__le$f2,$t3)                          # v- ..,undef$last,.. vs. ..,--$mod,..
      {$do->($f2);$f2=_succ($f2,$t3); $do->($t2),undef$last,last if !$nm&&$f2=~/$int/; }
    #$do->($t2) if defined$last&& !__le($t2,$last)&&!__le($f2,$t2) && ($t2 eq $t3 ||@r<2);
    # o perl has an optimization for for:  ____ for $a..$b;    \^- XXX better not: $1..$10
    #   unlucky this has a bug (at least 5.10.1, 5.16=fixed),
    #   so that:  ____ for $tainted..$whatever;  runs infinitely (with $_=0 always).
    # o btw.: ..-op: igitt1 c..a => c..z # ..-op: igitt2  aa..az vs. aa..a0 => aa..zz
    #   also: a0..z9 (...) vs. 0a..9z (0a only)
    # o Does further differences, beside atoi-behavior between .. and magic++ exists?
  }; @r
}
sub _frmto ($$$$)  # extend the magic of ..-op
{ my ($o,$f1,$t1,$step)=@_; my ($f,$t)=_map_r {s/^\\([\\![\]-])/$1/} $f1,$t1;
  my @r; my ($br,$ssz)=@$o{'break','stepsize'}; _2wide $ssz,$step;
  $ssz=min $step//1,abs($ssz||$step//1);
  if ($f=~/^.\z/s&&$t=~/^.\z/s&&"$f$t"!~/$pure/) #XXX
  { _2much $br,(my $fo=ord$f)-(my $to=ord$t),$ssz;
    @r=map chr,_updwn($br,$ssz, $fo,$to,$step);  @r=grep/$fine/,@r if "$f$t"=~/$fine/;
  } else
  { _2much $br,("$f$t"!~/[^0-9]/ ? $f-$t : 26**__mlen $f,$t),$ssz if $o->{break};
    @r=_updwn $br,$ssz, $f,$t,$step; # a-aa a-ba vs. a-zz -^- -1 by smaller numbers
  }; @r    # XXX $r[0]=$f1 if $r[0] eq $f;
}
sub _range ($$@)          # $o..options, $b ... protect '{[', inside {}?
{ my ($o,$b)=splice@_,0,2;   my $mc=$o->{minus} ? '[!]?' : '';
  my $step_re=defined $o->{stepsize} ? "(?:-($nat))?" : '';
  map { my@r; !(@r=/^($mc)(-? $ch{"\\$b-"}+) - ($ch{"\\$b"}+?) $step_re $/x) ? $_ :
              do{ s{(?|\\([\\-])|($ch))}{$1}g for @r[1,2]; #X $ch{'\\'} vs. $ch?
                  map $r[0]._qu($o,$_), _frmto $o,$r[1],$r[2],$r[3] }     } @_
}
#~~ \-escape handling
sub _qm    ($)  { (my$r=$_[0])=~s{\G((?:\\[^\w\d\n])++|[\n]++)|((?:\\[\w\d])++|[^\\]+|.$)}
                                 {defined $1 ? $1 : quotemeta $2}gse;$r }
sub _dequ ($@)  { my $o=shift; my $star=join '',map { $o&&$o->{star}=~/([$_])/ } qw'* ?';
                  my ($xa)=map {('^'x/[a\^]/).('^'x/[z\$]/)} $o->{rewrite}?'':$o->{anchors};
                  my $s=$star.($o->{minus}?'!':'').($o->{rewrite}?'':',{}').$xa;
                  my $dequ=qr/(?<=^\\)[!]|[[\]$s-]/; # $o{star} (\\?)
                  _map_r { s{$nobackslash\K\\($dequ)}{$1}gs;
                           s/\\\\/\\/gs if $o->{last} } @_ }# \# &c. = done elsewhere
sub _qu ($$)    { my $o=shift; my $star=join '',map { $o&&$o->{star}=~/([$_])/ } qw'* ?';
                  my $s=$star.($o&&$o->{minus}?'!':'');
                  $s ? _r{s<([$s])><\\$1>g}$_[0] : $_[0] }#only 4 _range, so don't check \\
                  # XXX because generating new stuff, also diff {} vs. []? in- vs. outbound
#~~ capture the flag
sub _anchors($) { map { /a/?'^':/z/?'\\z':$_ } map $_//'',$_[0]=~/(?:([a^])|([z\$])|.)*/; }
#~~ RE massages
sub _dotty ($)  { (my$u=shift)=~s/(?=[-^[\]\\])/\\/g; ($u ne''?("[$u]","[^$u]"):('','.')) }
sub _retqr($$)  { my($o,$re)=@_; my($a,$z)=_anchors $o->{anchored};
                  my$i=(my$c=$o->{case})?'':'i';my$b=$o->{capture}? $i?"|(?$i)":'|' : "$i:";
                  for ($re)                                                # v- revert case
                  { s{$nobackslash\K([[:lower:]]*+)([[:upper:]]*+)}{\U$1\L$2}gs    if$c<0;
                    # v- until here, no [..] used (with \w inside), so this should be fine
                    s/$nobackslash\K([[:lower:]])/[$1\U$1\E]/gs          if ($c=abs $c)==2;
                    s/$nobackslash\K([[:upper:]])/[$1\L$1\E]/gs                   if $c==3;
                    s/$nobackslash\K([[:lower:]])/(?:$1|\\b\U$1\E)/gs             if $c==4;
                    s{$nobackslash\K([[:upper:]])}{(?:$1|\\b\L$1\E|[_-]\L$1\E)}gs if $c==5;
                    # v-  cleanup for easier testing/inspecting
                    1 while s{ \(\?\:  ( \( (?: $ch{'()'}++|(?-1) )* \) ) \) }{$1}xg;
                    1 while s/\(\?\:($ch{'\\|()'}*+|\($ch{'\\()'}*+\))\)/$1/sg;
                    1 while s{^(\(\?\:(?:((?:$ch{'()'}++|(?1))*))\))$}{$+}s;
                  }
                  qr{$a(?$b$re)$z}s }   # free for further extending: ...?qr... : qr....
#~~ _sort used for subtraction pattern
sub __idx ($$)  { my $p=index $_[0],$_[1]; $p<0?'+Inf':$p }
sub _sort       { sort { __idx($b,'*')<=>__idx($a,'*')||__idx($b,'?')<=>__idx($a,'?')||
                         length($b)<=>length $a } @_ }
                # ^- one real condition: the pattern should find itself at last.
#~ forester
sub _flatten (@) { map { _reft($_) ? &_flatten(_deref $_) : $_ } @_ }
sub _markflt (@) { join'',map { _reft($_) ? '('.&_markflt(_deref$_).')' : $_ } @_ }#4capture
sub _treejoin($) { join'',&_flatten } # fixed ''
sub _forestjoin  { map { join'',_flatten $_ } @_ }
sub _treemap(&@) { my$f=shift; map{ _reft($_)?_doref &_treemap($f,_deref $_):$f->($_) } @_}
sub _forestmap(&@) {my$f=shift; map [&_treemap($f,@$_)], @_ }
sub _treefor1(&@){ my $f=shift; for (@_) { my$t=_reft $_; !$t ? $f->($_) :
                   &_treefor1($f,'ARRAY'eq$t?@$_:$t=~/SCAL|REF/?$$_:$_) } }
# ^- was: ...&_treefor1($f,_deref $_).. with _deref :lvalue but this bail out under 5.10
#         with "Bizarre copy of ARRAY in sassign at line 25 or in overload::Method ...."
sub _treefirst(&@) { my $f=shift; my $t=_reft $_[0]; !$t ? do{$f->($_[0])for$_[0]} :
                     &_treefirst($f, 'ARRAY'eq$t ? $_[0][0] : ${$_[0]}) }
sub _drop_anchor ($;$$) # rm outside anchors
{ my ($v,$xaa,$xae)=@_; return unless $xaa||$xae; my($A,$a,$e,$pos)=(0,0,0,0);
  while ($pos<@$v)
  { if (_reft $v->[$pos]) { ($a,$e)=&_drop_anchor($v->[$pos],$xaa,$xae); $A||=$a }
    else { $A||=$a=$xaa&&substr($v->[$pos],0,1)eq'^'; $e=$xae&&substr($v->[$pos],-1)eq'$' }
    if ($a&&$pos>1)    { splice @$v,0,$pos-1; $pos=0 }
    if ($e&&$pos<$#$v) { splice @$v,$pos+1; last }
    ++$pos # anchors self are latter removed because ref and therfore aliased
  }
  return ($A,$e)
}
#~~ globbing
sub __rhomb1($) { ($_[0]//'')=~/^(?|(\d*)-(\d*)|((\d+)))$/ }
sub __rhomb2($) { (($_[0]//'')=~/^\#(\d+)$/)[0]//1 } # <+^- get quantifier for # & ##
sub _clearret   { map { _reft($_)ne'REF'||_reft($$_)ne'ARRAY' ? $_ : # clear tree result
                        @$$_!=1 ? [&_clearret(@$$_)] : \($$_->[0]) } @_ }
# v- _minus: handle subtraction pattern {...,!...}     # vv- _multi: ##f
#sub _minus ($@) { my $o=shift;@{+reduce { _treejoin($b)!~/^!(.*)/ ? [@$a,$b] :
#                 [textglob_grep({%$o,minus=>0,invert=>1,pattern=>1},my$e=$1,@$a)] }[],@_} }
sub _minus ($@) { my $o=shift; my @r; $o={%$o,minus=>0,invert=>1,pattern=>1};
                  for(@_) { if (_treejoin($_)!~/^!(.*)/) { push @r,$_ }
                            else { @r=textglob_grep($o,$1,@r) } } @r } # was: my$e=$1
sub _multi ($@) { my $f=shift//1; return @_ if $f==1; map [ (_deref$_)x $f ],@_ }
sub _cc ($@) # predefined charclasses and subsets
{ my$o=shift;
  map{ not(/^$dcc$/&&/([a-z]+)([\d,-]*)/) ? $_ :
       do { my $cnt=my @r=split'',$dcc{$1}; my @set=$2 ? split /,/,$2 : $2;
            map { my($f,$t)=__rhomb1 $_;
                 (defined $f ? $t : $f)=1 if !$f && !$t; $_=min($cnt,$_||$cnt) for $f,$t;
                  map _qu($o,$_),@r[$f<=$t? $f-1..$t-1 : reverse $t-1..$f-1] } @set;
                } } @_
}
sub _textglob
{ my $o=&_opt; my ($rf,$rewrtf,$br,$ccf)=@$o{qw'range rewrite break charclass'};
  my ($quaf,$repf)=map { -/(?<!#)#(?!#)|###/,-/##/ } $o->{quant};
  my ($xaaf,$xaef)=map { -/[a^]/, -/[z\$]/ } $o->{anchors}; my $xaf=$xaaf||$xaef;
  my $b2=_b2($quaf,$repf,$ccf!~/def(?:ined)?=?[-0]/i);
  my $bracket_re=$o->{mell} ? qr/(?| ,?($ch{',\\-'}++ - $ch{','}++),? |($dcc|$ch)|^()$)/xs
                : $rf=~/\[/ ? qr/(?:\\ [\\\]!] | $ch{'\\'})-$ch|$dcc|$ch/xs : qr/$ch/s;
  my $braces_re =qr/(, (?: $b2 | $ch{',[{'}+ )* ) (?=,|$)/xs; # ',' used for detecting
  my $range=sub ($) { $rf=~/\Q$_[0]/ ? sub{&_range($o,@_)} : sub{shift;@_} };
  my $sort=$ccf=~/sort=?+[->]/i          ? sub { sort { $b cmp $a } @_ } :
           $ccf=~/sort=?+(?:[^->0!]|$)/i ? sub { sort +@_ }  :  sub {@_};
  my $__textglob; $__textglob=sub #_1  # heart
  { my $rewrtf=shift; my $o={%$o,rewrite=>$rewrtf};                      my @r;
    for (@_)
    { my @glob=map  /(?| $b2 | ($ch{'{['}++ | $ch | ^$ ))/sxg, $_//();
      my @a=[];                 # ^- $ch | ^$  so long, nothing else fits => [[]
      for my $b (reverse @glob) # reverse: for more natural order start from backward
      { my ($body,$typ,$inner,$repeat)=
                     $b=~/^(([{\[]) ($ch*) [}\]]) (?:\#(\#\d+|\d*-?\d+))? \\?$/xs;
        my ($qs,$qe)=__rhomb1($repeat//1); my $multi=__rhomb2($repeat); $typ//='';
        my @inner='{'eq$typ ? $range->($typ)->('{[',                              #{}
                         map{$_&&/^,/?substr$_,1:()} (",$inner"=~/$braces_re/g)) #v-[]
                      : $sort->($range->($typ)->('',_cc$o,$inner=~/$bracket_re/g)) if $typ;
        if ($rewrtf && !$typ) { $b=~s/$nobackslash\K([{}])/\\$1/gs }
        if ($quaf && defined $repeat)
        { ($typ,$b)=('','') if $qe//=1,(($qs//=1)||=0)==0 && $qe==0;
          unless ($qs==$qe && $qe<=1) # #1 is normal mode, wo interception
          { _2much$br,max($qs,$qe);        my @q= $qe>=$qs ? $qs..$qe : reverse $qe..$qs;
            _2much$br,($rewrtf?(sum map @inner*$_,@q):(sum map @inner**$_,@q))*(@a||1);
            $typ='{';@inner=map {$body x $_} @q;
          }
        }
        @inner=$__textglob->($rewrtf,@inner) if $typ;#XXX _2much$br,@inner**2 if$o->{pat..};
        my $min=$o->{minus};
        @inner=_forestjoin $__textglob->(0,_forestjoin @inner)       # v- XXX
           if $rewrtf&&($rewrtf<0||$multi>1||($min&&=first {_treejoin($_)=~/^\!/} @inner));
        @inner=_minus $o,@inner if $min; _2much $br,$multi*@inner*(@a||1) if $typ;
        @inner=_multi $multi,@inner;
        if ($typ)
        { if ($rewrtf)
          { $typ='';   # v- ','-escaping is a little tricky
            $b=join',', map{ join'',map { /$b2/ ? $_ : _r { s/$nobackslash\K,/\\,/g }  $_ }
                                    _deref$_ } @inner;              $b="{$b}" #if @inner>1;
          }
          elsif (@inner<=1) { $typ=''; $b=$inner[0]//'' } # @inner==0: no cross product with
        }                                                 #            with empty set
        unless ($typ) { unshift @$_,$b for @a; next };
        @a=map { my $bv=$_; map alias([$bv,@$_]),@a} @inner; # cross product XXX: optimize
        #0+my $ic=@inner; my $pos;
        #0+while ($ic) { my $bv=$inner[$pos=@inner-$ic--];
        #0+              splice @inner,$pos,1,map [$bv,@$_],@a; }
        #0+@a=splice @inner;
        #1+my $m=@a; push @a,map {map [@$_],@a } 1..$#inner;
        #1+my $i=0; unshift @$_,$inner[$i++/$m] for @a;
        #2+my $m=@a; @a=map {map [@$_],@a } @inner;#@a=map { my $ax=$_; map[@$_],@a} @inner;
        #2+my $i=0; unshift @$_,$inner[$i++/$m] for @a;
      };alias(push @r,splice @a); # XXX
    };  alias(return @r)
  };
#  sub _textglob
  map { _drop_anchor $_,$xaaf,$xaef;
        [ _clearret $xaf ? _treemap {_r {s/^[\^]// if$xaaf;s/[\$]$// if$xaef}$_} @$_ : @$_]
      } $__textglob->($rewrtf,map { _deref $_ } @_)
}

sub _star ($@) { state $s={'***'=>qr'\*\*\*','**'=>qr'/(?<!\*)\*\*(?!\*)|\*{5}/',
                           '*'=>qr'(?<!\*)(?:\*|\*{4})(?!\*)|\*{6}','?'=>qr'\?'};
                 my $test=$s->{+shift}; reduce { $a && ($b//''=~$test) } 1,@_ }
sub _g2re_cb ($$$$) # subglob2re with callbacks: $f2 when [*?], $f1 else; $g=subglob
{ my ($o,$f1,$f2,$g)=@_;    ($_//=sub(){undef})==1 and $_=sub($){$_[0]} for($f1,$f2);
  my ($uncho,$unheado,$twino,$staro,$rewriteo)=@$o{qw'unchar unhead twin star rewrite'};
  my ($xaa,$xae)=_anchors $o->{anchors};
  my @notwin=map { _star($_,$twino) ? () : $_ } qw'** ***';
  my %g2re=(qw'*** .*?    ** .*?   * .*?    ? .',
            qw'{   (?:    } )      ^ \\^    $ \\$', ','=>'|', ''=>'');
     %g2re=(%g2re,map { _star($_,$staro) ? () : ($_=>quotemeta $_) } qw'? * ** ***');
  my ($uc1,$dot1)=_dotty $uncho; my $greed=('?','','+')[$o->{greedy}];   my $uc=$uc1;
  my $dot =$unheado eq '' ? $dot1 : sprintf "(?(?<!$dot1)(?!%1\$s))$dot1",_dotty $unheado;
  my$bs=$o->{backslash}||'';$bs&&=$bs eq '1' ?'.':"[\Q$bs\E]";
  if ($bs) { $dot ="(?>\\\\$bs|$dot)";   my $also=$bs eq'.'||$bs eq$uc1 ?'':"(?=$bs)";
             $dot1="(?<=\\\\)$also$uc1|$dot1" if $uncho=~/$bs/;
             $uc  ="(?<!\\\\$also)$uc1" if $uncho=~/$bs/; } # X: $uc ?? needed?
  s/\./$dot/ for @g2re{'*','?',@notwin}; s/\?$/$greed/ for @g2re{'*','**','***'};
  my $middot=!$bs&&$unheado eq '' ? '.' : "(?:$uc1|$dot)"; # inside **
  my $twin=$uc1?"(?:(?<!$dot1)|(?!$dot1)|$uc|$uc1??(?<!$dot1)$middot*$greed(?!$dot1)$uc1??)"
               :$g2re{'*'};
  $g2re{'**'} =$twin if _star('**', $staro,$twino)&&$twino!~/\*\*\+/;
  $g2re{'***'}=$twin if _star('***',$staro,$twino)&&$twino=~/\*\*\*-/;
  $g2re{'{'}  ='('   if $o->{capture};
  $g2re{'^'}='^' if $xaa;          $g2re{'$'}="$xae(*ACCEPT)" if $xae;
  my $twinchk=$twino ne '*' ? '\\*\\*\\*?|' : ''; # '*'=off per multiple replacement
  # ^- ?? ?* *? have meanings=>no analogy to ** possible
  my $dove=qr{$ch{'^$\\?*'}*+}s; my $raven=qr{$ch{'^$\\?*\{\},'}*+}s; my $cnvd=0;
  return $f1->($g) if $rewriteo ? $g!~/^$raven[*?{]/ : $g!~/^$dove[*?]/;
  my $bal=$rewriteo ? qr/( \{ (?: $ch{',{}'}++ ,?+ | (?1) ,?+ | , )* \} )/xs : '((?!))';
  (my $re=$g)=~s{\G$bal|\G($ch{'\{'}*|.*?)}{ defined $1 # \G?
    ? _r { $cnvd+=s{($raven|\\$)($twinchk[\^\${},?*]|$)}{_qm($1).$g2re{$2}}seg  } $1
    : _r { $cnvd+=s{($dove |\\$)($twinchk[\^\$?*]   |$)}{_qm($1).$g2re{$2}}gsex } $2
  }seg;
  return $cnvd ? $f2->($re) : $f1->($g)  # cond: $re as string instead of qr.
}
#~ Obj, actually only for textglob_expand     # v- half baked ...
{ #sub _ourstuff($){ blessed($_[0]) && $_[0]->isa($pkg.'::Result') } # does...
  package Text::Glob::DWIW::Result;       use strict; use warnings; use re 'taint';
  use parent -norequire => 'Text::Glob::DWIW::IterBase';         no overloading;
  use overload '@{}' => sub { [$_[0]->_list] },  'qr' => 'as_re';
               # + - .. set like op.: {{},{}} {{},!{}} but ...; ~~ ...; '""' => ???
  sub _r (&$); sub _opt_fmt;
  { no strict 'refs'; for(%{"$pkg\::"}) {*{$_}=\&{"$pkg\::$_"}if/^_[a-z][a-z_]+$/} }
  sub _nthref (\@@) { my($a,$n)=splice@_,0,2; return if _reft($a)ne'ARRAY' && $n; # XXX
                      my$r=$n ? &_nth(\&_reft,$n-1,@$a) :$a;  @_ ?&_nthref($r//[],@_) :$r }
  #sub _new_glob   :method { my ($prot,$o,$c)=splice@_,0,3;
  #                          bless {o=>$o,c=>$c,i=>\@_},ref($prot)||$prot }
  sub _new_expand :method { my ($prot,$o)=splice@_,0,2;
                            bless {o=>$o,c=>sub{},d=>\@_,ainc=>1},ref($prot)||$prot }
  sub chunks ($)  :method { map [_flatten($_)], $_[0]->tree }
  sub tree   ($;$):method { @{$_[1] ? $_[0]{i}//$_[0]{d} : ($_[0]{d}//=$_[0]{c}->())} }#XXX
  sub size   ($;$):method { scalar $_[0]->tree($_[1]) }
  sub _list  ($;$):method { _forestjoin($_[0]->tree($_[1])) }
  sub as_re  ($)  :method { &_textglob_re($_[0]{o},$_[0]->elems(1)) }
  sub elems  ($;$):method { wantarray ? $_[0]->_list($_[1]) : $_[0]->size($_[1]) }
  sub expand ($)  :method { $_[0]->elems };  sub explode($) :method { $_[0]->elems }
  sub elem   ($$) :method { my $i=pop; my $d=$_[0]{d};
                            exists$d->[$i]?_treejoin($d->[$i]):undef }
  sub next   ($)  :method { $_[0]->elem( (($_[0]{p}//=0)%=$_[0]->size+1)++ ) } # iter
  sub has_next($) :method { ($_[0]{p}//=0)<$_[0]->size } # XXX
  #sub captures($):method { $_[0]{c}//=... )]}#XXX
  #sub _capture   :method { my $c=shift->captures; $c=(_reft($c)?$c:[])->[$_] for @_; $c }
  sub _capture    :method { my ($o,$l,@p)=@_; _nthref(@{($o->tree)[$l]//[]},@p) }
  sub capture($$@):method { my $v=shift->_capture(@_);$v?_treejoin($v):$v }
  sub format ($$@) :method
  { my $we=shift; my $o=&_opt_fmt;    my $re=qr/% ( % | [0-9]+ (?:\.[0-9]+)* )/x;
    map { my $f=$_;
      map { (my$r=$f)=~s{$re}{ my@r=split/\./,$1;$1 eq'%' ?$1 :$we->capture($_,@r)//'' }ge;
            $o->{paired} ? ($we->elem($_),$r) : $r } 0..$we->size-1 } @_;
  }
  sub grep ($@)  :method { my $re=shift->as_re; CORE::grep /$re/, @_ }
  #sub glob ($@) :method {...}
  sub opts ($;%) :method {my$we=shift;my$o=$$we{o};$$we{o}={%$o,@_}if@_; wantarray?%$o:$o }
}
sub _tilde ($$)  # ~-replacement, but only when whether tree nor chunk nor oo-interface
{ my ($o,$line)=@_;                                       my $id_re=qr/\w[\w\d_.-]*/;
  my $tilde_re=qr/^([~=])(?| ([+-][0-9]* | $id_re? ) | (?: \\?\{ ($id_re) \\?\} ) )/x;
  if ($o->{tilde} && _reft($o->{tilde})eq'CODE' && (my@arg=$line=~/$tilde_re(.?)/))
     { my $new=$o->{tilde}->(@arg); $line=~s/$tilde_re/$new/ if defined $new }
  $line                     # ^- @arg=($what,$for,$sep)
}
*textglob_explode=\&textglob_expand; sub textglob_expand
{ my $wa=_2void; my $o={&_opt};$o->{rewrite}//=0; @$o{'star','last'}=(0,0) if $o->{rewrite};
  my @r=_textglob $o,@_; # last and wildcards (under expansion) are ignored if rewrite -^
  my $tildef=defined $o->{tilde} && !_reft $o->{tilde}; # code variant not done here
  if ($tildef) { _treefirst { s/^~/$o->{tilde}/ } $_ for @r }     # hacked lately in
  if ($o->{star})
  { my @search=_sort _forestjoin @r;       # should be fine with backslash=1 ?
    my $searchopt={%$o,backslash=>'\\*?'}; # maybe better _dequ both sides XXX
    _treefor1 { my $val=_deref $_; my $new;
                if (defined(my $re=_g2re_cb $searchopt,undef,1,$val)) # _dequ$o,
                   { my $re=_retqr($searchopt,$re); $new=first {/(?=.)$re/} @search }
                $_=_reft($_)?\$new:$new if defined $new;
             } @r
  }
  @r=map { $o->{tree}||!$wa ? _forestmap {_dequ $o,$_} $_ :
           $o->{chunk} ? [_dequ$o,_flatten $_] : _tilde$o,join'',_dequ$o,_flatten $_ } @r;
  return $wa ? @r : Text::Glob::DWIW::Result->_new_expand($o,@r);
}

sub textglob_starlessexpand # should yield the same as tg_expand {*=0,last=0,tree=0,chunk=0}
{ my %o=(_opt(@_),star=>0,last=>0,anchors=>0);
  return map { join '',_dequ \%o, _flatten $_ } &_textglob
}  # opt assumed but not forced, for _textglob, not exported anymore anyway

sub _textglob_re
{ my $o=&_opt;  my @re=map { _addparens _g2re_cb $o,\&_qm,1,$_ } @_;
  my $re=join '|', @re; return _retqr($o,$re); # _sort should not be needed?
}
sub textglob_re
{ _2void; my $o={&_opt}; $o->{rewrite}//=1; my @arg=@_; # copy so $1 and co is allowed
  return _textglob_re $o,textglob_starlessexpand $o,@arg if !$o->{capture};
  _retqr $o,join'|',map {_markflt _treemap { _addparens _g2re_cb $o,\&_qm,1,$_ } _deref $_}
                        textglob_expand {%$o,tree=>1,star=>0,anchors=>0},@arg;#XXX
} # X unify the branches

sub _textglob_tester
{ my $o=&_opt; my $re=textglob_re $o,shift;
  my $str=$o->{pattern} ? sub($){join'',_dequ $o,_flatten shift} : \&_treejoin;
  # ^- with the _treejoin or join/dequ/flatten here, tg_grep &-match works also on
  #    chunks and tree resultsets
  $o->{invert} ? sub(_){$str->(shift//$_)!~/$re/} : sub(_){scalar $str->(shift//$_)=~/$re/}
}
sub textglob_match ($@){ _2void; my $tst=&_textglob_tester; (map $tst->($_),@_)[0..$#_] }
sub textglob_grep ($@) { _2void; my $tst=&_textglob_tester; grep $tst->($_),@_ }

sub textglob_glob ($@)                  # v- $o->{star} is handled from _g2re_cb
{ _2void; my $o=&_opt; my @pattern=textglob_starlessexpand $o,shift; my $ts=\@_;
  my $eq    =sub { my($p)=_dequ $o,@_;my@r=grep $p eq $_,@$ts; return @r?@r:@_ };
  my $finder=sub { my $re=_retqr($o,$_[0]); grep/$re/,@$ts };
  map { _g2re_cb $o,$eq,$finder,$_ } @pattern; #was: $eq=\&_id1
}

sub textglob (_;@) # (;$@) vs. (_@), (_@) fail under v5.10, but (_;@) seems ok
 {_2void; push @_,$_ if !@_; goto @_<=2-!_opt_get(@_) ? \&textglob_expand :\&textglob_glob }

{ package Text::Glob::DWIW::Iter;       use strict;  use warnings; use re 'taint';
  use parent -norequire => 'Text::Glob::DWIW::IterBase';           no overloading;
  sub new ($$$;$)       { my $class=shift; bless [0,undef,@_], ref$class||$class }
  sub __iter__ ($)      { $_[0][2] }
  sub _iter_cp : method { $_[0]->init; bless [@{$_[0]}], ref $_[0] }
  sub init ($) : method { $_[0][1]//$_[0]->next };
  sub last ($) : method { ++$_[0][0],$_[0]->init if !$_[0][0];  my $last=$_[0][1];
                          wantarray ? @{$last//[]} : $last&&join'',@$last }
  sub next ($) : method { my @r=$_[0][2]->(); $_[0][1]=@r?\@r:(); goto &last }
  sub get ($)  : method { goto $_[0][4]?\&next:\&last }
  sub size ($) : method { $_[0][3] }; sub count ($) : method; *count=\&size;
}
sub _load { my$pkg=shift; @_&&$_[0]eq''&&shift if my$im=@_; (my$file="$pkg.pm")=~s!::|'!/!g;
            eval{require$file} or croak "Can't load '$pkg'"; $pkg->import(@_)if$im; $pkg }
sub textglob_foreign (@)
{ my $wa=_2void; my $into=pop; (my $foreignopt,$into)=($into,pop) if _reft $into;
  my %o=&_opt; my $chunk=$o{chunk}; @o{qw(chunk tree rewrite)}=(0,0,0);
  if ($into eq 'Text::Glob::Expand')
     { my ($r)=textglob_expand @_,{%o,rewrite=>1}; return _load($into)->parse($r) }
  my @r=map @$_, textglob_expand @_,{%o,rewrite=>1,chunk=>1};
  @r=grep /./,map { !/^\{((?:\{$ch{'\\{}'}*\})*)\}$/ ? $_ :
                    map [split /$nobackslash\K,/, $_],grep /./,split /}{|^{{|}}$/,$_ } @r;
  $_=[textglob_expand $_,\%o] for @r;
  return $wa ? @r : \@r if $into=~/^\s*[AL]o[AL]\s*$/s;
  return _load($into)->new($foreignopt//(),@r)  if $into eq 'Set::CartesianProduct::Lazy';
  return _load($into)->new(\@r)                 if $into eq 'Set::CrossProduct';
  return _load($into,'')->can('cartesian')->($foreignopt//sub{@_}, @r)
                                           if $into=~/List::Gen|Math::Cartesian::Product/;
  return _load($into)->new(data => \@r)         if $into eq 'Iterator::Array::Jagged';
  my @ini=(0)x@r; my @pos=@ini;     my $step=sub { ++$pos[$_[0]]; @pos[0..$_[0]-1]=@ini };
  my $iter=sub { return if @pos>@r;       my @req=map $r[$_][$pos[$#r-$_]], 0..$#r;
                 for(0..@r) { $step->($_),last if $_>$#r||$pos[$_]<$#{$r[$#r-$_]} }
                 return wantarray  ?  @req  :  $chunk?\@req:join'',@req };
  return $iter                                            if $into eq 'CODE';
  return _load($into)->can('iterator_to_stream')->($iter) if $into eq 'HOP::Stream';
  return _load($into)->can('iterator')->($iter)      if $into eq 'Iterator::Simple';
  return _load($into)->new($iter)         if $into eq 'Iterator::Simple::Lookahead';
  return _load($into)->new(sub{ $iter->()//$into->is_done }) if $into eq 'Iterator';
  #return _load($into)->new($iter) if $into eq 'Class::Iterator'; # YA-FUBAR Iter
  my $size=reduce {$a*(@$b||1)} 1,@r;
  return Text::Glob::DWIW::Iter->new($iter,$size,1)       if $into eq 'REF';
  return Text::Glob::DWIW::Iter->new($iter,$size,0)       if $into eq '++';
  return $size                                            if $into=~/^(?:#|int|size|0\+)$/i;
  return do{ croak "Missing callback function for CALL mode." if _reft($foreignopt)ne'CODE';
             local $_=Text::Glob::DWIW::Iter->new($iter,$size,0);
             $foreignopt->($_) while ++$_; $_
           } if $into eq 'CALL';
  croak "Unknown module '$into' requested.";
}
sub textglob_expand_lazy (@)
    { push @_,'++' if 1>=grep { _reft $_[0] ne 'HASH' } @_; goto &textglob_foreign; }
# ----------------------------------------------------------------------------
{ no strict 'refs'; for(@EXPORT_OK){ *{"tg$1"}=*{"tglob$1"}=\&{$_} if /textglob(_.*|$)/ } }
"In this perl code is no proud about its ugliness, but also no shame on its pustules.";

__END__

=head1 NAME
X<glob> X<globbing> X<global replacement> X<wildcard> X<text, expansion> X<expand>

Text::Glob::DWIW - Yet another Text::Glob{::Expand,}

=head1 SYNOPSIS

  use Text::Glob::DWIW ':all';
  say for textglob_expand 'glob{b,al replac}ing',
          'Text{[-_],::}Glob{[-_],::}{DWIW,DoWhatIWant}';
  my @r=textglob_grep 'a*c', qw(...);

=head1 DESCRIPTION

L<C<Text::Glob::DWIW>|/"NAME"> implements L<C<glob>(3)|glob(3)> style expansion and
also matching against text. If you want to look at usage examples first, jump to
the L<C<textglob_expand> explanation|/"textglob_expand PATTERN ...">
at the start of the L<FUNCTIONS|/"FUNCTIONS"> section.

=head1 WHY

Some modules targeting that matter already exists on CPAN, e.g. for expanding
C<L<Text::Glob::Expand>> and C<L<String::Glob::Permute>>, and also a handful for matching.
Moreover perl itself came with two variants of globbing -
L<C<E<lt>E<nbsp>E<nbsp>E<gt>>|perlfunc/"glob EXPR"> aka L<C<glob>|perlfunc/glob EXPR> and
C<bsd_glob> from C<L<File::Glob>>, a core module -
which can be (mis)used for text expansion also.

Because of that already existing plurality, this wasting of CPANs namespace
demands some explanation.

In short all considered modules missed at least one of the features I liked:

=over 2

=item * separated from file system; or the non-interacting can be ensured

=item * character classes

=item * recursive pattern, like nested braces

=item * expansion

=item * interpretation as path and the corresponding can be turned off.

=item * simple interface, no arrogation to excessive descriptiveness

=item * order is determined by pattern, and looks natural.

=item * syntax is not too far from what is found in most L<shells|sh(1)>, and
        syntax extensions are integrated harmonically.

=back

=head1 WHEN STAY AWAY

Also this module has its issues like missing functionality or
L<performance|/"CAVEATS">.
To make your decisions hopefully easier a big L<MISSING|/"MISSING"> section - with
hints what you can do instead - exists.
See also under L<SEE ALSO|/"SEE ALSO">, where other modules are mentioned
which might fit your need better.

=head1 IMPORT TAGS

No functions are exported by default. They have
fixed naming schemes from which you can
select one: C<{textglob,tglob,tg}_*>.
So each function can be imported by three different names.

  :textglob_  import the subroutines so they begin with  textglob_... .
  :tglob_     ditto, except        tglob_...
  :tg_        again, this time as  tg_...
  :textglob   like :textglob_ but also import the  textglob() function.
  :tglob      ditto, but  textglob()  is renamed to tglob().
  :tg         you can guess it
  :all        load all under all available names.
  :use        use TGDWIW { options } available

Typical usage example: S<C<use Text::Glob::DWIW qw'textglob :tg_'>>.

=head1 FUNCTIONS

All the functions can be adapted by an L<option|/"OPTIONS"> hash.
In the following list only the long form is mentioned,
and the short form is used in examples.

=over 2

=item B<C<textglob_expand>> PATTERN ...

expands the glob following the syntax described under
L<PATTERN SYNTAX|/"PATTERN SYNTAX">.
The interpretation can be adapted with L<options|/"OPTIONS">, which are
given inside a hashref as first or last argument.

  tg_expand "[z-a]"  # z y x w v u t s r q ... h g f e d c b a
  tg_expand "[?-']"  # ? > = < ; : 9 8 ... 0 / . - , + * ) ( '
  tg_expand '[bcfglptwz]oo'    # boo coo foo ...
  tg_expand 'a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},}'
  # "abracadabra","abracadabr","abracadab","abracada",
  # "abracad","abraca","abrac","abra","abr","ab","a"

  tg_expand '{abra,{*}cad{*}}' # 'abra', 'abracadabra'

And also L<subtractive patterns|/"alternation subtraction {!bb} & {!mm-qq}"> are available.

  tg_expand '{a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},},!abrac}'
  tg_expand '{a{b{r{a{c{a{d{a{b{r{a,},},},},},},},},},},!*a}'
  # "abracadabr", "abracadab", "abracad", "abrac", "abr", "ab"

For more of that look at L<PATTERN SYNTAX|/"PATTERN SYNTAX">.
It should be mentioned
that a small addition to the pattern can produce a big (exponential) increase
of the resulting set. Some may think it should be better named C<textglob_explode>.

You are warned, this function is not for generating nasty big lists.

In numeric context (forcible with L<C<int>|perlfunc/int>)
it returns the count of results - by expanding all of these in memory beforehand.

A more kludged but also more effective counterpart (most of the time)
exits: L<C<textglob_expand_lazy>|/"E<nbsp> aka textglob_expand_lazy">.


=item C<textglob_expand(>PATTERN ...C<)-E<gt>B<format>(>FORMAT ...C<)>

allows C<L<Text::Glob::Expand>> style decoration and capturing,
with C<< %<num> >>, C<< %<num>.<num> >> etc.
For details of the format string, see L<there|Text::Glob::Expand>.

  print tg_expand('{foo,bar}')
        ->format("'%0' is used far too often in examples\n");
  print tg_expand('Robert {[A-C].,} Wilson')
        ->format("'%1' is the middle initial of '%0'\n");
  say tg_expand('{f[o]o,b[a]r}')->format("'%1.1' = middle char");
  say tg_expand('{{Cinderella}{fore},{Alice}{hind}}')
        ->format("%1.1 is be%1.2 the mirror.");
  say tg_expand('{file{0-100}}.tar.gz')->format("mv %0 %1.tgz");

  my %r=tg_expand('{f[o]o,b[a]r}')->format("%1.1",{paired=>1});
  # ( foo => 'o', bar => 'a' )

=item Other methods C<textglob_expand(>PATTERN ...C<)B<< -> >>>METHODC<(>...C<)>

S<C<< ->elems() >>> and C<@{E<nbsp>E<nbsp>}> list the result in the same form as called
in list context, by ignoring the C<tree> or C<chunk> option.
S<C<< ->chunks() >>>, S<C<< ->tree() >>> is equivalent to using the L<option|/"OPTIONS">
with the same name. S<C<< ->size() >>> and C<int(E<nbsp>E<nbsp>)> return the
count of expanded elements.

It can be used as a very basic iterator with S<C<< ->next() >>>, C<$$o>
or C<E<lt>E<nbsp>E<nbsp>E<gt>>.
Besides interchangeability with
L<C<textglob_expand_lazy>|/"E<nbsp> aka textglob_expand_lazy">
the worth of iterators hereby is low because the whole result is created in one go.

Only C<textglob_expand> can return an object.
No further OO interfaces for other functions are actually implemented.

=item B<C<textglob_match>> PATTERN STRING ...

returns whether the string matches. In list context more strings could be tested at once.

  tg_match 'a*','aaa'           # true
  tg_match 'a*',qw'aaa abc a b' # 1 1 1 0

=item B<C<textglob_grep>> PATTERN STRING ...

returns the strings which match the pattern.

  tg_grep 'a*a', qw'aa abba abracadabra' # finds all

=item B<C<textglob_glob>> PATTERN STRING ...

works like L<C<textglob_grep>|/"textglob_grep PATTERN STRING ..."> but also adds
L<expansions|/"textglob_expand PATTERN ..."> from wildcardless sub-patterns.

=item B<C<textglob>> PATTERNE<nbsp> or E<nbsp>B<C<textglob>>E<nbsp> or
      E<nbsp>B<C<textglob>> PATTERN STRING ...

The one-argument form acts like C<L<textglob_expand|/"textglob_expand PATTERN ...">>.
The parameterless variant also, but uses C<L<$_|perlvar/$_>> instead.
In the other cases it mimics C<L<textglob_glob|/"textglob_glob PATTERN STRING ...">>.
Many people like such all-in-one functionality, but it's not everyone's cup of tea.
If you prefer less magic use the more explicit variants.

=item B<C<textglob_re>> PATTERN ...

transforms the glob into a regexp.

=item B<C<textglob_foreign>> PATTERN ... CLASS

transforms the glob into other classes.
So for example C<L<Text::Glob::Expand>> has
caching and can manage slightly more data.
I believe that the connection to L<TGE|Text::Glob::Expand>
is stable but has some restrictions as explained later on.

  my $obj=tg_foreign '[[:card:]]#2' => 'Text::Glob::Expand';
  say join ',',$obj->explode;

If this is not sufficient, you can try to use modules which apply
index arithmetic to calculate the values and thus offer
random access without the need of calculating interim values.

  my $obj=tg_foreign '{1-100}#10' => 'Set::CartesianProduct::Lazy';
  say $obj->count;                     # 1e20
  say join ' ',$obj->get(1234567890);  # 1 1 1 1 1 13 35 57 79 91

  my $obj=tg_foreign '{1-100}#10' => 'List::Gen';
  say $obj->size;                      # 1e20
  say join ' ',$obj->get(1234567890);  # 1 1 1 1 1 13 35 57 79 91

Don't expect too much here. Whether you combine the strengths or the weaknesses of the
two modules depends heavily on the pattern.
The non-globbing backends are more a proof of concept
to show what could be L<possible|/"lazy generation">.

Transformations are defined forE<nbsp>
C<L<Set::CartesianProduct::Lazy>>,E<nbsp> C<L<List::Gen>>,E<nbsp>
C<L<HOP::Stream>>,E<nbsp> C<L<Set::CrossProduct>>,E<nbsp>
C<L<Iterator::Array::Jagged>>E<nbsp> and E<nbsp>C<L<Text::Glob::Expand>>.

Options can be given as first argument, or immediately before the CLASS.

Here the following restrictions apply:

=over 2

=item * No support for L<explicit anchors|/anchors>

=item * ranges, wildcards and subtractive patterns are
        pre-resolved by this module. Depending
        on their position and kind most of the work
        is done by this module.
        Thus no advantage can be gained through the use of a more powerful backend.

=item * currently for non-globbing backends the recursion
        is resolved, even in cases where the backend understood it.

=item * misinterpretation is more likely (for non-globbing backends).

A look at the L<lazy generation|/"lazy generation"> point under
L<what is missed|/"MISSING"> might be interesting.

=back

=item B<C<textglob_foreign>> PATTERN ... ITER_TYPE

=item E<nbsp> aka B<C<textglob_expand_lazy>>

C<textglob_foreign> can also generate an iterator.
The L<same restriction|/"No support for explicit anchors">
applies as L<above|/"textglob_foreign PATTERN ... CLASS">.

To stress the point, this function is only B<partly> lazy: Only
the outermost expansion layer is handled lazy at most.

Following ITER_TYPEs are supported:

  'CODE'             returns a closure as iterator
  'REF'              a reference to an auto-advancing scalar(/array)
  '++'               simple(minded) iterator:  while (++$i) {...$$i...}
                     also in stock: while (defined(my $i=<..>)) {...}
  CALL => \&sub      iterate over and call sub each time
  'SIZE'             calculated size only
  'Iterator::Simple' instance of that class
  'Iterator::Simple::Lookahead'         -"-
  'Iterator'                            -"-

C<textglob_expand_lazy> assumes in the one-argument form S<'C<++>'>.
Besides that no difference to C<textglob_foreign> exists.
Hereby the offered builtin iterator (C<++>) should be able to mimicry
different styles of iterator interfaces and therefore should be combinable
with a wide range of libraries offering 'list' processing.

=for :comment
Hereby the offered builtin iterator (C<++>) should be usable with S<C<L<Object::Iterate>>>,
S<C<L<Iterator::Simple>>> and libraries assuming a S<C<L<SPOPS::Iterator>>>-style
interface. If you have no preferences already, take a closer look at
C<Iterator::Simple>.

Also note that the object returned from
L<C<textglob_expand>|/"textglob_expand PATTERN ..."> exports basic iteration
support S<C<$$o>> (like REF-mode) and C<E<lt>E<nbsp>E<nbsp>E<gt>>.

=item B<C<textglob_options>> HASH

For more details see L<Setting of Options|/"Setting of Options">.

=back

=head1 PATTERN SYNTAX

=over 2

=item B<alternation> C<{aa,bb,cc}>

=item aka B<brace expansion>

  tg_expand 'Read The F'.
            '{ine,unded,a{{bul,m}ous,ntastic},{ascinat,\*}ing} Manual'
  tg_expand '{m{eo,iao,e}w,purr...}m{eo,iao,e}w'    # concert at home

generates all possible combinations.
The pattern C<{a,b}{0,1}> results in the list C<a0>, C<a1>, C<b0> and C<b1>.
This means the number of resulting elements is the product of the element count
of all sets. Be aware of that and take L<care|/"break (default: 0 # =off)">.

A C<{> or C<,> may be quoted with a
L<backslash|/"the escape character \">
to prevent it from being considered part of a brace expression. An alternation set
may contain others.

=item B<alternation ranges> C<{aa-zz}>

=item aka B<sequence expression>

  tg_expand '{aunt-away}'      # like perl's range op: aunt aunu ..
  tg_expand '{y0-2b2}'         # more: y0 y1 .. z0 z1 .. 1a0 1a1 ..
  tg_expand '{100-1,zero}'     # countdown
  tg_expand '{\-5-5}'          # -5 -4 -3 -2 -1 0 1 2 3 4 5
  tg_expand '{0.00-20.00}'     # 0.00 0.01 .. 19.98 19.99 20.00
  tg_expand '{(1)-(1_001)}'    # (1) (2) .. (999) (1_000) (1_001)
  tg_expand '{*******-*}'      # ******* ****** ***** **** *** ** *
  tg_expand ':{,\----------})' # pinocchio, animated

Ranges with negative numbers are only defined for integers (only sign and digits).
Punctuation characters must be used equivalently otherwise the result is undefined.

Some shells use C<..> instead of C<->, however AFAIK all use C<-> for
L<character ranges|/"character ranges [a-z]">.
In this module a decision for unification was made.

I<Important:> Be careful not to create a range unintentionally.

=item alternation ranges with B<step size> C<{aa-zz-5}>

  tg_expand '{auto-bane-1000}'  # auto awga axsm azey
  tg_expand '{001-100-9}'       # 001 010 019 028 ... 082 091 100
  tg_expand '{-10-10-2}'        # -10 -8 -6 -4 -2 0 2 4 6 8 10
  tg_expand '{-10--20-2}'       # -10 -12 -14 -16 -18 -20

The step size must be a decimal integer value greater than zero. This means
C<tg_expand '{a-z-0}'> is interpreted as ranging from C<a> to C<z-0>.
The step size for descending ranges is only well defined if the start- and end-point
are part of the result set.
For other possibilities to construct ranges see C<L<List::Maker>> and
the powerful and comprehensive C<L<List::Gen>>.

=item alternation B<subtraction> C<{!bb}> & C<{!mm-qq}>

remove matching elements from the expansion set inside the same scope of braces.
In other words, this operation is restricted to the nearest surrounding braces.

  tg_expand '{0-20,!*[13579]}'         # 0 2 4 6 8 ... 16 18 20
  tg_expand '{[a-d][a-d][a-d][a-d],!*{a*a,b*b,c*c,d*d}*}' # permute

I<Side note:> The above example is for syntax demonstration only.
For calculation of permutation you better use C<L<Algorithm::Permute>> or such.

=item B<character classes> C<[asdf]>

  tg_expand '[bcdhlmprt]uff'           # ... ruff tuff

One of the characters matches or else has its place in the generated set.

I<Consider:> B<C<[aaa]>> and C<[a]> are not the same in the
L<expanding case|/"textglob_expand PATTERN ...">,
the first delivers E<nbsp>C<a>,C<a>,C<a>E<nbsp> analogue to C<{a,a,a}> or C<a{,,}>.
Also empty character classes are allowed. Therefore C<[][]> has no special meaning
- two nothings -, this entails that you must quote the containing closing bracket C<[\][]>.

I<Note:> Nothing is a little bit imprecise, C<{}> and C<[]> represent the set with
the B<one> element of the B<zero>-length string C<''>.
If you need cross products with empty sets then look somewhere else, for example toE<nbsp>
S<C<< L<Set::Scalar>->L<cartesian_product|Set::Scalar/"Cartesian Product and Power Set">
>>>, E<nbsp>C<L<Set::CrossProduct>>E<nbsp> or
E<nbsp>S<C<< L<List::Gen>->L<cross|List::Gen/"combinations:"> >>>.

=item B<character ranges> C<[a-z]>

The one character wide counterpart of L<alternation ranges|/"alternation ranges {aa-zz}">.

  tg_expand '[1-357-9]'  # 1, 2, 3,  5,  7, 8, 9
  tg_expand "[\0-\40]"   # "\0", "\1", "\2", ... ' '

Whereas C<tg_expand "[\t- ]"> results only in C<"\t", "\n", "\N{VT}", "\f", "\r", " ">.
When the start and end point belong to the class of printable, whitespace or alarm bell,
then the generated output is also restricted to this.

=item B<predefined> char classes S<C<[ E<nbsp>[:upper:]E<nbsp> ]>>

  tg_expand '[aeiou[:space:]]'
  tg_expand '[[:punct:]][[:punct:]]'   # potential twigils

The following predefined classes are supported and in case they
do not constitute a very narrow set, they are restricted to the B<ASCII> range.

  [:digit:]       cumbersome way to write [0-9]
  [:xdigit:]      [0-9a-f]
  [:punct:]       punctuation chars ala POSIX (locale ignored)
  [:space:]       whitespace
  [:blank:]       "\t" & " "
  [:lower:]       [a-z]
  [:upper:]       [A-Z]
  [:alpha:]       [A-Za-z]
  [:lowernum:]    [a-z0-9]
  [:uppernum:]    [A-Z0-9]
  [:cardsym:]     spade heart diam club, both colors black first
  [:card:]        playing cards
  [:die:]         all sides of a die
  [:chess:]       chessmen, white makes the first move
  [:mahjong:]     tiles of mah-jong
  [:trigram:]     base for the  i ching
  [:zodiac:]      signs of zodiac
  [:note:]        musical notes
  [:smiley:]      the unicode consortium knows about
                  59 different emotions expressible by
                  a circle with points and lines in it.
  [:planet:]      symbols of planets of our solar system, with the
                  sun (a star) so the name is not really correct.
  [:polygon:]     triangle,quadrangle,pentagon & hexagon
  [:legal:]       the sign for (C),(R),(P),SM,TM.
  [:roman:]       roman numerals (but not the ASCII substitute)

=for :comment
  [:hexagram:]    i ching/yijing
  [:endmark:]     end marker for sentences for latin-based languages
  [:alphanum:]    [A-Za-z0-9] (also known as [:alnum:])
  [:word:]        [A-Za-z0-9_]
  [:luck:]

With a C<-> at the end the generating order is reversed.

  [:digit-:]      [9-0]

=item B<subset> from predefined char classes S<C<[ E<nbsp>[:lower4-6,20:]E<nbsp> ]>>

  [:lower12-14:]  l, m & n
  [:cardsym1-4:]  black suit
  [:cardsym6,2:]  red and black heart
  [:card1:]       ace of spades
  [:card1,1,1,1:] swindler
  [:lowernum-27:] [9-0] again

The numbering begins with one, so C<[:luck1-:]> is identical to C<[:luck:]>,
and C<[:luck-1:]> is identical to C<[:luck-:]>. This numbering scheme has
the pitfall that C<[:digit1:]> is C<0>. Yet starting with one is more natural in most cases.

  tg_expand '[[:card1-11,13-25,27-39,41-53,55-56:]]'
  tg_expand '{[[:card1-56:]],![[:card12,26,40,54:]]}'
  # both: all cards without jokers and knights


=item B<pattern quantifier> C<{E<nbsp> }#9>, C<{E<nbsp> }#0-9>

=item E<nbsp> E<nbsp> and further C<[E<nbsp> ]#9>, C<[E<nbsp> ]#0-9>

=item aka B<list exponentiation>

  tg_expand '[01]#8'                 # 0..255 in binary
  tg_expand '[abc]#0-1'              # optional, same as {,[abc]}
  tg_expand 'AB{inside comment}#0BA' # ABBA
  tg_expand ':[-]#0-8)'              # pinocchio again
  tg_expand '# {-=}#38-'             # decoration line
  tg_expand '[a]#10'                 # by the doctor
  tg_expand '1[_,]#0-1\200'          # =1{,[_,]}200: 1200 1_200 1,200

A C<{>I<pattern>C<}#>I<n> is the same as repeating the pattern I<n> times
(C<{>I<pattern>C<}{>I<pattern>C<}>...).
Being an expander feature it needs a finite upperbound.
If you need more power, the C<L<Regexp::Genex>> module is worth a try.

For matching using the builtin L<Regexp|perlre> is preferable.
Most widely known are the (non-expanding) I<ksh> style variants
C<?()>, C<*()>, C<+()>, C<@()> and C<!()>. The use of C<#>
maybe looks familiar to I<zsh> users, but the meaning is different
to the (yet another) matching only extension from I<zsh>.

=item B<element repeat> C<{E<nbsp> }##9> or C<[E<nbsp> ]##9>

  tg_expand '[01]##8'                  # only: 00000000 11111111
  tg_expand ':[-]##8)'                 # pinocchio, unanimated
  tg_expand '# {-=}##38-'              # as #
  tg_expand '[a]##10'                  # as #
  tg_expand '{([_]#0-3)}##2'           # S-XXL
  tg_expand '{[a-d]#4,!{*[a-d]}##2*}'  # permutation again

Not the pattern, the element is repeated. Where B<C<[ab]#2>> produces E<nbsp>C<aa>,
C<ab>, C<ba>E<nbsp> and E<nbsp>C<bb>,E<nbsp> the same as C<[ab][ab]>;
B<C<[ab]##2>> produces only E<nbsp>C<aa> and E<nbsp>C<bb>,E<nbsp>
here only the resulting element is duplicated. Mnemonic: the
repetition is done later so two E<nbsp>C<#>.

=item B<wildcards> C<?>, C<*>, C<**> & C<***>

  *    Match zero or more of characters, except those listed in
       unchar=>'...'. Also tests against condition of unhead=>'...'
  ?    Match a single character, honors unchar- & unhead-option.
  ***  Match any string of characters by ignoring unchar & unhead.
  **   All letters (not restricted by unhead) are allowed inside,
       but bordered by 'unchar' against other characters.
       This whole-parts-only resembles multiple directory semantic.
       Fallback to *-behavior if unchar is not set.

The wildcards have slightly different behavior if
L<matching|/"textglob_grep PATTERN STRING ...">,
L<subtracting|/"alternation subtraction {!bb} & {!mm-qq}"> or
L<expansion|/"textglob_expand PATTERN ...">.
In expansions it stands only for a single best-fitting value instead of all.

For better understanding of the difference between E<nbsp>C<**> and C<***>,
here a description of how to replace one by the other:

  ***   {*,*/**,**/*,*/**/*} # unchar=>'/' assumed, and unhead unset
  **    {/,/***/}            # ignoring cases at the start or end

Using C<< tg_grep {L<unchar|/unchar (default: '')>=E<gt>'/'},'a**d', >>...
would match E<nbsp>C<a/d>, E<nbsp>C<a/b/d>,
E<nbsp>C<a/b/c/d>E<nbsp> and so on,
but B<not> E<nbsp>C<ad>, E<nbsp>C<ab/d>, E<nbsp>C<ab/cd>.E<nbsp>
The variant E<nbsp>C<a/**/d> additionally doesB<n't> match E<nbsp>C<a/d>.
While C<a***d> matches all the examples above.
The B<C<**>>-behavior (when C<< {L<unchar|/unchar (default: '')>=E<< gt
>>'/',L<unhead|/unhead (default: '')>=E<gt>'.'} >> options are set)
is comparable to that in many shells
(after E<nbsp>C<L<shopt|shopt(1)> -s globstar> is applied).
         .
Some examples: assuming we have a list of paths - domain familiar to the majority -
and L<C<unchar>|/unchar (default: '')> is set accordingly:

  /** or /***  match absolute paths
  ?***         match relative paths (whereas ?** = {?,?/**})
  **/ or ***/  any paths ending in / (aka marked directories)
  **file       that file anywhere
  ***ext       file with that ext, wherever
  **file.*     that file with whatever extension anywhere
  dir**        dir and all its subdirectories with all files inside
  dir/***ext   all files with that ext under that dir or its subdirs
  **subdir/*   all files inside such named subdirs
  **subdir**   subdir and everything beneath

See further in the L<option section|/"OPTIONS"> for adaptable behavior,
e.g. through options like
L<C<unchar>|/unchar (default: '')> and L<C<unhead>|/unhead (default: '')>.

=item the B<escape> character C<\>

The backslash C<\> forces the following (meta)character to loose its special meaning,
so that it is used verbatim.

=item B<word splitting> (alternatives for csh'ish space separator)

Instead of space separator from the original csh glob facility,
you can use:

  textglob '{foo,bar}'
  textglob [qw'foo bar']

=item normal text

The rest, this includes space and parentheses, and per default also
slash, tilde, equal sign and (leading) dot constitutes normal text.
But some of the L<option switches|/"OPTIONS"> allow a more shellish handling.

=item anchors

Per default the pattern is implicitly anchored at both sides.
Besides using C<*>....C<*> for suppression, an
L<C<anchorB<ed>>|/"anchored (default: 'a,z')">-option exists.

  tg_grep 'jam', qw'pyjamas jamboree',{anchored=>0}

If you are feeling lucky you can try another very experimental feature
of explicit anchors. These can be turned on with
L<C<anchorB<s>>|/"anchors (default: '')">.

  tg_expand 'for{$,,ever and }ever',{anchors=>1}
  # for, forever, forever and ever
  tg_expand 'flop{^,$}flip',{anchors=>1}  # flip, flop

It is important to note that in case of use for matching the start
anchor C<^> has the restriction that only
variable length pattern which can go down to zero are allowed to precede.

  tg_options anchors => 1;
  tg_grep 'flop{^,$}flip',qw'flip flop'     # only a flop
  tg_grep '*{/a/,^}bla', qw'where/ever/a/bla bla' # works

However such limitation does not apply to the end anchor C<$>.
(The acting of the end anchor C<$> is more consistent to the use for expansion.)

  tg_grep 'for{$,,ever and }ever',      # fine, match all
          'for','forever','forever and ever'

Don't jumble the two options! They have very different effects.

=back

=head1 OPTIONS

Options influence the behavior and extend the adaptability
and thereby the range of application/usage opportunities.

=head2 Setting of Options

Options can be supplied directly to the function call or
already when loading the module.
So you don't have to repeat it if you use the same options in row.

  use Text::Glob::DWIW ':all', { unchar => '/' };
  tg_options { case => 0 };    # tg_options case => 0; also works
  say for tg_grep { anchored => 0 }, 'falling stars', ...;

=over 2

=item Appended to the E<nbsp>C<use>E<nbsp> statement

Hereby options must be specified as hash reference at the end.
This method only allows constant (compile-time known) values.
The options act in all function calls which are inside the same lexical
scope as the E<nbsp>C<use> statement. Declaring another E<nbsp>C<use>E<nbsp> in an
narrower scope can be done. These options are only set once at compile time, and
therefore don't reset if the program flow arrives at them another time.
The combined behavior with
E<nbsp>L<C<textglob_options>|/"Through the E<nbsp>textglob_optionsE<nbsp> function">
call (from inside the same scope) is loosely comparable with E<nbsp>
L<C<state> variables|perlsub/"Persistent variables via state()">.

As shorthand notation - instead of always writing out the full package name -
the tagE<nbsp> C<:use> can be added to the first L<import|/"IMPORT TAGS">.
After doing that,E<nbsp> S<C<use TGDWIW { E<nbsp>}>E<nbsp>> is available alternatively.

=item Through the E<nbsp>C<textglob_options>E<nbsp> function

Here the validity is the scope of the next outer E<nbsp>C<use> statement.
A restriction to constants doesn't exist. If needed a E<nbsp>C<use> clause
(with or without options) and a followingE<nbsp> C<textglob_options>E<nbsp>
can be combined.

=item Directly supplied to the function call

The options must be handed over as the first or as last parameter in the form
of a hash reference C<{E<nbsp>E<nbsp>}>.
Options are only considered for that function and override options
set otherwise.

=back

I<Warning:> The presetting capabilities works only by use of explicitE<nbsp>
C<use>E<nbsp> without scope related L<indirections|/"PITFALLS">.

=head2 General Options

=over 2

=item C<quant> (default: 'C<#,##>')

The quantifier L<...C<#>I<n>C<->I<m>|/"pattern quantifier {E<nbsp> }#9, {E<nbsp> }#0-9">
and L<...C<##>I<n>|/"element repeat {E<nbsp> }##9 or [E<nbsp> ]##9"> can be turned off,
then a E<nbsp>C<#>E<nbsp> behind E<nbsp>C<{E<nbsp> }> or C<[E<nbsp> ]>E<nbsp>
acts as a normal character.

=item C<range> (default: 'C<{},[]>')

The L<C<{0-100}>|/"alternation ranges {aa-zz}"> and L<C<[a-z]>|/"character ranges [a-z]">
can be turned off. Then the hyphen-minus (C<->) is handled like a normal character.

=item C<charclass> (default: 'C<def1,sort0>')

Some L<character class|/"character classes [asdf]"> features are also switchable.
E.g. the L<predefined character classes C<< [[:punct:]]
>>|/"predefined char classes [ E<nbsp>[:upper:]E<nbsp> ]"> can be turned off
with C<{charclass=E<gt>'def0'}>.
The result is then like the feature doesn't exists.
For example C<[[:punct:]]> is interpreted as a char class with C<[\[:punct:]>
and a following C<]> which generates E<nbsp>C<[]>, C<:]>, C<p]>, C<u]>, ... C<t]>, C<:]>.

Some shells generate L<brace sequences|/"alternation {aa,bb,cc}"> in natural order,
but sort the contribution from
char classes in ascending order. With C<{charclass=E<gt>'sort+'}> this can
simulated, and C<sort-> is for descending order.

=item C<minus> (default: C<1>)

The L<subtracting|/"alternation subtraction {!bb} & {!mm-qq}"> with
S<C<{E<nbsp> E<nbsp>,!E<nbsp> }>> can also be turned off.

=item C<anchors> (default: '')

Basic support for B<explicit> L<anchors|/anchors> exists.
This feature is known to be buggy, and is therefore turned off by default.
Turn it only on if you can not live without it.

But maybe you have searched for the
L<C<anchored>|/"anchored (default: 'a,z')">-option anyway, which can be found
in the following
L<section about options for matching|/"Options which influence Matching">.

=item C<tilde> (default: C<undef>)

Through this option the handling of tilde expansion is available:

  say tg_expand '~{he,she,it,sking}/path',{tilde=>'/home/'};

More powerful possibilities are offered by using coderefs:

  sub tilde_expand ($$$)
  { my ($what,$arg,$delim)=@_;
    my $nyi= $what eq '~' && $arg!~/^[+-\d]/ && $delim=~qr'^/?$';
    return unless $nyi; # don't change
    File::HomeDir->${$arg eq '' ? \'my_home' : \'users_home'}($arg)
  }
  say tg_expand $p='~{he,she,it,sking}/path',{tilde=>\&tilde_expand};

Typical meanings (mentioned here only so you know what is your part ;-):

  ~user, ~{user} File::HomeDir->users_home($user)
  ~              File::HomeDir->my_home
  ~-             $ENV{OLDPWD} # or whatever is available in perl
  ~+n            (`dirs`)[$n]
  ~-n            (`dirs`)[-$n-1]
  =file          File::Which::which($file)

The subref/closure variant is not combinable with the L<C<tree>|/"tree (default: 0)">
or L<C<chunk>|/"chunk (default: 0)"> option.
It is also not available in combination with the
L<< object interface|/"textglob_expand(PATTERN ...)->format(FORMAT ...)" >>.
This matches only at the beginning of patterns.
But differently to shell behavior a path separator sign (e.g. B<C<:>> under I<Unix>)
is B<not> honored. Split it yourself beforehand.

=item C<break> (default: C<0> # =off)

Too easily big lists can be generated by simple patterns.

=for :comment
This means without countermeasures this is a DoS attack vector
if used with data from outside.
Maybe you think first to turn off the L<C<quant>|/"quant (default: '#,##')">
and the L<C<range>|/"range (default: '{},[]')"> option.
And indeed the I<theoretical> length of
C<join '', textglob '{aaa-zzz}{aaa-zzz}'> is around 1GB.
But the memory usage of this operation is even much higher.
And of course the C<quant> option can run even wilder.
You can turn off this particular features with C<< {quant=>0,range=>0} >>,
but this doesn't protect you.
Because even C<[1234]> repeated 10 times manually, would be more than
1 million entries.

  tg_expand '[0123][0123][0123][0123][0123]',{break=>1000}; # die

This option allows to set an upper bound for the size of a generated list.
It L<C<die>s|perlfunc/"die LIST"> if this limit is reached.
Use it in an L<C<eval>|perlfunc/"eval BLOCK"> block for catching
if you turn this feature on.

Some assumptions are made:

=over 2

=item * Only sets which are going to be constructed are handled.
  The reasoning is that for matching,
  more complex patterns are processable, and so the are accepted.

=item * Size of interim sets are checked.

=item * Checks are only done when: a quantifier is used, a cross product happens,
   and by ranges.

=item * Ranges are often only roughly guessed, ...

=item * No analysis of cost is done, so C<{aaaa-zzzz}> is considered to have the
  same costs as C<[a-z][a-z][a-z][a-z]>, and even
  C<{[a-z][a-z][a-z][a-z],![a-z][a-z][a-z][a-z]}>.

=item * Only the growth of elements counts, and not the growth of the size of a
  single element is considered. Here the important exception is C<##>I<n>.
  Without this the value of the whole option would be questionable.

=item * The size of a single element from the input always counts as one.

=back

So the last point means, that you must also restrict the length of the input field!
Otherwise:

  tg_expand 'a'x10_000_000,{break=>1} # no die, the death himself


The value you should set for C<break> depends on the power you have.
In the following, values are from a weak
machine and should be considered as a starting point.
A value between 1000 and 3000 seems reasonable, if you forbid the
L<subtractive pattern|/"alternation subtraction {!bb} & {!mm-qq}">
by setting C<< {L<minus|/"minus (default: 1)">=>0} >>.
With this costly feature enabled, a value of 100 seems to fit better.

Set also the
L<C<stepsize>-option|/"stepsize (default: 0 # =on, without restriction)">
to a reasonable value e.g. -100.

And B<please> don't rely on this feature. This is most likely not ready for
security sensitive production environments!
Maybe combining it with modules like C<L<Time::Out>> helps.

=item C<stepsize> (default: C<0> # =on, without restriction)

L<Ranges with step size|/"alternation ranges with step size {aa-zz-5}">
can be turned off or limited.

=over 2

=item * C<undef>: If set to C<undef> the step size feature is completely turned off.
  Then step sizes are not recognized as such and
  the appendage is interpreted as a part of the range's end point.

=item * C<0>: A value of C<0> means no limit.

=item * C<< >0 >>: If a number greater zero is set,
  then this is the maximal allowed step size.
  If this size is exceeded, an exception is thrown.
  See L<C<eval> in perlfunc|perlfunc/"eval BLOCK"> for handling.

=item * C<< <0 >>: If a negative number is given, this is
  a kind of soft limit, that influence
  the internal element count prediction. This has only an effect if
  L<C<break>|/"break (default: 0 # =off)"> is also set.

  tg_expand '{1-100-100}',{stepsize=>-10,break=>10} # '1'
  tg_expand '{1-100-100}',{stepsize=>-10,break=>9 } # die

=back

I<Note:> Actually for non integer ranges an extended magic increment is used, which
can get CPU intensive if big steps are used. So one of the reasons for restriction is
that 'magic' arithmetic operations are B<not> yet programmed,
and so delegation to repeated increments is used.

=back

=head2 Options which are specific for Wildcards

=over 2

=item C<star> (default: 'C<?,*,**,***>')

The L<wildcards|/"wildcards ?, *, ** & ***">
C<***>, C<**>, C<*> and C<?> can also be turned off.
With C<< {star=>0} >> this symbols stop to be special and are taken verbatim.
With C<< {star=>1} >> they could later be brought back.
Also selecting selectively is possible.

=item C<twin> (default: 'C<**,***>')

For degrading the twin star C<**>- andE<nbsp> the triplet star
C<***>-L<wildcard|/"wildcards ?, *, ** & ***">.
With C<< {twin=>0} >> usage these act like normal stars.
It is sometimes called I<globstar>.

As surplus C<< {twin=>'**+'} >> switch C<**> to C<***> behavior
and C<< {twin=>'***-'} >> switch C<***> to C<**> behavior.
For complete switch off, see the
L<C<star>|/"star (default: '?,*,**,***')">-option.

=item C<unchar> (default: '')

All inputs are equal. But here you can define 'non grata' chars,
which are not matched by the
L<wildcards C<*> and C<?>|/"wildcards ?, *, ** & ***">.
This setting is ignored by the B<C<***>>-wildcard, and has special meaning
for the B<C<**>>. If unset - the default - then C<***>, C<**> and C<*> act
B<identically>.

  textglob 'fo*ba*','foo/bar','foobaz',{unchar=>'/'}    # foobaz only

If the argument to the option looks like a
L<character class|/"character classes [asdf]">, the interpretation
is likewise.

If you don't want matching multiline texts, use E<nbsp>C<< unchar=>"\n" >>.

=item C<unhead> (default: '')

If the string starts (or continues after an L<C<unchar>|/"unchar (default: '')">)
with one of the characters mentioned in the C<unhead>-option,
it is hidden from the result except it is explicit in the pattern.

Under Unix files beginning with a leading dot are called hidden.
They are second class citizens (or are they E<eacute>minence grise?)
which are only visible if explicitly requested.

  textglob {unhead=>'.'},'*', qw'. .. .bashrc fine your.txt'
  # find: fine, your.txt

So C<< {unhead=>'.',unchar=>'/'} >> serve I<dotglob> behavior.

=back

=head2 Options for Expanding

=over 2

=item C<tree> (default: C<0>)

Instead of a list of text, returns a list of listrefs where braces subgroups are
itself refs (natural list refs or scalar refs as marker).
This can be seen as an alternative to the
L<< S<C<< ->format >>>|/"textglob_expand(PATTERN ...)->format(FORMAT ...)" >> feature.
Compare it to the L<capturing|/"capture (default: 0)"> feature for matching.

  tg_expand 'a{b,c}d',{tree=>1}  # ['a',\'b','d'], ['a',\'c','d']

=item C<chunk> (default: C<0>)

Instead of a list of text, returns a LoL structure,
where the listrefs hold the ordered single chunks.
This and the previous feature are only available for
L<C<textglob_expand>|/"textglob_expand PATTERN ...">.

  tg_expand 'a{b,c}d',{chunk=>1} # [qw'a b d'], [qw'a c d']

=back

=head2 Options which influence Matching

=over 2

=item C<case> (default: C<1>)

Normally matches are case sensitive C<{case=E<gt>B<1>}>.
But you can chose to ignore case, with C<< {case=>0} >>.
Beside that, a extended case mode C<< {case=>2} >> exists, where uppercase characters
match only uppercase, but lowercase match both. This mode is best known from
search engines. Then an uppercase variant C<< {case=>3} >> exists where
uppercase letters match both.

  my @v=qw'ABC abc Abc aBC aBc Abd';
  tg_grep {case=>0}, 'Abc', @v # all except Abd
  tg_grep {case=>1}, 'Abc', @v # only Abc
  tg_grep {case=>2}, 'Abc', @v # ABC Abc
  tg_grep {case=>3}, 'Abc', @v # abc Abc
  tg_grep {case=>-1},'Abc', @v # aBC
  tg_grep {case=>-2},'Abc', @v # ABC aBC
  tg_grep {case=>-3},'Abc', @v # abc aBC aBc

A mode for people with defect shift key C<< {case=>4} >>, where every first
character of a word if lowercase, match both.

  tg_grep {case=>4}, 'abc', @v # abc Abc
  tg_grep {case=>-4},'ABC', @v # abc Abc


Beside that also a CamelCase mode C<< {case=>5} >> exists:

  tg_grep {case=>5}, 'CamelCase',qw'CamelCase camel_case camelcase'
  tg_grep {case=>-5},'CamelCase',qw'cAMELcASE c_a_m_e_lc_a_s_e cc'
  # find first and second

=item C<anchored> (default: 'C<a,z>')

Normally pattern search is done by testing if the whole string fits.
By turning off anchoring a part of the string is enough for matching.
This is useful if you like to combine parts, because enclosure with C<*>
doesn't help with that.
Single sided anchoring is available by setting the option to
E<nbsp>C<^> or C<$>,E<nbsp> or by setting to E<nbsp>C<a> or C<z>.

  my @horoscopes= ...
  .. $astro=~/${ \tg_re '[[:zodiac:]]*',
                  {anchored=>0,greedy=>1,unchar=>'[[:zodiac:]]'} }/g;
  .. $astro=~/${\tg_re'[[:zodiac:]]',{anchored=>0}} [\pP\w\s]*/xg;
  .. split /(?=${\tg_re '[[:zodiac:]]',{anchored=>0}})/,$astro;

Of course for that simple case, you can write:

  my @horoscopes=grep !/^.$|\Q$astro/,
                 $astro=~tg_re '{[[:zodiac:]]*}#12',{capture=>1};

The C<L<Interpolation>> module is recommended as assembly adhesive.
If you only want to pimp up your L<REs|perlre>, have a look at C<L<Regexp::Common>>.

=item C<invert> (default: C<0>)

Inverts the matching.
Only for use with L<C<textglob_match>|/"textglob_match PATTERN STRING ..."> and
L<C<textglob_grep>|/"textglob_grep PATTERN STRING ...">.
It is also fine for L<C<textglob_glob>|/"textglob_glob PATTERN STRING ...">
and L<C<textglob>|/"textglob PATTERNE<nbsp> or E<nbsp>textglobE<nbsp> or E<< nbsp
>>textglob PATTERN STRING ...">, so long as you use that because of their shorter name.
But in the cases where matching is mixed with expansion, it is unlikely to do what you want.

=item C<capture> (default: C<0>)

has only meaning for L<C<textglob_re>|/"textglob_re PATTERN ...">.
Through that C<{}> and C<[]> act as capture groups.

  my $re=tg_re 'A {v* ,}{*} story',{capture=>1};
  my @r='A very short story'=~/$re/;  # 'very ', 'short'

It interacts slightly with C<rewrite>. You can use C<grep defined,(>...C<=~/$re/)>
to equalize the differences between these modes.

A common interface between expanding and matching would be nice,
but OTOH that way it was easy to implement. It's here because it was easier
to code, as to explain why it is left out.
This option is likely to change or disappear in future.

=item C<greedy> (default: C<0>)

Default behaviour for L<C<*>, C<**> and C<***>|/"wildcards ?, *, ** & ***">
is non-greedy (C<0>), you can switch to greedy (C<1>) and possessive (C<2>).

  'eggshells'=~tg_re '{egg*s}*',{greedy=>0,capture=>1}    # eggs
  'eggshells'=~tg_re '{egg*s}*',{greedy=>1,capture=>1}    # as is

  tg_match 'sim*.bim',  'simsala.bim',{greedy=>2,unchar=>'.'} # 1
  tg_match 'sim***.bim','simsala.bim',{greedy=>2,unchar=>'.'} # 0

Best you forget that this option exists. (Consider using L<Regexp|perlre>.)

=back

=head2 Esoteric Options

=over 2

=item C<last> (default: C<1>)

The unescaping/dequoting of this module mostly follows filter semantics.
So different kinds of data processing can be stacked together.
Normally the escaping of the escape, so that that is verbatim,
in our case a backslashed backslash C<\\>, should be only removed
from the last stage. So usage requires no knowledge of the filter stack depth.
So composited tools can be seen as a blackbox.
If this module is not the last stage, you can set this option to 'off'
C<< last=>0 >>, then C<\\> would not be dequoted, an the protected and
the protecting backslash would be handled down as they are.
This applies only to L<expansion|/"textglob_expand PATTERN ...">.

=item C<rewrite> (default: C<0> for expand, C<1> for matching)

Instead of expanding, the pattern is only rewritten to a normalised, simpler form.
This is the default interim format for matching.

  tg_expand 'foo{[ab][01]}#2{[ab][01]}##2ba[rz]',{rewrite=>1}
  # foo{{{a,b}{0,1}}{{a,b}{0,1}}}{a0a0,a1a1,b0b0,b1b1}ba{r,z}

If necessary - for
L<C<##> element repeat|/"element repeat {E<nbsp> }##9 or [E<nbsp> ]##9"> or
L<C<!>... subtraction|/"alternation subtraction {!bb} & {!mm-qq}"> -
the pattern is partly expanded.
Also the L<C<last>-option|/"last (default: 1)"> is ignored, and always off.
The L<wildcards|/"wildcards ?, *, ** & ***"> are transferred as is,
so under expansion the L<C<star>-option|/"star (default: '?,*,**,***')"> is meaningless.

It is useful for debugging to see the pattern differently or
to detect if C<< rewrite=>0 >> changes what is matched, however it shouldn't.

Another use case is feeding the rewritten pattern to another module which
understands basic patterns, but you prefer the fancy ones.

=item C<backslash> (default: '')

In combination with L<C<unchar>|/"unchar (default: '')">,
C<backslash> can be used to allow a preceding backslash (in the text domain)
to disable that special meaning.
Besides that, the backslashed sequence counts as a single char for the
L<C<?>-wildcard|/"wildcards ?, *, ** & ***">. Remember that this option
only inflects wildcards and so the backslash must be written out
in explicit parts of the pattern.

Unstable, and candidate for removal.

  my @v=("ab", "c\nd", "e\\\nf");
  tg_grep '*',@v,{ unchar=>"\n",backslash=>"\n" } # "ab",  "e\\\nf"
  tg_grep '???', @v, { backslash=>1 }             # "c\nd","e\\\nf"
  tg_grep "?\\\\\n?", @v, {backslash=>...}        # "e\\\nf"

The dequoting in pattern space is not changed in any way. Don't allow this
option to confuse you.

=begin :comment

=item C<pattern> (default: C<0>)

declares that the members of the element list are also patterns.
It has no clear semantics, but brings better results for that case.
Only for L<matching|/"textglob_grep PATTERN STRING ...">.

=item C<mell> (default: C<0>)

Switches the C<[]> syntax/semantic to something esoteric. Don't use it.

=item C<default> (default: C<0>)

If set as an option by function calls, all options defined by C<textglob_options> or
by C<use> are ignored.

=end :comment

=back

=head1 ERRORS

The following error messages are defined and are thrown in the respective
condition.

=over 2

=item C<Useless call of >...C< in void context.>

The function is called without having the possibility to return a result.

=item C<Unknown option >...C<.>

The given L<option|/"OPTIONS"> isn't understood.

=item C<Error in option setting: Scope of use declaration not found.>

You have loaded this module by something L<other|/"PITFALLS">
than a normal E<nbsp>C<use> statement.
In such a case a E<nbsp>L<C<textglob_options>|/"Setting of Options">
call can trigger this error. Add an explicitE<nbsp> C<use>E<nbsp> before.
Otherwise you are restricted to feeding the options directly.

=item C<Too much (E<gt>>...C<).>

If L<C<break>|/"break (default: 0 # =off)"> is set, and that limit is reached.

=item C<Step size too wide (E<gt>>...C<).>

If L<C<stepsize>|/"stepsize (default: 0 # =on, without restriction)">
is greater than zero, and that limit is reached.

=item C<Can't load >...<!>

=item C<Unknown module >...C< requested.>

L<C<textglob_foreign>|/"textglob_foreign PATTERN ... CLASS">
doesn't know or has trouble to load the requested module.

=back

=head1 PITFALLS

Because of the L<pragmata-style|perlpragma> capability of lexical-scoped
L<presetting options|/"Setting of Options">,
the following incompatible constructs are not supported in these regards:

=over 2

=item * S<C<{ use Text::Glob::DWIW ...; } ... E<nbsp>>>E<nbsp># outside the scope

=item * S<C<use Text::Glob::DWIW ();E<nbsp> E<nbsp> E<< nbsp
        >> E<nbsp> E<nbsp> E<nbsp>>>E<nbsp># preset feature also turned off

=item * S<C<require Text::Glob::DWIW; E<nbsp> E<nbsp> E<< nbsp
        >> E<nbsp> E<nbsp>>>E<nbsp># not even turned on

=item * S<C<eval "use Text::Glob::DWIW ...;" ...>>

=back

If options are set in such situations, they are B<silently> ignored.
FurthermoreE<nbsp>
L<C<textglob_options>|/"Through the E<nbsp>textglob_optionsE<nbsp> function">E<nbsp>
called in such context and without an existing upper scope declaration will throw
an L<exception|/"ERRORS">.

I<Note:> In the case that some programmatic control over module loading is needed,
you can useE<nbsp> C<use L<if|if> $test, ...> and C<use L<maybe|maybe> ...>.

=head1 CAVEATS

It is assumed that only small patterns are typically used. No optimisation
for speed or against L<memory exhaustion|/"lazy generation"> is considered.

Nearly no error handling and recovery is built in.
If you feed garbage, you get garbage back - most of the time.
This do-the-next-best-thing strategy also means that no forward compatibility exists.
So most likely your code must be adapted for new releases.

X<design>
Instead of a clear design, this module was developed in a more dirty and hackish way.
So regexps and inbound signaling are heavily used.
Mutual recursion is used in such excessivity,
that the resulting code convolution is best called I<higher order
L<spaghetti|https://en.wikipedia.org/wiki/Spagetti%20code>>.

=head1 BUGS

B<Pretty sure> (see L<design caveats|/"CAVEATS"> ;-). E<nbsp>
Anyway, if you catch one, mail how to reproduce it, what you got and what you expected.
And maybe on what you rely on that it doesn't change, as an action-result pair.

=head1 MISSING

This module may have some advantages over
L<TGE|Text::Glob::Expand> and L<SGP|String::Glob::Permute>.
I wrote it to get a glob expander which possesses that particular features.
The only reason why I hacked the matching features in,
was my disliking of such a longish
name like L<Text::Glob::Expand::DWIW|/"NAME">.
So the non expander functionality is a bit rudimentary.

Especially negative character classes would be useful.

=over 2

=item Negative character classes C<[!ab]>

Not yet implemented. Sorry for that.

=item Special Treatment of C<..> & C<.>

C<< tg_grep '.*',{unhead=>'.'} >>E<nbsp> match C<.> and C<..>E<nbsp>E<nbsp>
Most shells allow to suppress this behavior.
You can add an extra layer for filtering these out:

  tg_grep {invert=>1,unchar=>'/'},'**{.,..}**', tg_grep ....

=item Understanding of Path Syntax

=over 2

=item repeating slash

C</usr//tmp/*> (cleanup input instead).
Look at the S<C<< ->cleanup >>>-method which is offered by C<L<Path::Class>>.
This can also help with the following points.

=item current directory C<.>

Replace C</./> with C</> and remove C<./> at start and C</.> at end beforehand.

=item parent directory C<..>

Remove C</*/..> repeatedly and also C<*/..> from the start.

=item volumes

Depending on your needs replace C<'D:foobar'> with
E<nbsp>C<Cwd::getdcwd('D:').'\\foobar'> or C<'D:**\\foobar'>

=back

=item csh'ish empty C<{}>

No special, write explicitly C<\{\}>.

=item Independent capturing support C<(E<nbsp>E<nbsp>)>

exists neither for matching nor expanding.
But an every-C<{}>-and-every-C<[]>-is-a-marker/selector is available.
If the L<C<capture>|/"capture (default: 0)">-option is not enough or too cumbersome,
use L<Regexp|perlre>. This is what they are for.
For expanding only the following, restricted possibilities exists:
the search through the result sets of the
L<C<tree>|/"tree (default: 0)">-option as one option, and
the L<Text::Glob::Expand>-like L<< C<tg_expand(>...C<< )->format(
>>...C<)>|/"textglob_expand(PATTERN ...)->format(FORMAT ...)"
>>E<nbsp> method the other.
But to emphasize: You have to know your pattern because every C<{}> and C<[]>
is marked or selected.

=item lazy generation

If you have to deal with patterns that produce big result sets
(and you don't like to experiment with less stable parts of this module,
like the half-baked for demonstration purposes only functions
L<C<textglob_foreign>|/"textglob_foreign PATTERN ... CLASS"> and
L<C<textglob_expand_lazy>|/"textglob_foreign PATTERN ... ITER_TYPE">),
then sorry this module is definitely B<not> for you.

I thought about it, especially about doing it with index arithmetic,
which allows random access without the need of holding anything
of the result in memory.
See L<C<textglob_foreign>|/"textglob_foreign PATTERN ... CLASS">
for a restricted example with the help of C<L<Set::CartesianProduct::Lazy>>.

Recursive patterns shouldn't be a problem. But for I<magic> ranges basic arithmetic
operations are needed. Also subtractive patterns and wildcards which match the actual
expansion set are at least difficult, maybe even impossible to solve directly.
Of course an extra layer of memory-friendly hole and insertion store are
possible. I hope you understand that this sounds too much as too much work.
So my decision fell on the side of let-it-be instead of do-it-right.

Nevertheless it would open cool opportunities:

  xx_expand('{1-*}[abc]{1-*}{1-*-2}')->[100*Inf**2+100]
  # result of this hypothetical routine would be: 33b1200  ;-)

Anyway I have never used globs for more than generating 1000 elements.
(hmmm, maybe even only 100.
But I also never tried to backup all my files in my inbox along with
all that mails with big attachments in the same place.
So in this 'modern' world my computer usage appears to be untypical.
Ok I'm wrong, the youngsters today store the data on dropbox or skydrive make a
youtube video about it and use then an url shortener for posting on facebook.
This way they can be sure that a north-american suction agency
makes a backup. But with backup generally: how you get it back
when you need it? E<nbsp>
(Ok, maybe an additional backup onto the gmail account helps.))

=item Sorting option

Sorting can be done afterwards, and is an independent functionality -
at least as long as it is not depending on the pattern.
A minimalistic version of partial sorting is added for compatibility reasons
E<nbsp> C<{L<charclass|/"charclass (default: 'def1,sort0')">=E<gt>'sort+'}>.
Details can be found in the options section.

=item Syntax switching

It gives a few popular extensions like globbing of the I<zsh>
or the VMS DCL syntax e.g. triple dot C<...> instead of C<**>.
So this module has its own hard-wired syntax. (yet another. yuck.)
Changing between syntaxes is offered by  C<L<Regexp::Wildcards>> as its main feature.

=item Substitution

Something like
E<nbsp>C<< tg_grep('{**}/{*}.tar.gz',...)->format('%1/new/%2.tgz',{paired=>1}) >>
would be nice, but is E<nbsp>I<B<not>>E<nbsp> implemented.
You can use E<nbsp>L<C<textglob_re>|/"textglob_re PATTERN ...">E<nbsp>
with E<nbsp>L<C<< capture=>1 >>|/"capture (default: 0)">, and then perl's
E<nbsp>L<C<sE<sol>E<sol>E<sol>>|perlop/"Regexp Quote-Like Operators">.E<nbsp>
If you have to handle files then maybe C<L<File::GlobMapper>> fulfills your needs.

=back

=head1 SEE ALSO

=over 2

=item file based and in the CORE

L<glob builtin|perlfunc/glob>, L<File::Glob>

=item renowned, but matcher only

L<Regexp::Wildcards>, L<Text::Glob>, L<Regexp::Shellish>, L<Regexp::SQL::LIKE>

=item expander

L<Text::Glob::Expand>, L<String::Glob::Permute>, L<String::Range::Expand>,
S<L<Regexp::Genex> (Regexp based),>E<nbsp> S<L<Data::Generate> (alienated)>

=item glob-based filename substituter

L<File::GlobMapper> which is part of L<IO::Compress|IO::Compress::Base>,E<nbsp>
L<File::Wildcard>

=item lightweight named capturing matcher

L<Routes::Tiny>

=item list modules with fuze

L<List::Gen> (swiss army knife),
L<Set::CartesianProduct::Lazy> (lightning),
L<Set::CrossProduct> (iterating), L<Iterator::Array::Jagged>,
L<Math::Cartesian::Product>

=item list comprehension

L<List::Maker>, L<List::Gen>

=item and now for something completely different

L<File::HomeDir>, L<File::Which>, L<Path::Class>, L<Cwd>, L<Time::Out>,
L<Algorithm::Permute>, L<Set::Scalar> (a real member of Set::),
L<Interpolation>, L<Regexp::Common>, L<HOP::Stream>,
L<Iterator::Simple> (a worthy representative for all mentioned iterator packages),
L<if> core module, L<maybe> (nearly a philosophy: just try it)

=back

=head1 CONTRIBUTION

Some test files F<t/02-*.t> are borrowed/adapted from other L<mentioned above|/"SEE ALSO">
modules on L<CPAN|http://www.metacpan.org/> which ones also provides C<glob> functionality.

=head1 COPYRIGHT

(c) 2013 Josef. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
