#!/usr/bin/perl

package XML::LibXSLT::Easy::CLI;
use Moose;

use XML::LibXSLT::Easy;

use MooseX::Types::Path::Class;

use namespace::clean -except => [qw(meta)];

with qw(MooseX::Getopt);

has [qw(xml xsl out)] => (
    isa => "Path::Class::File",
    is  => "rw",
    coerce   => 1,
    required => 1,
);


has out => (
    isa => "Path::Class::File",
    is  => "rw",
    coerce => 1,
);

has proc => (
    traits => [qw(NoGetopt)],
    isa => "XML::LibXSLT::Easy",
    is  => "rw",
    lazy_build => 1,
);

sub _build_proc {
    XML::LibXSLT::Easy->new;
}

sub run {
    my $self = shift;
    $self = $self->new_with_options unless ref $self;

    $self->proc->process(
        xml => $self->xml,
        xsl => $self->xsl,
        out => ( $self->out || \*STDOUT ),
    );
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::LibXSLT::Easy::CLI - 

=head1 SYNOPSIS

    use XML::LibXSLT::Easy::CLI;

=head1 DESCRIPTION

=cut


