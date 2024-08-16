package YATT::Lite::Macro;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

# use YATT::Lite::Macro;

use YATT::Lite::Core qw(Template Part Widget Page Action);
use YATT::Lite::Constants;
use YATT::Lite::Util qw(globref lexpand);

our @EXPORT = qw(Macro lexpand);
our @EXPORT_OK = (@EXPORT, qw(Template Part Widget Page Action));

# Use cases:
# (a) .htyattrc.pl から呼ばれて、 MyYATT::INST1::CGEN_perl に macro_zzz を足す。
# (b) MyYATT.pm から呼ばれて、 MyYATT::CGEN_perl に... こっちがまだだよね。
# sub cgen_perl () {'...CGEN_perl'} を設定するべきか否か。<= ロード順問題を抱えるよね。

sub define_Macro {
  if (@_ >= 3) {
    croak "API is changed: type must be specified in Macro [\$type => \$name]";
  }
  my ($myPack, $callpack) = @_;
  my $macro = globref($callpack, 'Macro');
  unless (*{$macro}{CODE}) {
    *$macro = sub {
      my ($nameSpec, $sub) = @_;
      my ($type, $name) = ref $nameSpec ? @$nameSpec : (perl => $nameSpec);

      my $destns = $callpack->ensure_cgen_for($type, $callpack);

      *{globref($destns, "macro_$name")} = $sub;
    };
  }
}

sub default_export { @EXPORT }

sub import {
  my ($pack, @opts) = @_;
  @opts = $pack->default_export unless @opts;
  my $callpack = caller;
  my (%opts, @task);
  foreach my $exp (@opts) {
    my ($name, @rest) = split /=/, $exp, 2;
    if (my $sub = $pack->can("define_$name")) {
      push @task, [$sub, @rest];
    } elsif (grep {$_ eq $exp} @EXPORT_OK) {
      *{globref($callpack, $exp)} = *{globref($pack, $exp)};
    } else {
      croak "Unknown export spec: $exp";
    }
  }
  foreach my $task (@task) {
    my ($sub, @rest) = @$task;
    $sub->($pack, $callpack, @rest);
  }
}

1;
