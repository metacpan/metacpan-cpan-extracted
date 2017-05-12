# WWW:Auth::Template
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.


package WWW::Auth::Template;
use base 'WWW::Auth::Base';


use strict;
use WWW::Auth::Config;


sub _init {
  my $self   = shift;
  my %params = @_;

  return 1;
}

sub process {
  my $self = shift;
  my ($template, $vars) = @_;

  if (! open (TEMPLATE, $template)) {
    return $self->error ("Error opening template $template: $!");
  }
  my $text;
  while (my $line = <TEMPLATE>) {
    $line =~ s/\${([^}]+)}/$vars->{$1}/g;
    $text .= $line;
  }
  close (TEMPLATE);

  print $text;

  return 1;
}


1;
