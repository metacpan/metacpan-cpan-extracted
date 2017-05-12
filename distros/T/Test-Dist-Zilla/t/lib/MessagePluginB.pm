#   ------------------------------------------------------------------------------------------------
#
#   file: t/MessagePluginB.pm
#
#   This file is part of perl-Test-Dist-Zilla.
#
#   ------------------------------------------------------------------------------------------------

package MessagePluginB;

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::Plugin';

sub BUILD {
    my ( $self ) = @_;
    $self->log( "Message 1" );
    $self->log( "Message 2" );
};

1;

# end of file #
