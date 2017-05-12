use Test::More;

BEGIN {
	eval 'require Moo; 1'
		or plan skip_all => 'This test requires Moo'
}

{
	package Local::Cow;
	use Moo;
	use namespace::sweep;
}

can_ok 'Local::Cow' => qw( new );
ok not $INC{'Moose.pm'};
done_testing;
