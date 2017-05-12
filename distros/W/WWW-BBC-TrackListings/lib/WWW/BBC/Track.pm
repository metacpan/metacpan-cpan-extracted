package WWW::BBC::Track;

use Moose;
use namespace::autoclean;

# ABSTRACT: An object repesenting a track in a BBC radio programme
our $VERSION = '0.01'; # VERSION

has 'artist' => (
    is => 'ro',
    isa => 'Str',
);

has 'title' => (
    is => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

WWW::BBC::Track - An object repesenting a track in a BBC radio programme

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $track = WWW::BBC::Track->new({ artist => 'Bonobo', title => 'Black Sands' })

=head1 METHODS

=head2 new

Constructor for objects of this class.

=head1 ATTRIBUTES

=head2 artist

=head2 title

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

