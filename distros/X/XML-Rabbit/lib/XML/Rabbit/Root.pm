use strict;
use warnings;

package XML::Rabbit::Root;
$XML::Rabbit::Root::VERSION = '0.4.1';
use 5.008;

# ABSTRACT: Root class with sugar functions available

use XML::Rabbit::Sugar (); # no magic, just load
use namespace::autoclean (); # no cleanup, just load
use Moose::Exporter;

my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    also             => 'XML::Rabbit::Sugar',
    base_class_roles => ['XML::Rabbit::RootNode'],
);


sub import {
    namespace::autoclean->import( -cleanee => scalar caller );
    return unless $import;
    goto &$import;
}


sub unimport {
    return unless $unimport;
    goto &$unimport;
}


#sub init_meta {
#    return unless $init_meta;
#    goto &$init_meta;
#}

# FIXME: https://rt.cpan.org/Ticket/Display.html?id=51561
# Hopefully fixed by 2.06 (doy)
sub init_meta {
    my ($dummy, %opts) = @_;
    Moose->init_meta(%opts);
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $opts{for_class},
        roles => ['XML::Rabbit::RootNode']
    );
    return Moose::Util::find_meta($opts{for_class});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit::Root - Root class with sugar functions available

=head1 VERSION

version 0.4.1

=head1 FUNCTIONS

=head2 import

Automatically loads L<namespace::autoclean> into the caller's package and
dispatches to L<XML::Rabbit::Sugar/"import"> (tail call).

=head2 unimport

Dispatches to L<XML::Rabbit::Sugar/"unimport"> (tail call).

=head2 init_meta

Initializes the metaclass of the calling class and adds the role
L<XML::Rabbit::RootNode>.

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
