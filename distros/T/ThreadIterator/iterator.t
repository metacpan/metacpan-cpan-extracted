use Thread::Iterator 'coroutine';

$c = coroutine {
    my $obj = shift;
    for (my $i = 0; $i < 10; $i++) {
	$obj->provide($i);
   }
};

for ($j = 0; $j < 12; $j++) {
    printf "iterator is %s, ", $c->alive ? "alive" : "dead";
    my $val = $c->iterate;
    printf "value is %s\n", defined($val) ? $val : "undefined";
}
