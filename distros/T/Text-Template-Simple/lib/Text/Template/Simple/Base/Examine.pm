## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Examine;
use strict;
use warnings;

use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

our $VERSION = '0.90';

sub _examine {
   my $self   = shift;
   my $TMP    = shift;
   my($type, $thing) = $self->_examine_type( $TMP );
   my $rv;

   if ( $type eq 'ERROR' ) {
      $rv           = $thing;
      $self->[TYPE] = $type;
   }
   elsif ( $type eq 'GLOB' ) {
      $rv           = $self->_examine_glob( $thing );
      $self->[TYPE] = $type;
   }
   else {
      if ( my $path = $self->io->file_exists( $thing ) ) {
         $rv                = $self->io->slurp( $path );
         $self->[TYPE]      = 'FILE';
         $self->[TYPE_FILE] = $path;
      }
      else {
         # just die if file is absent, but user forced the type as FILE
         $self->io->slurp( $thing ) if $type eq 'FILE';
         $rv           = $thing;
         $self->[TYPE] = 'STRING';
      }
   }

   LOG( EXAMINE => sprintf q{%s; LENGTH: %s}, $self->[TYPE], length $rv ) if DEBUG;
   return $rv;
}

sub _examine_glob {
   my($self, $thing) = @_;
   my $type = ref $thing;
   fatal( 'tts.base.examine.notglob' => $type ) if $type ne 'GLOB';
   fatal( 'tts.base.examine.notfh'            ) if ! fileno $thing;
   return $self->io->slurp( $thing );
}

sub _examine_type {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;

   return EMPTY_STRING ,  $TMP if ! $ref;
   return GLOB         => $TMP if   $ref eq 'GLOB';

   if ( ref $TMP eq 'ARRAY' ) {
      my $ftype  = shift @{ $TMP } || fatal('tts.base.examine._examine_type.ftype');
      my $fthing = shift @{ $TMP } || fatal('tts.base.examine._examine_type.fthing');
      fatal('tts.base.examine._examine_type.extra') if @{ $TMP };
      return uc $ftype, $fthing;
   }

   return fatal('tts.base.examine._examine_type.unknown', $ref);
}

1;

__END__

=head1 NAME

Text::Template::Simple::Base::Examine - Base class for Text::Template::Simple

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

This document describes version C<0.90> of C<Text::Template::Simple::Base::Examine>
released on C<5 July 2016>.

Private module.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
