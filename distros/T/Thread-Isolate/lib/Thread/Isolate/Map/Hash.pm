

package Thread::Isolate::Map::Hash ;

sub TIEHASH {
  my $class = shift ;
  bless([@_],$class) ;
}

sub FETCH {
  my $this = shift ;
  return $this->[0]->eval("\$$this->[2]\{\$_[0]}",$_[0]) ;
}

sub STORE {
  my $this = shift ;
  return $this->[0]->eval("\$$this->[2]\{\$_[0]} = \$_[1]",$_[0],$_[1]) ;
}

sub CLEAR {
  my $this = shift ;
  return $this->[0]->eval("$this->[1] = ()") ;
}

sub FIRSTKEY {
  my $this = shift ;
  return $this->[0]->eval("scalar( keys $this->[1] ); each $this->[1] ;") ;
}

sub NEXTKEY {
  my $this = shift ;
  return $this->[0]->eval("each $this->[1] ;") ;
}

sub EXISTS {
  my $this = shift ;
  return $this->[0]->eval("exists \$$this->[2]\{\$_[0]}",$_[0]) ;
}

sub DELETE {
  my $this = shift ;
  return $this->[0]->eval("delete \$$this->[2]\{\$_[0]}",$_[0]) ;
}

1;


