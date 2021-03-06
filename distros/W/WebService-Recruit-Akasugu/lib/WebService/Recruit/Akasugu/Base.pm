package WebService::Recruit::Akasugu::Base;
use strict;
use base qw( XML::OverHTTP );
use vars qw( $VERSION );
$VERSION = '0.10';

use Class::Accessor::Children::Fast;

sub attr_prefix { ''; }

sub is_error {
    my $self = shift;
    my $root = $self->root();
    return $root ? 0 : 1;
}

=head1 NAME

WebService::Recruit::Akasugu::Base - Base class for Akasugu.net Web Service

=head1 DESCRIPTION

This is a base class for Akasugu.net Web Service.
L<WebService::Recruit::Akasugu> uses this internally.

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
