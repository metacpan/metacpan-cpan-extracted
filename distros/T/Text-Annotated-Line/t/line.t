#!perl -w
use Test;

BEGIN {
    plan(tests => 7);
}

# load the module
eval { require Text::Annotated::Line };
ok(length $@ == 0) or warn $@; # 1

# construct a line
my $l1 = new Text::Annotated::Line(
    filename => 'foo',
    linenr   => 1001,
    content  => "foobar\n"
);

# check the fields
ok($l1->{filename},'foo'); # 2
ok($l1->{linenr},1001); # 3
ok($l1->{content},"foobar\n"); # 4

# check the methods
ok($l1->stringify(), "foobar\n"); # 5
ok($l1->stringify_annotated(), "[foo#01001]foobar"); # 6

# check the overloading mechanism
my $str = "";
$str .= $l1;
ok($str,"foobar\n"); # 7

__END__

