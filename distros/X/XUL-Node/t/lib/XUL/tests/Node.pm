package XUL::tests::Node;

use strict;
use warnings;
use Carp;
use Test::More;
use Test::Exception;
use XUL::tests::Assert;
use XUL::Node;# qw(XUL::tests::CustomNode);

use base 'Test::Class';

sub subject_class { 'XUL::Node' }

# attributes ------------------------------------------------------------------

sub set_attribute: Test {
	my ($self, $subject) = @_;
	$subject->set_attribute(tag => 'Label');
	is $subject->get_attribute('tag'), 'Label';
}

sub set_attribute_direct: Test {
	my ($self, $subject) = @_;
	$subject->_set_attribute(tag => 'Label');
	is $subject->get_attribute('tag'), 'Label';
}

sub set_attribute_autoload: Test {
	my ($self, $subject) = @_;
	$subject->tag('Label');
	is $subject->tag, 'Label';
}

sub set_attribute_direct_autoload: Test {
	my ($self, $subject) = @_;
	$subject->_tag('Label');
	is $subject->tag, 'Label';
}

sub unknown_autoload: Test {
	my ($self, $subject) = @_;
	throws_ok { $subject->_ILLEGAL } qr/no message called \[_ILLEGAL\]/;
}

# composition -----------------------------------------------------------------

sub add_child: Test {
	my ($self, $subject) = @_;
	$subject->set_attribute(tag => 'Box');
	my $child = $self->make_subject(tag => 'Label');
	$subject->add_child($child);
	is_deeply [$subject->children], [$child];
}

sub set_parent_node: Test {
	my ($self, $subject) = @_;
	my $child = $subject->add_child(Label);
	is $child->get_parent_node, $subject;
}

sub add_child_at_index: Test {
	my ($self, $subject) = @_;
	$subject->set_attribute(tag => 'Box');
	my $child1 = $self->make_subject(tag => 'Label');
	my $child2 = $self->make_subject(tag => 'Label');
	my $child3 = $self->make_subject(tag => 'Label');
	$subject->add_child($child1);
	$subject->add_child($child2);
	$subject->add_child($child3, 1);
	is_deeply [$subject->children], [$child1, $child3, $child2];
}

sub create_with_children: Test {
	my $self    = shift;
	my $child1  = $self->make_subject(tag => 'Label');
	my $child2  = $self->make_subject(tag => 'Label');
	my $subject = $self->make_subject(tag => 'Box', $child1, $child2);
	is_deeply [$subject->children], [$child1, $child2];
}

sub create_on_parent: Test {
	my ($self, $subject) = @_;
	$subject->tag('Box');
	$subject->add_child(Label value => 'bar');
	is_xul_xml $subject, <<AS_XML;
<Box>
   <Label value="bar"/>
</Box>
AS_XML
}

sub create_with_nice_api: Test {
	my $self = shift;
	my $subject =
		Box(ORIENT_HORIZONTAL,
			Label(value => 'foo'),
			Box(ORIENT_VERTICAL,
				Label(value => 'a label'),
				Button(value => 'a button'),
			),
		);
	is_xul_xml $subject, <<AS_XML;
<Box orient="horizontal">
   <Label value="foo"/>
   <Box orient="vertical">
      <Label value="a label"/>
      <Button value="a button"/>
   </Box>
</Box>
AS_XML
}

sub destroy: Test(4) {
	my ($self, $subject) = @_;
	$subject->add_child(my $child = Label);
	ok !$subject->is_destroyed, 'subject exists';
	ok !$child->is_destroyed, 'child exists';
	$subject->destroy;
	ok $subject->is_destroyed, 'subject destroyed';
	ok $child->is_destroyed, 'child destroyed';
}

sub remove_child: Test(2) {
	my ($self, $subject) = @_;
	$subject->add_child(my $child = Label);
	$subject->remove_child($child);
	is $subject->child_count, 0, 'child count decreased';
	ok $child->is_destroyed, 'child removed';
}

sub remove_all_children: Test {
	my ($self, $subject) = @_;
	$subject->add_child(Label) for 1..3;
	$subject->remove_all_children;
	is $subject->child_count, 0;
}

1;