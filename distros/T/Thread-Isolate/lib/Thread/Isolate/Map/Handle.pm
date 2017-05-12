
package Thread::Isolate::Map::Handle ;

sub TIEHANDLE {
  my $class = shift ;
  my @args = ( shift(@_) , shift(@_) , shift(@_) ) ;
  my $this = bless(\@args,$class) ;
  $this->OPEN(@_) if @_ ;
  $this->flush_buffer if !@_ ;
  return $this ;
}

sub flush_buffer {
  my $this = shift ;
  $this->[0]->eval("my \$sel = select($this->[2]) ; \$|=1 ; select(\$sel) ;") ;
  my $sel = select($this->[2]) ; $|=1 ; select($sel) ;
}

sub EOF {
  my $this = shift ;
  return $this->[0]->eval("eof($this->[2])") ;
}

sub TELL {
  my $this = shift ;
  return $this->[0]->eval("tell($this->[2])") ;
}

sub FILENO {
  my $this = shift ;
  return $this->[0]->eval("fileno($this->[2])") ;
}

sub SEEK {
  my $this = shift ;
  return $this->[0]->eval("seek($this->[2] , \$_[0] , \$_[1])" , @_) ;
}

sub CLOSE {
  my $this = shift ;
  return $this->[0]->eval("close($this->[2])") ;
}

sub BINMODE {
  my $this = shift ;
  return $this->[0]->eval("binmode($this->[2])") ;
}

sub OPEN {
  my $this = shift ;
  
  my $ret ;
  if ( @_ == 0 ) {
    $ret = $this->[0]->eval("open($this->[2])") ;  
  }
  elsif ( @_ == 1 ) {
    $ret = $this->[0]->eval("open($this->[2] , \$_[0])" , @_) ;  
  }
  elsif ( @_ == 2 ) {
    $ret = $this->[0]->eval("open($this->[2] , \$_[0] , \$_[1])" , @_) ;  
  }
  
  ## Need to flush since we can't flush from outside and we can lose data if not closed explicity:
  $this->flush_buffer ;
  
  return $ret ;
}

sub READ {
  my $this = shift ;
  return $this->[0]->eval("read($this->[2] , \$_[0] , \$_[1])" , @_) ;  
}

sub READLINE {
  my $this = shift ;
  return $this->[0]->eval("scalar(readline($this->[2]))") ;
}

sub GETC {
  my $this = shift ;
  return $this->[0]->eval("getc($this->[2])") ;
}

sub PRINT {
  my $this = shift ;
  return $this->[0]->eval("print $this->[2] \@_ ;" , @_) ;
}

sub PRINTF {
  my $this = shift ;
  return $this->[0]->eval("print $this->[2] sprintf(shift(@_) , @_) ;" , @_) ;
}

sub WRITE {
  my $this = shift ;
  return $this->[0]->eval("write($this->[2] , \$_[0] , \$_[1] , \$_[2])" , @_) ;  
}

sub DESTROY {
  my $this = shift ;
  $this->CLOSE ;
}


1;


