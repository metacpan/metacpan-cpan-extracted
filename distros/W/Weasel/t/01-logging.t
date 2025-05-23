#!perl


use Data::Dumper;
use Test::More;

package DummyDriver;

use Data::Dumper;
use Moose;
with 'Weasel::DriverRole';

sub implements {
    return $Weasel::DriverRole::VERSION;
}

sub get_attribute {
    return '';
}

sub tag_name {
    my ($self, $tag) = @_;

    return $tag->{tag};
}

sub find_all {
    my @rv = (
        { tag => 'span' },
        { tag => 'span' },
        );

    return (wantarray) ? @rv : \@rv;
}

sub screenshot {

    return;
}

package main;

use Weasel;
use Weasel::Session;

my @logs;

my $weasel =
    Weasel->new(
        default_session => 'default',
        sessions => {
            default => Weasel::Session->new(
                driver => DummyDriver->new(),
                log_hook => sub {
                    my ($event, $item) = @_;
                    $item = $item->() if ref $item eq 'CODE';
                    push @logs, [ $event, $item ];
                },
                ),
        },
    );

my $session = $weasel->session;

# Specifically test `find_all' due to the complex nature:
#  It can return an array ref in scalar context or an array in
#  list context -- yet the logger will receive an array ref (always)
my @found = $session->page->find_all('span');
my $found = $session->page->find_all('span');

# `find_all' uses a different calling pattern than `screenshot'
# and `is_displayed'
$session->screenshot;

is(scalar(@found), 2, 'Number of tags found equals two');
is(ref $found, 'ARRAY', 'Scalar context returns ARRAYREF');

is_deeply(\@logs,
          [['pre_find_all', 'pattern: span(span)'],
           ['post_find_all', 'found 2 elements for span 
 - Weasel::Element (span)
 - Weasel::Element (span)'],
           ['pre_find_all', 'pattern: span(span)'],
           ['post_find_all', 'found 2 elements for span 
 - Weasel::Element (span)
 - Weasel::Element (span)'],
           ['pre_screenshot', 'screenshot'],
           ['post_screenshot', 'screenshot'],
          ], 'Compare log output');

done_testing;
