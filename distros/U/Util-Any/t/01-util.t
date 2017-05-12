use Test::More qw/no_plan/;
use Util::Any ();
use strict;
use Data::Dumper;

require Cwd;
my @cwd_funcs = qw/cwd getcwd fastcwd fastgetcwd chdir abs_path fast_abs_path realpath fast_realpath/;
push @cwd_funcs, qw(getdcwd) if $^O eq 'MSWin32';


@cwd_funcs = sort @cwd_funcs;
my @funcs = sort @{Util::Any::_all_funcs_in_class('Cwd')};
is_deeply(\@funcs, \@cwd_funcs);

my @tests = (
             [
              [ [list => ['any', 'uniq']], {} ],
              [ [], {list => ['any', 'uniq']} ],
             ],
             [
              [ [ scalar => [camelcase => { -as => 'cl' } ], qw/hoge fuga/], {} ],
              [ [qw/hoge fuga/], {scalar => [camelcase => {-as => 'cl'}]} ],
             ],
             [
              [ [ scalar => [camelcase => { -as => 'cl' }],
                  list   => [uniq      => {-as => 'unique'}, 'any', 'max', shuffle => {-as => 'mix'}, 'min' ],
                  qw/aaa  bbb  dcc/,
                ], {} ],
              [ [qw/aaa bbb dcc/],
                {scalar => [camelcase => {-as => 'cl'}],
                 list   => [uniq => {-as => 'unique'}, 'any', 'max',
                            shuffle => {-as => 'mix'}, 'min'
                           ],
                } ],
             ],
             [
              [ [ scalar => {-prefix => 'sc_'}], {} ],
              [ [], {scalar => {-prefix => 'sc_'}} ],
             ],
             [
              [ ['string', list => ['any', 'uniq']], {} ],
              [ [], {string => undef, list => ['any', 'uniq']} ],
             ],
            );

for my $test (@tests) {
  my ($args, $config) = (@{$test->[0]});
  my $ret = $test->[1];
  my ($arg, $want) = Util::Any->_arrange_args($args, $Util::Any::Utils, 'main');
  is_deeply($arg,  $ret->[0]);
  is_deeply($want, $ret->[1]);
}

my @isa = @main::ISA;
Util::Any::_base_import('Util::Any', 'main', '-base');
is($main::ISA[-1], 'Util::Any', 'isa');
ok(!defined &main::_use_import_module, 'not defined');
@main::ISA = @isa;

MODULE:
foreach my $m (['-Exporter'        , 'Exporter'            ],
               ['-ExporterSimple'  , 'Exporter::Simple'    ],
               ['-SubExporter'     , 'Sub::Exporter'       ],
              ) {
  {
    package tmp_package;
    eval "require $m->[1]";
    if($@ =~m{can't locate}i) {
      warn("$m->[1] is not installed\n");
      next MODULE;
    }
  }

  Util::Any::_base_import('Util::Any', 'main', $m->[0]);
  my $file = $m->[1] . '.pm';
  $file =~s{::}{/}g;
  ok(exists $main::INC{$file}, $file);
  is(&main::_use_import_module(), $m->[1], $m->[1]);
  undef &main::_use_import_module;
  @main::ISA = @isa;
}

eval {
  Util::Any::_base_import('Util::Any', 'main', "Hoge");
};

ok($@ =~ /cannot understand/, 'unknown option');
