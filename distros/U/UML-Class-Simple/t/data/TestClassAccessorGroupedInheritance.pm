package TestClassAccessorGroupedInheritance;

use base 'TestClassAccessorGrouped';

__PACKAGE__->mk_group_accessors('single', 'sub_singlefield');
__PACKAGE__->mk_group_accessors('multiple', qw/sub_multiple1
sub_multiple2/);
__PACKAGE__->mk_group_accessors('listref', [qw/sub_lr1name
sub_lr1field/], [qw/sub_lr2name sub_lr2field/]);
__PACKAGE__->mk_group_accessors('component_class', 'sub_result_class');

sub overridden {
}

sub subclass_only {
}

1

