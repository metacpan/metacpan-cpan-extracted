
use strict;
use warnings;

package MyTestParser;
use Test::More;    # last test to print
use Moose;
extends 'Text::Parser';

sub save_record {
    my $self = shift;
    my $nf   = scalar( split /\s+/, $_[0] );
    is $nf, $self->NF, "Split correctly to $nf fields";
    my $status = ( not $self->NF or $self->NF > 15 ) ? 1 : 0;
    ok( $status, 'Joined lines properly: ' . $self->this_line );
    $self->SUPER::save_record(@_) if $nf;
}

my $pattern = qr/\\\s*$/;

override is_line_continued => sub {
    my $self = shift;
    ok $self->field(-1) =~ $pattern, $self->this_line . " is continued"
        if $self->this_line =~ $pattern;
    $self->this_line =~ $pattern;
};

override join_last_line => sub {
    my $self = shift;
    my ( $last, $line ) = @_;
    $last =~ s/\\\s*$//g;
    return $last . ' ' . $line;
};

sub BUILDARGS {
    return { auto_chomp => 1, };
}

package TestNoSplitParser;
use Test::More;
use Moose;
extends 'Text::Parser';

sub BUILDARGS {
    return { auto_chomp => 1, auto_split => 1 };
}

sub save_record {
    my $self = shift;
    $self->auto_split
        ? $self->_if_split_is_on(@_)
        : $self->_if_no_split(@_);
}

sub _if_no_split {
    my $self = shift;
    is $self->NF, 0, '0 fields saved';
    $self->auto_split(1);
    $self->SUPER::save_record( [ @_, $self->NF ] );
}

sub _if_split_is_on {
    my $self = shift;
    my $nf   = scalar( split /\s+/, $self->this_line );
    is $nf, $self->NF, "Split correctly to $nf fields";
    $self->SUPER::save_record( [ @_, $self->NF ] );
    $self->auto_split(0);
}

use constant LINEND => qr/\\\s*$/;

override is_line_continued => sub {
    my $self = shift;
    ok $self->this_line =~ LINEND(), $self->this_line . " is continued"
        if $self->this_line =~ LINEND;
    $self->this_line =~ LINEND;
};

override join_last_line => sub {
    my $self = shift;
    my ( $last, $line ) = @_;
    $last =~ s/\\\s*$//g;
    return $last . ' ' . $line;
};

package main;
use Test::More;
use Test::Exception;

my @parser;
$parser[0] = MyTestParser->new();
isa_ok $parser[0], 'Text::Parser';
lives_ok {
    $parser[0]->multiline_type(undef);
    $parser[0]->auto_split(1);
    $parser[0]->multiline_type('join_next');
    $parser[0]->read('t/example-wrapped.txt');
    is scalar( $parser[0]->get_records ), 2, 'Exactly 2 lines';
}
'All operations on parser[0] pass';

$parser[1] = MyTestParser->new();
isa_ok $parser[1], 'Text::Parser';
lives_ok {
    $parser[1]->multiline_type(undef);
    $parser[1]->multiline_type('join_next');
    $parser[1]->auto_split(1);
    $parser[1]->read('t/example-wrapped.txt');
    is scalar( $parser[1]->get_records ), 2, 'Exactly 2 lines';
}
'All operations on parser[1] pass';

my $parser = TestNoSplitParser->new();
$parser->read('t/example-wrapped.txt');
$parser->auto_split(0);
$parser->read('t/example-wrapped.txt');
$parser->auto_split(1);
$parser->multiline_type('join_next');
$parser->read('t/example-wrapped.txt');
$parser->auto_split(0);
$parser->read('t/example-wrapped.txt');

done_testing;
