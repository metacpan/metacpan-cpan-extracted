package testcases::Indexer::isupport;
use strict;
use XAO::Utils;
use XAO::IndexerSupport;
use Data::Dumper;

use base qw(testcases::Indexer::base);

sub test_template_sort {
    my $self=shift;

    srand(97531);

    my @matrix=(
        { # 0
            full        => [ 9,8,7,6,5,4,3,2,1 ],
            partials    => {
                p1 => {
                    list    => [ 5,6,7,8 ],
                    expect  => [ 8,7,6,5 ],
                },
                p2 => {
                    list    => [ 9 ],
                    expect  => [ 9 ],
                },
                p3 => {
                    list    => [ ],
                    expect  => [ ],
                },
                p4 => {
                    list    => [ 9,8,7,6,5,4,3,2,1 ],
                    expect  => [ 9,8,7,6,5,4,3,2,1 ],
                },
                p5 => {
                    list    => [ 7,6,5,8,4,3,2,1,9 ],
                    expect  => [ 9,8,7,6,5,4,3,2,1 ],
                },
                p6 => {
                    list    => [ 7,6,5,8,4,3,2,1,9,10 ],
                    expect  => [ 9,8,7,6,5,4,3,2,1,10 ],
                },
            },
        },
        { # 1
            full        => sub {
                my $count=100000;
                my @data=(0..($count-1));
                for(my $i=0; $i<$count; ++$i) {
                    my $n=int(rand($count));
                    next if $n==$i;
                    ($data[$i],$data[$n])=($data[$n],$data[$i]);
                }
                return \@data;
            },
            partials    => {
                p1 => {
                    list    => [ 12,34,56,78,90,123,234,345,456,567,678,789 ],
                    expect  => [ 90,678,345,567,123,34,78,12,456,56,789,234 ],
                },
                p2 => {
                    list    => [ 9 ],
                    expect  => [ 9 ],
                },
                p3 => {
                    list    => [ ],
                    expect  => [ ],
                },
                p4 => {
                    list    => [ 9,8,7,6,5,4,3,2,1 ],
                    expect  => [ 2,4,9,3,8,1,6,7,5 ],
                },
                p5 => {
                    list    => [ 7,6,5,8,4,3,2,1,9 ],
                    expect  => [ 2,4,9,3,8,1,6,7,5 ],
                },
                p6 => {     # non existent
                    list    => [ 999999 ],
                    expect  => [ 999999 ],
                },
                p7 => {
                    list    => [ 987654,98765,9876,987,98,9 ],
                    expect  => [ 987,9,98,98765,9876,987654 ],
                },
            },
        },
    );

    for(my $bn=0; $bn<@matrix; ++$bn) {
        my $block=$matrix[$bn];
        my $full_data=$block->{full};
        $full_data=&{$full_data}($self) if ref($full_data) eq 'CODE';
        $self->assert(ref($full_data) eq 'ARRAY',
                      "template_sort - block $bn, bad 'full'");

        XAO::IndexerSupport::template_sort_prepare($full_data);

        for my $part_name (keys %{$block->{partials}}) {
            my $part_data=$block->{partials}->{$part_name};
            my $list=$part_data->{list};
            $list=&{$list}($self) if ref($list) eq 'CODE';
            my $expect=$part_data->{expect};
            $expect=&{$expect}($self) if ref($expect) eq 'CODE';
            my $got=XAO::IndexerSupport::template_sort($list);
            my $got_str=join(',',@$got);
            my $expect_str=join(',',@$expect);
            $self->assert($got_str eq $expect_str,
                          "template_sort - block $bn, part $part_name, expected $expect_str, got $got_str");
        }
    }

    XAO::IndexerSupport::template_sort_clear();
    $self->assert(XAO::IndexerSupport::template_sort_position(123) == XAO::IndexerSupport::template_sort_position(345),
                  "template_sort - there is some data after template_sort_clear");

    XAO::IndexerSupport::template_sort_prepare([ 10,20,30,40,50,60 ]);
    my $got=XAO::IndexerSupport::template_sort_position(20);
    $self->assert($got == 1,
                  "template_sort - wrong position, expected 1, got $got");

    XAO::IndexerSupport::template_sort_free();
    $self->assert(XAO::IndexerSupport::template_sort_compare(20,40) == 0,
                  "template_sort - there is some data after template_sort_free");
}

1;
