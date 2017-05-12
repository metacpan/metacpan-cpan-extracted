package Test::WWW::StaticBlog::Types::TestClass;

use Moose;

use WWW::StaticBlog::Types qw(
    DateTime
    TagList
);

has tag => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => TagList,
    coerce  => 1,
    handles => {
        all_tags     => 'elements',
        clear_tags   => 'clear',
        num_tags     => 'count',
        _sorted_tags => 'sort',
    },
);

sub sorted_tags
{
    my $self = shift;
    return sort { $a->name() cmp $b->name() } $self->all_tags();
}

has datetime => (
    is        => 'rw',
    isa       => DateTime,
    coerce    => 1,
    clearer   => 'clear_datetime',
    predicate => 'has_datetime',
);

package Test::WWW::StaticBlog::Types;

use parent 'Test::Mini::TestCase';
use Test::Mini::Assertions;

use WWW::StaticBlog::Tag ();

sub test_split_tags_on_whitespace
{
    my $types = Test::WWW::StaticBlog::Types::TestClass->new(
        tag => 'there should be several tags',
    );

    assert_eq(
        [ $types->sorted_tags() ],
        [ map { WWW::StaticBlog::Tag->new($_) } qw(
            be
            several
            should
            tags
            there
        )],
    );
}

sub test_split_tags_on_whitespace_with_quoting
{
    my $types = Test::WWW::StaticBlog::Types::TestClass->new(
        tag => 'there should be "several tags"',
    );

    assert_eq(
        [ $types->sorted_tags() ],
        [ map { WWW::StaticBlog::Tag->new($_) } (
            'be',
            'several tags',
            'should',
            'there',
        )],
    );
}

sub test_coerce_datetime_from_str
{
    my $types = Test::WWW::StaticBlog::Types::TestClass->new(
        datetime => '2010-03-22 19:01:10',
    );

    assert_isa(
        $types->datetime(),
        'DateTime',
    );

    assert_eq(
        $types->datetime()->iso8601(),
        '2010-03-22T19:01:10',
    );
}

1;
