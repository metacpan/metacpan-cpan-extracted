=head1 LIBRARY
Name:	poxargs.pl
Desc:	Common argument parsing logic for POX_parser-derived scripts
=cut
for (my($j, $i) = (-1, 0); $i < @ARGV; $i++) {
  if ($ARGV[$i] eq '-out') {
    if ($i == $#ARGV) {
      croak "-out requires an argument";
    }
    $OUT[$j] = $ARGV[++$i];
  } else {
    $IN[++$j] = $ARGV[$i];
  }
}
for (my $i; $i < @IN; $i++) {
  if (-d $IN[$i]) {
    my $d = $IN[$i];
    my @pox = glob("$d/*.pox");
    splice(@IN, $i, $i+1 - @IN || 1, @pox);
    splice(@OUT, $i, $i+1 - @OUT || 1,
      map {m,$d/(.*)\.pox,;
           $OUT[$i] ? "$OUT[$i]/$1.$OUT_EXT" : "$1.$OUT_EXT"}
          @pox);
    $i += @pox;
  } elsif (!$OUT[$i]) {
    $OUT[$i] = $IN[$i];
    # Change the extension, or add it if it there's no extension:
    $OUT[$i] =~ s/([^.])(?:\..*$|$)/$1.$OUT_EXT/;
    if ($IN[$i] eq $OUT[$i]) {
      if ($IN[$i] =~ /\.html$/) {
        croak "Filename ends in .$OUT_EXT: [$IN[$i]]";
      } else { # It must have been a .foo file
        $OUT[$i] .= ".$OUT_EXT";
      }
    }
  }
}

1;
