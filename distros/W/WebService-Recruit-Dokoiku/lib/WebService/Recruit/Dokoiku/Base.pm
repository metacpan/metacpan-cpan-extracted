package WebService::Recruit::Dokoiku::Base;
use strict;
use base qw( XML::OverHTTP );
use vars qw( $VERSION );
$VERSION = '0.10';

use Class::Accessor::Children::Fast;

sub default_param { { format => 'xml' }; }
sub notnull_param { [qw( key )]; }
sub attr_prefix { ''; }

sub is_error {
    my $self = shift;
    my $root = $self->root();
    $root->status();                # 0 means ok
}
sub total_entries {
    my $self = shift;
    my $root = $self->root() or return;
    $root->{totalcount} || 0;
}
sub entries_per_page {
    my $self = shift;
    my $root = $self->root() or return;
    $root->{pagesize} || 10;
}
sub current_page {
    my $self = shift;
    my $root = $self->root() or return;
    $root->{pagenum} || 1;
}
sub page_param {
    my $self = shift;
    my $page = shift || $self->current_page();
    my $size = shift || $self->entries_per_page();
    my $hash = shift || {};
    $hash->{pagenum}  = $page if defined $page;
    $hash->{pagesize} = $size if defined $size;
    $hash;
}

=head1 NAME

WebService::Recruit::Dokoiku::Base - Base class for Dokoiku Web Service Beta

=head1 DESCRIPTION

This is a base class for the Dokoiku Web Service I<Beta>.
L<WebService::Recruit::Dokoiku> uses this internally.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
