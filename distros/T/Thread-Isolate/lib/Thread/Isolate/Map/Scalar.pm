

package Thread::Isolate::Map::Scalar ;

sub TIESCALAR {
  my $class = shift ;
  bless([@_],$class) ;
}

sub FETCH {
  my $this = shift ;
  return $this->[0]->eval($this->[1]) ;
}

sub STORE {
  my $this = shift ;
  return $this->[0]->eval("$this->[1] = \$_[0] ;", $_[0]) ;
}

1;


