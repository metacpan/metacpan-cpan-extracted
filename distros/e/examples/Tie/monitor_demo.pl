use Monitor;

monitor(\$x, "x");
$x = 10;
$x += 30;
unmonitor(\$x);

print "Value after unmonitor: $x \n"; # Should print 40
