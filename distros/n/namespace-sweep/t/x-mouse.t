use Test::More;

BEGIN {
	eval 'require Mouse; 1'
		or plan skip_all => 'This test requires Moose'
}

sub X::test_method { 1 };

{
	package Local::Antlers;
	use Mouse;
	use namespace::sweep;
	BEGIN {
		__PACKAGE__->meta->add_method(method => \&X::test_method);
	}
}

can_ok 'Local::Antlers' => qw( new method );
done_testing;
