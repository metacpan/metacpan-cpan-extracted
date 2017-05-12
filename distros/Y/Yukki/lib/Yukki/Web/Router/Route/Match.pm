package Yukki::Web::Router::Route::Match;
{
  $Yukki::Web::Router::Route::Match::VERSION = '0.140290';
}
use Moose;

extends 'Path::Router::Route::Match';

use List::MoreUtils qw( all );
use Yukki::Error qw( http_throw );

# ABSTRACT: Matching with access controls


sub access_level { 
    my $self = shift;

    my $mapping = $self->mapping;
    my $acl     = $self->route->acl;

    for my $rule (@$acl) {
        my ($access_level, $match) = @$rule;

        if (all { $mapping->{$_} ~~ $match->{$_} } keys %$match) {
            return $access_level;
        }
    }

    http_throw("no ACL found to match " . $self->path);
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Router::Route::Match - Matching with access controls

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

This is a helper that include access control level checking.

=head1 EXTENDS

L<Path::Router::Route::Match>

=head1 METHODS

=head2 access_level

Evaluates the access control list against a particular path.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
