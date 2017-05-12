package Vote::View::TT;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH => Vote->path_to( 'root', 'templates' ),
    PRE_PROCESS => 'includes/header.tt',
    POST_PROCESS => 'includes/footer.tt',
    PLUGIN_BASE => 'Vote::Template::Plugin',
);

=head1 NAME

Vote::View::TT - TT View for Vote

=head1 DESCRIPTION

TT View for Vote. 

=cut

sub process {
    my ($self, $c) = @_;

    $c->stash->{Vote}{VERSION} = $Vote::VERSION;
    Catalyst::View::TT::process($self, $c);
}

=head1 SEE ALSO

L<Vote>

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
