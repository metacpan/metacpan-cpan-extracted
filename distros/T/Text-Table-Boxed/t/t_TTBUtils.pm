package t_TTBUtils;

# Common file used by tests for Text::Table::Boxed

require Exporter;
use parent 'Exporter';

our @EXPORT = qw/cx2let mk_table/;

use t_Common qw/oops btw btwN/; # strict, warnings, Carp, oops etc.

use Text::Table::Boxed;

no warnings 'experimental'; use feature 'signatures';

sub cx2let :prototype(_) {
  my $cx = shift;
  my $ABC="A"; ++$ABC for (1..$cx); return $ABC
}

sub mk_table(%opts) {
  my $num_data_cols = delete($opts{num_data_cols}) // 3;
  my $num_pic_cols  = delete($opts{num_pic_cols}) // ($num_data_cols < 3 ? 2 : 3);
  my $num_pic_rows  = delete($opts{num_pic_rows}) // 2;
  my $num_body_rows = delete($opts{num_body_rows}) // 1;
  my $nobox         = delete($opts{nobox});
  my $nopad         = delete($opts{nopad});
  foreach (keys %opts) { oops "Wrong key '$_'" }

  #   normal:      nopad:     nobox:      nopad & nobox:
  #   +-------+    +---+
  #   | c | c |    |c|c|      "c | c"         "c|c"
  #   +-------+    +---+
  my $picwidth = ($num_pic_cols*($nopad ? 2 : 4) - 1)
                 + ($nobox ? 0 : 2);

  my sub _mkline($lhs, $colstr, $rhs, $padch=" ", $sep="|") {
     #($nobox ? "" : $lhs.($nopad ? "" : " "))
     ($nobox ? "" : $lhs)
    .join($sep, (($nopad ? $colstr : "${padch}${colstr}${padch}") x $num_pic_cols))
    #.($nobox ? "" : ($nopad ? "" : " ").$rhs)
    .($nobox ? "" : $rhs)
    ."\n"
  }
  my $datarow_line = _mkline("|", "c", "|");
  my $top_line     = _mkline("[", "-", "]", "-", "+");
  my $aftert_line  = _mkline("+", "T", "+", "T", "+");
  my $midsep_line  = _mkline("+", "m", "+", "m", "+");
  my $bot_line     = _mkline("<", "b", ">", "b", "+");
  my @picture = (
      ($nobox ? () : ($top_line)),
      ($num_pic_rows == 0 ? () :
        ( $datarow_line,
          ($num_pic_rows >= 3 ? $aftert_line :
           $num_pic_rows == 2 ? $midsep_line : ()
          ),
          (map{ ($datarow_line, $midsep_line) } 2..$num_pic_rows-1
          ),
          ($num_pic_rows >= 2 ? ($datarow_line) : ()),
        )
      ),
      ($nobox ? () : ($bot_line)),
  );
  my $tb = Text::Table::Boxed->new({
      columns => [ map{ "Title-A$_" } 1..$num_data_cols ],
      picture => \@picture
  });
  # Add data rows
  for my $brx (0..$num_body_rows-1) {
    $tb->add(map{
               my $str = "Data-".cx2let($brx+1).($_+1); # e.g. Data-B1
               $_ == 0 ? $str :
               $_ == 1 ? join("", $str, map{"\nextra wide line$_"} 2..$_+1) :
                         join("", $str, map{"\nline$_"} 2..$_+1)
             }0..$num_data_cols-1
            );
  }
  return $tb
}

1;
