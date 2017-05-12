package WWW::Metalgate::Role::Html;

use warnings;
use strict;

use Moose::Role;

#requires_attr 'uri';

use Encode;
use File::Spec;
use Cache::File;
use URI::Fetch;

=head1 NAME

WWW::Metalgate::Role::Html

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 FUNCTIONS

=head2 html

=cut

sub html {
    my $self = shift;

    $self->{_html} ||= do {
        my $tmpdir = File::Spec->tmpdir();
        my $cache  = Cache::File->new( cache_root => $tmpdir );
        #my $res = URI::Fetch->fetch($self->uri->canonical, Cache => $cache) or die URI::Fetch->errstr;
        my $res = URI::Fetch->fetch($self->uri->canonical, Cache => $cache, NoNetwork => 60) or die URI::Fetch->errstr;
        decode("cp932", $res->content);
    };

    return $self->{_html};
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
