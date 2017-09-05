package Test2::Harness::Schema::Dir;
use strict;
use warnings;

use Carp qw/croak/;
use File::Spec();

BEGIN { require Test2::Harness::Schema; our @ISA = 'Test2::Harness::Schema' }
use Test2::Harness::Util::HashBase qw/-root -polls -index -cache/;

sub init {
    my $self = shift;

    croak "The 'root' attribute is required"
        unless $self->{+ROOT};

    $self->{+ROOT} = File::Spec->rel2abs($self->{+ROOT});

    $self->{+POLLS} ||= {};
    $self->{+INDEX} ||= {};
    $self->{+CACHE} ||= {};
}

sub path {
    my $self = shift;
    my $root = $self->{+ROOT};
    return File::Spec->catfile($root, @_);
}

sub reload {
    my $self = shift;

    %{$self->{+POLLS}} = ();
    %{$self->{+INDEX}} = ();
    %{$self->{+CACHE}} = ();
}

sub clear_cache { %{shift->{+CACHE}} = () }

1;
