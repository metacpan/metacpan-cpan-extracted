# -*- mode: perl; coding: utf-8 -*-
package YATT::LRXML::MetaInfo;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::Configurable);
BEGIN {require Exporter; *import = \&Exporter::import}
our @EXPORT = qw(MetaInfo);
our @EXPORT_OK = @EXPORT;

sub MetaInfo () {__PACKAGE__}

use YATT::Fields
  (['^nsdict' => sub { {} }]
   , ['cf_namespace' => 'yatt']
   , [cf_startline => 1]
   , qw(^=tokens
	^cf_filename
	cf_nsid
	cf_iolayer
	^cf_caller_widget
      )
   );

sub after_configure {
  my MY $self = shift;
  $self->SUPER::after_configure;
  if (defined $self->{cf_namespace}) {
    my $nsdict = $self->{nsdict} = {};
    $self->{cf_namespace} = [$self->{cf_namespace}]
      unless ref $self->{cf_namespace} eq 'ARRAY';
    foreach my $ns (@{$self->{cf_namespace}}) {
      $nsdict->{$ns} = keys %$nsdict;
    }
  } else {
    $self->{nsdict} = {};
  }
}

sub in_file {
  (my MY $self) = @_;
  if (defined $$self{cf_filename}) {
    " in file $$self{cf_filename}";
  } else {
    '';
  }
}

1;
