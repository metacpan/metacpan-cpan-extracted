#!/usr/bin/perl

package XML::LibXSLT::Easy::Batch::CLI;
use Moose;

use XML::LibXSLT::Easy::Batch;

use Carp qw(croak);
use MooseX::Types::Path::Class;
use Config::Any;

use namespace::clean -except => [qw(meta)];

with qw(MooseX::Getopt);

has conf_file => (
    isa => "Path::Class::File",
    is  => "rw",
    coerce => 1,
);

has files => (
    traits => [qw(NoGetopt)],
    isa => "ArrayRef[HashRef]",
    is  => "ro",
    lazy_build => 1,
);

sub _build_files {
    my $self = shift;
    my $files = Config::Any->load_files({ files => [ $self->conf_file ], use_ext => 1 });
    return $files->[0]{$self->conf_file} || croak "conf file could not be loaded";;
}

has proc => (
    traits => [qw(NoGetopt)],
    isa => "XML::LibXSLT::Easy::Batch",
    is  => "rw",
    lazy_build => 1,
);

sub _build_proc {
    my $self = shift;
    XML::LibXSLT::Easy::Batch->new( files => $self->files );
}

sub run {
    my $self = shift;
    $self = $self->new_with_options( @ARGV == 1 ? ( conf_file => shift @ARGV ) : () ) unless ref $self;

    $self->proc->process()
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::LibXSLT::Easy::Batch::CLI - 

=head1 SYNOPSIS

    use XML::LibXSLT::Easy::Batch::CLI;

=head1 DESCRIPTION

=cut


