#---------------------------------------------------------------------
package inc::My_Build;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Customize Module::Build for WebService::NFSN
#---------------------------------------------------------------------

use strict;
use warnings;

use parent 'Module::Build';

#=====================================================================
# Package Global Variables:

our $VERSION = '1.03'; # VERSION

#---------------------------------------------------------------------
# Explain that JSON 2 can substitute for JSON::XS:

sub prereq_failures
{
  my $self = shift @_;

  my $out = $self->SUPER::prereq_failures(@_);

  return $out unless $out;

  if (my $attrib = $out->{requires}{'JSON::XS'}) {
    my $message;

    if (do { local $@; eval "use JSON 2 (); 1" }) {
      # JSON 2.0 or later is an acceptable replacement for JSON::XS:
      delete $out->{requires}{'JSON::XS'};

      # Update requirements for MYMETA:
      my $req = $self->requires;
      delete $req->{'JSON::XS'};
      $req->{'JSON'} = 2;

      # Clean out empty hashrefs:
      delete $out->{requires} unless %{$out->{requires}};
      undef $out              unless %$out;
    } else {
      $attrib->{message} .= "\n\n" . <<'';
   JSON 2.0 or later can substitute for JSON::XS, but its pure-Perl
   implementation is slower, and you don't have it installed either.

    } # end else we couldn't load JSON 2 either
  } # end if JSON::XS failed

  return $out;
} # end prereq_failures

#=====================================================================
# Package Return Value:

1;
