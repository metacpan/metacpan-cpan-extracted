package XML::Validator::Schema::Library;
use strict;
use warnings;

use XML::Validator::Schema::Util qw(XSD _err);
use Carp qw(croak);

=head1 NAME

XML::Validator::Schema::TypeLibrary

=head1 DESCRIPTION

Internal base class used to implement a libraries of named items.

=cut

sub new {
    my $pkg = shift;
    my $self = bless({@_}, $pkg);

    croak("Missing required 'what' parameter.")
      unless $self->{what};
    
    # initialize stacks
    $self->{stacks} = {};

    return $self;
}

sub find_all {
    my $self = shift;
    my @ret;
    foreach my $ns (keys %{$self->{stacks}}) {
        foreach my $name (keys %{$self->{$ns}}) {
            push @ret, $self->{stacks}{$ns}{$name};
        }
    }
    return @ret;
}

sub find {
    my ($self, %arg) = @_;
    croak("Missing required name parameter.") unless $arg{name};

    # HACK: fix when QName resolution works
    $arg{name} =~ s!^[^:]*:!!;
    $arg{ns} ||= XSD;

    return $self->{stacks}{$arg{ns}}{$arg{name}};
}

sub add {
    my ($self, %arg) = @_;
    croak("Missing required name parameter.") unless $arg{name};
    croak("Missing required obj parameter.") unless $arg{obj};
    
    # HACK: fix when QName resolution works
    $arg{name} =~ s!^\w+:!!;
    $arg{ns} ||= XSD;

    _err("Illegal attempt to redefine $self->{what} '$arg{name}' ".
         "in namespace '$arg{ns}'")
      if exists $self->{stacks}{$arg{ns}}{$arg{name}};
    $self->{stacks}{$arg{ns}}{$arg{name}} = $arg{obj};
}

1;
