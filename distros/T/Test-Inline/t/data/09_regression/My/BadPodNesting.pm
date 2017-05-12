package My::BadPodNesting;

print "Hello World!\n";

=pod

=begin testing foo

This is a test

=begin testing bar

oopsi, forgot the previous =end tag

=end testing

=cut
