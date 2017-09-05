package Test2::Harness::DirORM::File;
use strict;
use warnings;

use Carp qw/croak/;

use Test2::Harness::Util();
use Test2::Harness::Util::ActiveFile();

use Test2::Harness::HashBase qw{-file -transform -active_file -append_fh};

sub exists { -e $_[0]->{+FILE} }

sub decode { shift; @_ }
sub encode { shift; @_ }

sub init {
    my $self = shift;

    croak "The 'file' attribute is required"
        unless $self->{+FILE};
}

sub maybe_read {
    my $self = shift;
    return undef unless -e $self->{+FILE};
    return $self->read;
}

sub read {
    my $self = shift;
    my $out = Test2::Harness::Util::read_file($self->{+FILE});
    $out = $self->decode($out);
    my $trans = $self->{+TRANSFORM} or return $out;
    return $self->$trans($out);
}

sub write {
    my $self = shift;
    return Test2::Harness::Util::write_file($self->{+FILE}, $self->encode(@_));
}

sub reset_line {
    my $self = shift;
    delete $self->{+ACTIVE_FILE};
    return;
}

sub read_line {
    my $self = shift;
    my ($eof) = @_;

    my $af = $self->{+ACTIVE_FILE} ||= Test2::Harness::Util::ActiveFile->maybe_open_file($self->{+FILE})
        or return undef;

    $af->set_done(1) if $eof;

    my $out = $af->read_line;
}

sub open {
    my $self = shift;
    return Test2::Harness::Util::open_file($self->{+FILE}, @_)
}

1;
