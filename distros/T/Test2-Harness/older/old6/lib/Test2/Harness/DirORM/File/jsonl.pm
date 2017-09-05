package Test2::Harness::DirORM::File::jsonl;
use strict;
use warnings;

use Carp qw/croak/;
use Test2::Harness::Util::JSON qw/encode_json decode_json/;

use parent 'Test2::Harness::DirORM::File';
use Test2::Harness::HashBase;

sub decode { shift; decode_json(@_) }
sub encode { shift; encode_json(@_) }

sub read {
    my $self = shift;

    my $raw = Test2::Harness::Util::read_file($self->{+FILE});
    my @lines = split /\n/, $raw;

    my $trans = $self->{+TRANSFORM};

    my @out = map {
        my $d = $self->decode($_);
        $trans ? $self->$trans($d) : $d
    } @lines;

    return \@out;
}

1;
