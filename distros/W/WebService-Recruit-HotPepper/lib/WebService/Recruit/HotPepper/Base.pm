package WebService::Recruit::HotPepper::Base;
use strict;
use base qw( XML::OverHTTP );
use vars qw( $VERSION );
$VERSION = '0.02';

use Class::Accessor::Children::Fast;

sub default_param { {}; }
sub notnull_param { [qw( key )]; }
sub attr_prefix { ''; }

sub is_error {
    my $self  = shift;
    my $tree  = $self->tree();
    my $mess;
    if ( ref $tree ){
        my $error = $tree->{Error} or return;
        $mess = $error->{Message} or return;
    }else{
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
    $root->{DisplayPerPage} || 10;
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
    $hash->{Start} = ($page-1) * $size + 1;
    $hash->{Count} = $size;
    $hash;
}

=head1 NAME

WebService::Recruit::HotPepper::Base - Base class for HotPepper Web Service Beta

=head1 DESCRIPTION

This is a base class for the HotPepper Web Service I<Beta>.
L<WebService::Recruit::HotPepper> uses this internally.

=head1 SEE ALSO

L<WebService::Recruit::HotPepper>, L<XML::OverHTTP>

=head1 AUTHOR

Toshimasa Ishibashi L<http://iandeth.dyndns.org/>

This module is unofficial and released by the author in person.

=head1 THANKS TO

Yusuke Kawasaki L<http://www.kawa.net/>

For creating/preparing all the base modules and stuff.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Toshimasa Ishibashi. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
