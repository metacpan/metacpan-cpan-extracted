package WebService::GData::Iterator;
use strict;
sub TIEARRAY {
    my $class = shift;

    my $this  =  bless {
        ARRAY    => [],
        SETTER   => shift() || sub { return (shift(),shift())},
        GETTER   => shift() || sub { return shift()}
    }, $class;
    $this->pointer=0;
    
    return $this;
 }

sub ARRAY {
	my $this = shift;
	$this->{ARRAY};
	
}

sub FETCH {
    my ($this,$index) = @_;
    $this->pointer=$index;   
    return undef if($this->pointer >= $this->total && $this->total!=0);

    if(my $code = $this->{GETTER}){
       $this->ARRAY->[$this->pointer]=$code->($this->ARRAY->[$this->pointer]);
    }

    return $this->ARRAY->[$this->pointer];
}
 
sub pointer:lvalue {
	my $this = shift;
     $this->{pointer};
}


sub STORE {
    my $this = shift;
    my( $index, $value ) = @_;
    
    ($index,$value)=$this->{SETTER}->($index,$value);
    
    $this->ARRAY->[$index] = $value;
}
 
sub FETCHSIZE {
    my $this = shift;

    if($this->pointer>=$this->total || $this->pointer<0){

        $this->pointer=0;
        return 0;
    }
    return $this->total;
}
 
sub total {
    my $this = shift;
    return scalar (@{$this->ARRAY});
}
 
sub STORESIZE {

}
sub EXTEND {

}
 
sub EXISTS {
    my ($this,$index) = @_;
    if(! defined $this->ARRAY->[$index]){
        $this->pointer=0;
        return 0;
    }
    return 1;
}
 
sub DELETE {
     my ($this,$index) = @_;
     return $this->STORE( $index, '' );
}
 
sub CLEAR {
     my $this = shift;
 #    return $this->ARRAY = [];
}
 
####ARRAY LIKE BEHAVIOR####
sub PUSH {
     my $this = shift;
     my @list = @_;
     my $last = $this->total();
     $this->STORE( $last + $_, $list[$_] ) foreach 0 .. $#list;
     return $this->total();
}
 
sub POP {
     my $this = shift;
     return pop @{$this->ARRAY};
}
 
sub SHIFT {
     my $this = shift;
     return shift @{$this->ARRAY};
} 

sub UNSHIFT {
    my $this = shift;
    my @list = @_;
    my $size = scalar @list;
   
    @{$this->ARRAY}[ $size .. $#{$this->ARRAY} + $size ]
    = @{$this->ARRAY};
   
    $this->STORE( $_, $list[$_] ) foreach 0 .. $#list;
}

sub SPLICE {
     my $this = shift;
     my $offset = shift || 0;
     my $length = shift || $this->FETCHSIZE() - $offset;
     my @list = ();
     if ( @_ ) {
         tie @list, ref $this;
         @list = @_;
     }
     return splice @{$this->ARRAY}, $offset, $length, @list;
}
 
'The earth is blue like an orange.';
