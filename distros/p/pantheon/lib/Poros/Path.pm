package Poros::Path;

=head1 NAME

Poros::Path - Implements Vulcan::DirConf

=cut
use strict;
use base qw( Vulcan::DirConf );

=head1 CONFIGURATION

A YAML file that defines I<code>, I<run> paths.
Each must be a valid directory or symbolic link.

=cut
sub define { qw( code run ) }

1;
