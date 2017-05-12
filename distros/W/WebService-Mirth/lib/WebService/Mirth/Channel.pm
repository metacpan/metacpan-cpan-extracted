package WebService::Mirth::Channel;
{
  $WebService::Mirth::Channel::VERSION = '0.131220';
}

# ABSTRACT: Represent a Mirth channel

use Moose;
use namespace::autoclean;

extends 'WebService::Mirth';

use Moose::Util::TypeConstraints qw( enum );

has channel_dom => (
    is       => 'ro',
    isa      => 'Mojo::DOM',
    required => 1,
);

has name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->channel_dom->at('name')->text },
);

has id => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->channel_dom->at('id')->text },
);

has enabled => (
    is      => 'rw',
    isa     => enum( [qw( true false )] ),
    lazy    => 1,
    default => sub { $_[0]->channel_dom->at('enabled')->text },
);

sub get_content {
    my ($self) = @_;

    my $content = $self->channel_dom . ''; # (Force string context)

    return $content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WebService::Mirth::Channel - Represent a Mirth channel

=head1 VERSION

version 0.131220

=head1 AUTHOR

Tommy Stanton <tommystanton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tommy Stanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

