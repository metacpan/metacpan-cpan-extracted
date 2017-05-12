
package Thread::Isolate::Map::Array ;

sub TIEARRAY {
  my $class = shift ;
  bless([@_],$class) ;
}

sub FETCH {
  my $this = shift ;
  return $this->[0]->eval("\$$this->[2]\[$_[0]]") ;
}

sub STORE {
  my $this = shift ;
  return $this->[0]->eval("\$$this->[2]\[$_[0]] = \$_[0] ;" , $_[1]) ;
}

sub FETCHSIZE {
  my $this = shift ;
  return $this->[0]->eval("scalar $this->[1]") ;
}

sub STORESIZE {
  my $this = shift ;
  return $this->[0]->eval(" $#{$this->[2]} = $_[0] ") ;
}

sub CLEAR {
  my $this = shift ;
  return $this->[0]->eval("$this->[1] = ()") ;
}

sub POP {
  my $this = shift ;
  return $this->[0]->eval("pop($this->[1])") ;
}

sub PUSH {
  my $this = shift ;
  return $this->[0]->eval("push($this->[1] , \@_)" , @_) ;
}

sub SHIFT {
  my $this = shift ;
  return $this->[0]->eval("shift($this->[1])") ;
}

sub UNSHIFT {
  my $this = shift ;
  return $this->[0]->eval("unshift($this->[1] , \@_)" , @_) ;
}

sub SPLICE {
  my $this = shift ;

  my $size = $this->FETCHSIZE ;

  my $offset = @_ ? shift(@_) : 0 ;
  $offset += $size if $offset < 0 ;
  
  my $length = @_ ? shift(@_) : $size - $offset ;
  
  return $this->[0]->eval("splice($this->[1] , $offset , $length , \@_)" , @_) ;
}

sub EXISTS {
  my $this = shift ;
  return $this->[0]->eval("exists \$$this->[2]\[$_[0]]") ;
}

sub DELETE {
  my $this = shift ;
  return $this->[0]->eval("delete \$$this->[2]\[$_[0]]") ;
}

1;


