package Test::Synopsis::Expectation::Pod;
use strict;
use warnings;
use parent qw/Pod::Simple::Methody/;

sub new {
    my $class  = shift;
    my $parser = $class->SUPER::new(@_);

    # NOTE I think not good way...
    $parser->{in_head1}    = 0;
    $parser->{in_synopsis} = 0;
    $parser->{in_verbatim} = 0;
    $parser->{no_test}     = 0;

    $parser->{target_codes} = [];

    $parser->accept_target_as_text(qw/test_synopsis_expectation_no_test/);

    return $parser;
}

sub _handle_text {
    my($self, $text) = @_;
    if ($self->{in_head1} && $text =~ /^synopsis$/i) {
        $self->{in_synopsis} = 1;
    }

    # Target codes (that is synopsis code)
    if ($self->{in_synopsis} && $self->{in_verbatim}) {
        unless ($self->{no_test}) {
            push @{$self->{target_codes}}, $text;
        }
        $self->{no_test} = 0;
    }
}

sub _handle_element_start {
    my ($self, $element_name, $attr_hash_r) = @_;

    if ($element_name eq 'head1') {
        $self->{in_head1}    = 1;
        $self->{in_synopsis} = 0;
    }
    elsif ($element_name eq 'Verbatim') {
        $self->{in_verbatim} = 1;
    }
    elsif ($element_name eq 'for') {
        if ($attr_hash_r->{target} eq 'test_synopsis_expectation_no_test') {
            $self->{no_test} = 1;
        }
    }
}

sub _handle_element_end {
    my ($self, $element_name) = @_;

    if ($element_name eq 'head1') {
        $self->{in_head1} = 0;
    }
    elsif ($element_name eq 'Verbatim') {
        $self->{in_verbatim} = 0;
    }
}
1;
