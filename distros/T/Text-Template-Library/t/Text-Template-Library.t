# -*- perl -*-

use Test::More tests => 13;
#use Test::More 'no_plan';
BEGIN { use_ok('Text::Template::Library') };

my $template=<<'TMPL';
hu
[% define m1 %]
  blub [% $prefix.$_.$suffix %] blub
[% /define %]

hu
[%
  for (@arr) {
    $OUT.=$Text::Template::Library::T->library('m1', (defined $usep ? (PACKAGE=>$usep) : ()));
  }
  '';
 %]blah
TMPL

my %cache;
my $tmpl=Text::Template::Library->new
  (DELIMITERS=>[qw/[% %]/],
   EVALCACHE=>\%cache,
   TYPE=>'STRING',
   SOURCE=>$template);

our ($prefix, $suffix)=('','');
our @arr=(1,2,3);
$out=$tmpl->fill_in;

ok $out eq <<'TMPL', "at line ".__LINE__;
hu
hu
  blub 1 blub
  blub 2 blub
  blub 3 blub
blah
TMPL

@arr=qw/aa bb cc dd/;
my $out='';
ok $tmpl->fill_in(OUTPUT=>sub{$out.=$_[0]}) eq 1, "at line ".__LINE__;
ok $out eq <<'TMPL', "at line ".__LINE__;
hu
hu
  blub aa blub
  blub bb blub
  blub cc blub
  blub dd blub
blah
TMPL

{
  no warnings 'once';
  ($Q::prefix, $Q::suffix)=('','');
  @Q::arr=qw/3 4 5/;
}
$out=$tmpl->fill_in(PACKAGE=>'Q');
ok $out eq <<'TMPL', "at line ".__LINE__;
hu
hu
  blub 3 blub
  blub 4 blub
  blub 5 blub
blah
TMPL

($prefix, $suffix)=qw/>> <</;
$out=$tmpl->fill_in(PACKAGE=>'Q', HASH=>{usep=>'main'});
ok $out eq <<'TMPL', "at line ".__LINE__;
hu
hu
  blub >>3<< blub
  blub >>4<< blub
  blub >>5<< blub
blah
TMPL

$template=<<'TMPL';
hu


[% define m1 %]
  >>
[%

$x::x=
          1/0
       %]
  <<
[% /define %]


hu
[%
  for (@arr) {
    $OUT.=$Text::Template::Library::T->library('m1');
  }
  '';
 %]
blah
TMPL
my $expected_line_number=($]<5.008009 ? 10 : 8);

@arr=qw/1 2/;
$tmpl=Text::Template::Library->new
  (DELIMITERS=>[qw/[% %]/],
   EVALCACHE=>\%cache,
   TYPE=>'STRING',
   FILENAME=>'my.tmpl',
   SOURCE=>$template);

$out=$tmpl->fill_in(FILENAME=>'huhu.tmpl');
ok $out eq <<"TMPL", "at line ".__LINE__;
hu


hu
  >>
Program fragment delivered error ``Illegal division by zero at huhu.tmpl line $expected_line_number.''
  <<
  >>
Program fragment delivered error ``Illegal division by zero at huhu.tmpl line $expected_line_number.''
  <<

blah
TMPL

$out=$tmpl->fill_in;
ok $out eq <<"TMPL", "at line ".__LINE__;
hu


hu
  >>
Program fragment delivered error ``Illegal division by zero at my.tmpl line $expected_line_number.''
  <<
  >>
Program fragment delivered error ``Illegal division by zero at my.tmpl line $expected_line_number.''
  <<

blah
TMPL
$tmpl=Text::Template::Library->new
  (DELIMITERS=>["\n[%", "%]\n"],
   EVALCACHE=>\%cache,
   TYPE=>'STRING',
   FILENAME=>'my.tmpl',
   SOURCE=>$template);

$out=$tmpl->fill_in;
ok $out eq <<"TMPL", "at line ".__LINE__;
hu

hu  >>Program fragment delivered error ``Illegal division by zero at my.tmpl line $expected_line_number.''  <<  >>Program fragment delivered error ``Illegal division by zero at my.tmpl line $expected_line_number.''  <<blah
TMPL

$template=<<'TMPL';
begin
{use Text::Template::Library qw/fill_in_module/;''}
{ define m1 }
  >>{$1=1}<<
{ /define }

middle

{ define m2 }
  >>{my $x=0; 1/$x}<<
{ /define }

end

top
{OUT $Text::Template::Library::T->library('m2') for(1..2)}
{OUT $Text::Template::Library::T->library('m1') for(1..2)}
between
{OUT Text::Template::Library::fill_in_module('m2') for(1..2)}
{OUT fill_in_module('m1') for(1..2)}
bottom
TMPL

$tmpl=Text::Template::Library->new
  (EVALCACHE=>\%cache,
   TYPE=>'STRING',
   FILENAME=>'my.tmpl',
   SOURCE=>$template);

