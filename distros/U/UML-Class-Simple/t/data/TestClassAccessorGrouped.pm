package TestClassAccessorGrouped;

use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors('single', 'singlefield');
__PACKAGE__->mk_group_accessors('multiple', qw/multiple1 multiple2/);
__PACKAGE__->mk_group_accessors('listref', [qw/lr1name lr1field/], [qw/lr2name lr2field/]);
__PACKAGE__->mk_group_accessors('component_class', 'result_class');

sub overridden {
}

sub blah {
}

1
