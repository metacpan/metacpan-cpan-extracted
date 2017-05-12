package YATT::Lite::Macro;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

# use YATT::Lite::Macro;
# use YATT::Lite::Macro qw(Macro=perl);
# use YATT::Lite::Macro qw(Macro=js);

use YATT::Lite::Core qw(Template Part Widget Page Action);
use YATT::Lite::Constants;
use YATT::Lite::Util qw(globref lexpand);

our @EXPORT = qw(Macro lexpand);
our @EXPORT_OK = (@EXPORT, qw(Template Part Widget Page Action));

# Use cases:
# (a) .htyattrc.pl から呼ばれて、 MyApp::INST1::CGEN_perl に macro_zzz を足す。
# (b) MyApp.pm から呼ばれて、 MyApp::CGEN_perl に... こっちがまだだよね。
# sub cgen_perl () {'...CGEN_perl'} を設定するべきか否か。<= ロード順問題を抱えるよね。

sub define_Macro {
  my ($myPack, $callpack, $type) = @_;
  my $destns = join('::', $callpack, 'CGEN_'.($type || 'perl'));
  my $macro = globref($callpack, 'Macro');
  unless (*{$macro}{CODE}) {
    *$macro = sub {
      my ($name, $sub) = @_;
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
    my ($name, $rest) = split /=/, $exp, 2;
    if (my $sub = $pack->can("define_$name")) {
      push @task, [$sub, $rest];
    } elsif (grep {$_ eq $exp} @EXPORT_OK) {
      *{globref($callpack, $exp)} = *{globref($pack, $exp)};
    } else {
      croak "Unknown export spec: $exp";
    }
  }
  foreach my $task (@task) {
    my ($sub, $rest) = @$task;
    $sub->($pack, $callpack, $rest);
  }
}

1;
