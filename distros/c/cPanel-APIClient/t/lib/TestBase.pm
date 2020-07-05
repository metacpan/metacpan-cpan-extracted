package TestBase;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use mro;

use parent 'Test::Class';

use Test::More;

use cPanel::APIClient;

sub fail_if_returned_early { 1 }

sub SKIP_CLASS {
    my ($self) = @_;

    my $classes_ar = mro::get_linear_isa(ref $self);

    my %already;

    for my $class (@$classes_ar) {
        my $cp_req_cr = $class->can('_CP_REQUIRE');

        next if !$cp_req_cr;
        next if $already{$cp_req_cr};

        $already{$cp_req_cr} = 1;

        my @reqs = $cp_req_cr->();

        for my $req (@reqs) {
            local $@;

            my $ok;

            if ('CODE' eq ref($req)) {
                $ok = eval { $req->(); 1 };
            }
            elsif ('ARRAY' eq ref $req) {
                $ok = eval "use @$req; 1";
            }
            else {
                $ok = eval "use $req; 1";
            }

            return $@ if !$ok;
        }
    }

    return q<>;
}

sub CREATE {
    my ( $self, @args ) = @_;

    my $remote_cp = cPanel::APIClient->create(
        transport => $self->TRANSPORT(),

        @args,
    );

    return $remote_cp;
}

1;
