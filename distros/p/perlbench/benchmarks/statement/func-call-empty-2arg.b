# Name: Call an empty function with 2 arguments
# Repeat: 20

sub empty {
   my($arg1, $arg2) = @_;
   # do nothng
}

### TEST

empty("foo", 12);

