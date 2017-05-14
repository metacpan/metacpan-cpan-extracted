# $Id: Esqlc.pm,v 1.12 2011/10/30 20:58:00 pfeiffer Exp $

=head1 NAME

Mpp::Scanner::Esqlc - makepp scanner for Embedded SQL C files

=head1 DESCRIPTION

Scans a C file for C<EXEC SQL INCLUDE>s, C<$include>s and C<#include>s.

Tags are:

=over

=item user

File scanned due to an EXEC SQL INCLUDE "filename" or $INCLUDE "filename"
directive.

=item sys

File scanned due to an EXEC SQL INCLUDE E<lt>filenameE<lt>, EXEC SQL INCLUDE
filename or $INCLUDE E<lt>filenameE<lt> directive.
=over 6

=item usersys

An EXEC SQL INCLUDE IDENTIFIER statement with neither <> nor quotes.  This
gets extended with suffixes like F<.h> if needed.

=item sql

Temporarily assigned internally to EXEC SQL INCLUDE or $INCLUDE, before
deciding which of the above two to use.

=back

=cut

use strict;
package Mpp::Scanner::Esqlc;

use Mpp::Scanner::C;
our @ISA = 'Mpp::Scanner::C';

sub get_directive {
  if( s/^\s*(?:EXEC\s+SQL\s+|\$\s*)INCLUDE(?:\s+EXTERN)?\s+(?=[^\s;])//i ) {
    'sql';
  } elsif( s/^\s*EXEC\s+(?:SQL|ORACLE)\s+OPTION\s\((sys_?)?include=(?:\((.+)\)|(.+))\)//i ) {
    my $sys = $1;
    for( $2 ? split( ',', $2 ) : $3 ) {
      $_[0]->add_include_dir( user => $_ );
      $_[0]->add_include_dir( usersys => $_ );
      $_[0]->add_include_dir( sys => $_ ) if $sys;
    }
    return;
  } elsif( s/^\s*EXEC\s+ORACLE\s+// ) {
      if( s/^(DEFINE|IFN?DEF)(\s+\w+)\s*;/$2/i || s/^(ELSE|ENDIF)\s*;//i ) {
	lc $1;
      }
  } else {
    &Mpp::Scanner::C::get_directive;
  }
}

sub other_directive {
  my( $self, $cp, $finfo, $conditional, $tag, $scanworthy ) = @_;
  return 0 unless $tag eq 'sql';
  $_ = $self->expand_macros($_) if $conditional;
  $$scanworthy = 1;
  if( s/^(<)(.+?)>\s*;?\s*$// or s/^(['"]?)(.+?)\1\s*;?\s*$// ) {
    $tag = $1 eq '<' ? 'sys' : $1 ? 'user' : 'usersys';
    my $file = $1 ? $2 : lc $2; # downcase unquoted file
    $self->include( $cp, $tag, $file, $finfo )
      or undef;
  }
}

1;
