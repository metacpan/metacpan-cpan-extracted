package WebService::Mirth::GlobalScripts;
{
  $WebService::Mirth::GlobalScripts::VERSION = '0.131220';
}

# ABSTRACT: Represent Mirth "global scripts"

use Moose;
use namespace::autoclean;

extends 'WebService::Mirth';

has global_scripts_dom => (
    is       => 'ro',
    isa      => 'Mojo::DOM',
    required => 1,
);

sub get_content {
    my ($self) = @_;

    my $content = $self->global_scripts_dom . ''; # (Force string context)

    return $content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WebService::Mirth::GlobalScripts - Represent Mirth "global scripts"

=head1 VERSION

version 0.131220

=head1 AUTHOR

Tommy Stanton <tommystanton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tommy Stanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

