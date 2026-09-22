package WWW::Hetzner::Role::Pagination;
# ABSTRACT: Controller helper for collecting paginated API lists

our $VERSION = '0.101';

use Moo::Role;
use Carp qw(croak);
use namespace::clean;


requires '_list_page';

sub list_all {
    my ($self, %params) = @_;

    my %request_params = %params;
    my $page = exists $request_params{page} ? $request_params{page} : 1;
    croak "Invalid pagination page '$page'" unless _valid_page($page);

    my @entities;
    my %seen = ($page => 1);

    while (1) {
        my ($entities, $meta) = $self->_list_page(%request_params);
        push @entities, @$entities;

        return \@entities unless defined $meta;
        croak 'Invalid pagination metadata'
            unless ref $meta eq 'HASH' && ref $meta->{pagination} eq 'HASH';

        my $next_page = $meta->{pagination}{next_page};
        return \@entities unless defined $next_page;
        croak "Invalid pagination next_page '$next_page'"
            unless _valid_page($next_page);
        croak "Pagination next_page $next_page is cyclical"
            if $seen{$next_page};
        croak "Pagination next_page $next_page does not advance from $page"
            unless $next_page > $page;

        $seen{$next_page} = 1;
        $request_params{page} = $next_page;
        $page = $next_page;
    }
}

sub _valid_page {
    my ($page) = @_;
    return defined $page && !ref $page && $page =~ /\A[1-9]\d*\z/;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Role::Pagination - Controller helper for collecting paginated API lists

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    package My::API::Widgets;
    use Moo;
    with 'WWW::Hetzner::Role::Pagination';

    sub _list_page {
        my ($self, %params) = @_;
        my $result = $self->client->get('/widgets', params => \%params);
        return ($self->_wrap_list($result->{widgets} // []), $result->{meta});
    }

=head1 DESCRIPTION

Adds C<list_all> to a controller that implements C<_list_page>. The page
helper returns the wrapped entities and the response's C<meta> hashref. This
keeps pagination above the HTTP request/response seam and lets controllers
preserve their existing one-page C<list> methods.

=head2 list_all

    my $entities = $controller->list_all(per_page => 50, sort => 'id');

Collects every page starting at page 1, or at the supplied C<page>. Carries
all filters and sort values to each request. A response without C<meta> is
treated as a single page. Invalid, repeated, or non-advancing C<next_page>
metadata raises an error instead of returning a partial list.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
