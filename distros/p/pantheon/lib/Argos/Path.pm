package Argos::Path;

=head1 NAME

Argos::Path - Implements Vulcan::DirConf

=cut
use strict;

use base qw( Vulcan::DirConf );

=head1 CONFIGURATION

A YAML file that defines I<code>, I<conf>, I<run> paths.
Each must be a valid directory or symbolic link.

=cut

sub define { qw( code conf run ) }

1;
