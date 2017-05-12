package autovivification::TestRequired5::b0;
sub get {
 eval 'require autovivification::TestRequired5::c0';
}
1;
