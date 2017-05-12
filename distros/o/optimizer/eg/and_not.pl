#! perl

package
  optimizer::and_not;

=head1 DESCRIPTION

optimize (and ... NO) to null if no gvsv/padsv, else (dor $x) or do some SvGETMAGIC.
(and NO) is always false, but all SVs must call their mg_get for all SVs before not.

=head1 EXAMPLE1 gvsv

    $ perl -MO=Concise,-exec -e'if ($a and "x" eq "y") { print $s;}'
    1  <0> enter
    2  <;> nextstate(main 3 -e:1) v:{
    3  <$> gvsv(*a) s
    4  <|> and(other->5) sK/1
    5      <$> const(SPECIAL sv_no) s
    6  <|> and(other->7) vK/1
    7      <0> pushmark s
    8      <$> gvsv(*s) s
    9      <@> print vK
    a  <@> leave[1 ref] vKP/REFC

can be optimized to

    1  <0> enter
    2  <;> nextstate(main 3 -e:1) v:{
    3  <$> gvsv(*a) s
    4  <1> dor vK/1
    a  <@> leave[1 ref] vKP/REFC

=head1 EXAMPLE2 padsv

    $ perl -MO=Concise,-exec -e'my $a; if ($a and "x" eq "y") { print $s;}'

    1  <0> enter
    2  <;> nextstate(main 1 -e:1) v:{
    3  <0> padsv[$a:1,4] vM/LVINTRO
...
    4  <;> nextstate(main 4 -e:1) v:{
    5  <0> padsv[$a:1,4] s
    6  <|> and(other->7) sK/1
    7      <$> const[SPECIAL sv_no] s
    8  <|> and(other->9) vK/1
    9      <0> pushmark s
    a      <#> gvsv[*s] s
    b      <@> print vK
    c  <@> leave[1 ref] vKP/REFC

can be optimized to

    1  <0> enter
    2  <;> nextstate(main 1 -e:1) v:{
    3  <0> padsv[$a:1,3] vM/LVINTRO
...
    4  <;> nextstate(main 2 -e:1) v:{
    5  <$> padsv([$a:1,3) s
    6  <1> dor vK/1
    7  <@> leave[1 ref] vKP/REFC

=head1 EXAMPLE3 ok

    $ perl -MO=Concise,-exec -e'if ("x" eq "y" and $a) { print $s;}'

is already optimized to

    1  <0> enter
    2  <;> nextstate(main 3 -e:1) v:{
    3  <@> leave[1 ref] vKP/REFC

=cut

use B::Generate;
use optimizer callback => sub {
  my $o	= shift;
  if (($o->name eq 'gvsv' or $o->name eq 'padsv')
      and ${$o->next} and {$o->next}->name eq 'and'
      and ${$o->next->next} and {$o->next->next}->name eq 'const'
      and {$o->next->next}->sv == B::sv_no
     )
  {
    # change o->next to dor and nullify the rest
    warn "TODO optimize and not ",$o->sv->name;
  }
};

1;
