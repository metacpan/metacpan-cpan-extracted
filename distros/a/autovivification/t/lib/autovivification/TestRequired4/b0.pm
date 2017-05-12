package autovivification::TestRequired4::b0;
sub get {
 eval 'require autovivification::TestRequired4::c0';
}
1;
