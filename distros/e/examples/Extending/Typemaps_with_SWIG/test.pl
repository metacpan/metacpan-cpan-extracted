use ArrayRet;

$, = " ";  # Output record separator. Used by print for separating list elements.
$rl = ArrayRet::test();
print "ArrayRet returned ", @$rl, "\n";
