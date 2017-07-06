#===============================================================================
#
#  DESCRIPTION:  Test lexer
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
#$Id$
package T::WebDAO::Lex;
use strict;
use warnings;
use Test;
use base 'Test';
use Test::More;
use Data::Dumper;
use WebDAO::Lex;

sub setup: Test(setup=>+0) {
    my $t =shift;
    $t->{l} = new WebDAO::Lex::;
    return $t->SUPER::setup(@_);
}
sub t01_split_html:Test(4) {
    my $t= shift;
    my $r1 =  $t->{l}->split_template(<<T1);
  <!-- <wd:pre_fetch>-->
Textext1 Testxt1   <!-- </wd:pre_fetch>-->
  <!-- <wd:post_fetch>-->
  <div id="footer">
   <p>Footer of page</p>
  </div>
  <!-- </wd:post_fetch>-->
T1
   is_deeply [ map{ref($_)} @$r1] , [
          'SCALAR',
          '',
          'SCALAR'
        ], 'tmpl:empty fetch';

    my $r2 =  $t->{l}->split_template(<<T1);
Textext1 Testxt1
  <!-- <wd:fetch>-->
  <div id="footer">
   <p>Footer of page</p>
  </div>
  <!-- </wd:fetch>-->
test
T1
   is_deeply [ map{ref($_)} @$r2] ,[
          'SCALAR',
          'SCALAR',
          'SCALAR'

   ], 'tmpl:only defined wd:fetch in text';

    my $r3 =  $t->{l}->split_template(<<T1);
Textext1 Testxt1
  <!-- <wd:fetch>-->
  <div id="footer">
   <p>Footer of page</p>
  </div>
  <!-- </wd:fetch>-->
T1
   is_deeply [ map{ref($_)} @$r3] ,[
          'SCALAR',
          'SCALAR',
          ''

   ], 'tmpl:empty post';

    my $r4 =  $t->{l}->split_template(<<T1);
Textext1 Testxt1
  <div id="footer">
   <p>Footer of page</p>
  </div>
T1
   is_deeply [ map{ref($_)} @$r4] ,[
          '',
          'SCALAR',
          ''

   ], 'tmpl: empty pre and post';
}

sub  t04_buld_scene :Test(2) {
    my $t =shift;
    my $lex = new WebDAO::Lex:: tmpl=><<T1;
Textext1 Testxt1
  <!-- <wd:fetch>-->
  <div id="footer">
   <p>Footer of page</p>
  </div>
  <!-- </wd:fetch>-->
test
T1
    my $eng2 = new WebDAO::Engine:: session=> $t->{tlib}->get_session, lex=>$lex ;
    is_deeply $t->{tlib}->tree($eng2), {
          ':WebDAO::Engine' => [
                                 {
                                   'none:WebDAO::Lib::RawHTML' => []
                                 },
                                 {
                                   'none:WebDAO::Lib::RawHTML' => []
                                 },
                                 {
                                   'none:WebDAO::Lib::RawHTML' => []
                                 }
                               ]
        },'parse pre, fetch post';

    $eng2->_set_childs_();
    is_deeply $t->{tlib}->tree($eng2),{
          ':WebDAO::Engine' => [
                                 {
                                   'none:WebDAO::Lib::RawHTML' => []
                                 },
                                 {
                                   'none:WebDAO::Lib::RawHTML' => []
                                 }
                               ]
        },'check pre and post';
}

sub t05_wd_in_pre :Test(no_plan) {
    my $t= shift;
    my $lex = new WebDAO::Lex::;
    my $tmpl=<<T1;
Textext1 <wd><object id="ed" class="WebDAO"/></wd>Testxt1
  <!-- <wd:fetch>-->
  <div id="footer">
   <p>Footer of page</p>
  </div>
  <!-- </wd:fetch>-->
test
T1
#    my $eng2 = new WebDAO::Engine:: session=> $t->{tlib}->get_session, lex=>$lex ;
#    diag Dumper $lex->split_template($tmpl);
    diag Dumper $lex->_parsed_template_($tmpl);
#    is_deeply $t->{tlib}->tree($eng2), {

}
1;