$out=$tmpl->fill_in;
ok $out eq <<'TMPL', "at line ".__LINE__;
begin

middle

end

top
  >>Program fragment delivered error ``Illegal division by zero at my.tmpl line 10.''<<
  >>Program fragment delivered error ``Illegal division by zero at my.tmpl line 10.''<<

  >>Program fragment delivered error ``Modification of a read-only value attempted at my.tmpl line 4.''<<
  >>Program fragment delivered error ``Modification of a read-only value attempted at my.tmpl line 4.''<<

between
  >>Program fragment delivered error ``Illegal division by zero at my.tmpl line 10.''<<
  >>Program fragment delivered error ``Illegal division by zero at my.tmpl line 10.''<<

  >>Program fragment delivered error ``Modification of a read-only value attempted at my.tmpl line 4.''<<
  >>Program fragment delivered error ``Modification of a read-only value attempted at my.tmpl line 4.''<<

bottom
TMPL

$template=<<'TMPL';
[[ define row ]]
||[[ for my $s (@$_) {
        local $_=$s;
        OUT Text::Template::Library::fill_in_module 'cell';
      } ]]|
[[ /define ]]
[[ define cell ]]
 [[ OUT sprintf "%05s", $_ ]] |[[ /define ]]
now follows table output:

[[
  OUT Text::Template::Library::fill_in_module 'row' for(@list);
]]
TMPL

$tmpl=Text::Template::Library->new
  (EVALCACHE=>\%cache,
   DELIMITERS=>[qw/[[ ]]/],
   TYPE=>'STRING',
   FILENAME=>'list.tmpl',
   SOURCE=>$template);

$out=$tmpl->fill_in(HASH=>{list=>[[1,2,3], [qw/a aa aaa/], [qw/bbb aa c/]]});
ok $out eq <<'TMPL', "at line ".__LINE__;
now follows table output:

|| 00001 | 00002 | 00003 ||
|| 0000a | 000aa | 00aaa ||
|| 00bbb | 000aa | 0000c ||

TMPL

$template=<<'TMPL';
[[ define row ]]
||[[ for my $s (@$_) {
        local $_=$s;
        OUT module 'cell';
      } ]]|
[[ /define ]]
[[ define cell ]]
 [[ OUT sprintf "%05s", $_ ]] |[[ /define ]]
now follows table output:

[[
  OUT module 'row' for(@list);
]]
TMPL

$tmpl=Text::Template::Library->new
  (EVALCACHE=>\%cache,
   DELIMITERS=>[qw/[[ ]]/],
   TYPE=>'STRING',
   FILENAME=>'list.tmpl',
   SOURCE=>$template);

{ no warnings 'once'; *Q::module=\&Text::Template::Library::fill_in_module; }
$out=$tmpl->fill_in(PACKAGE=>'Q',
		    HASH=>{list=>[[1,2,3], [qw/a aa aaa/], [qw/bbb aa c/]]});
ok $out eq <<'TMPL', "at line ".__LINE__;
now follows table output:

|| 00001 | 00002 | 00003 ||
|| 0000a | 000aa | 00aaa ||
|| 00bbb | 000aa | 0000c ||

TMPL

my $template2=<<'TMPL';
table1
[[ module 'm', HASH=>{i=>0} ]]

table2
[[ module 'm', HASH=>{i=>1} ]]

[[ define m ]]
>>>[[
Text::Template::Library->new(DELIMITERS=>[qw/[[ ]]/],
                             TYPE=>'string',
                             FILENAME=>'table.tmpl',
                             SOURCE=>$template,
                            )->fill_in(PACKAGE=>'Q',
                                       HASH=>{list=>$lists[$i]});
]]<<<[[ /define ]]
footer
TMPL

$tmpl=Text::Template::Library->new
  (EVALCACHE=>\%cache,
   DELIMITERS=>[qw/[[ ]]/],
   TYPE=>'STRING',
   FILENAME=>'list.tmpl',
   SOURCE=>$template2);

$out=$tmpl->fill_in(PACKAGE=>'Q',
		    HASH=>{
			   template=>$template,
			   lists=>[
				   [[1,2,3], [qw/a aa aaa/], [qw/bbb aa c/]],
				   [[qw/bbb aa c/], [1,2,3], [qw/a aa aaa/]],
				  ],
			  });

ok $out eq <<'TMPL', "at line ".__LINE__;
table1
>>>now follows table output:

|| 00001 | 00002 | 00003 ||
|| 0000a | 000aa | 00aaa ||
|| 00bbb | 000aa | 0000c ||

<<<

table2
>>>now follows table output:

|| 00bbb | 000aa | 0000c ||
|| 00001 | 00002 | 00003 ||
|| 0000a | 000aa | 00aaa ||

<<<

footer
TMPL

#warn "\n#############################################\n";
#warn "\n\n>>>\n$out<<<\n";
#use Data::Dumper; warn Dumper(keys %cache);
