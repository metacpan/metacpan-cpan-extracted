package WebService::Recruit::Jalan::Base;
use strict;
use base qw( XML::OverHTTP );
use vars qw( $VERSION );
$VERSION = '0.10';

use Class::Accessor::Children::Fast;

sub attr_prefix { ''; }
sub text_node_key { '_text'; }

sub is_error {
    my $self  = shift;
    my $tree  = $self->tree();
    my $mess;
    if ( ref $tree ) {
        my $error = $tree->{Error} or return;
        $mess = $error->{Message} or return;
    }
    else {
        my $xml = $self->xml() or return;
        return unless ( $xml =~ m{</Error>\s*$} );
        $mess = ( $xml =~ m{([^<>]*?)</Message>}s )[0];
    }
    $mess;
}
sub total_entries {
    my $self = shift;
    my $root = $self->root() or return;
    $root->{NumberOfResults} || 0;
}
sub entries_per_page {
    my $self = shift;
    my $root = $self->root() or return;
    $root->{DisplayPerPage} || 0;
}
sub current_page {
    my $self = shift;
    my $root = $self->root() or return;
    my $epp  = $self->entries_per_page() or return;
    int(($root->{DisplayFrom}-1) / $epp)+1 || 1;
}
sub page_param {
    my $self = shift;
    my $page = shift || $self->current_page();
    my $size = shift || $self->entries_per_page();
    my $hash = shift || {};
    $hash->{start} = ($page-1) * $size + 1;
    $hash->{count} = $size;
    $hash;
}

=head1 NAME

WebService::Recruit::Jalan::Base - Base class for Jalan Web Service

=head1 DESCRIPTION

This is a base class for the Jalan Web Service.
L<WebService::Recruit::Jalan> uses this internally.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
