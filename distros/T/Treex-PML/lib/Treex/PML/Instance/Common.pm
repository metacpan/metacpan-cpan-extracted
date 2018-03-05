package Treex::PML::Instance::Common;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
import Exporter qw( import );

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
  'diagnostics' => [ qw( _die _warn _debug DEBUG XSLT_BUG ) ],
  'constants' => [ qw( LM AM PML_NS SUPPORTED_PML_VERSIONS ) ],
);
$EXPORT_TAGS{'all'} = [
  @{ $EXPORT_TAGS{'constants'} },
  @{ $EXPORT_TAGS{'diagnostics'} },
  qw( $DEBUG $XSLT_BUG SUPPORTED_PML_VERSIONS )
];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(  );
our $VERSION = '2.24'; # version template


our $DEBUG = $ENV{PML_DEBUG}||0;

our $XSLT_BUG=0;
eval {
    require XML::LibXSLT;
    $XSLT_BUG = grep 10127 == $_, XML::LibXSLT::LIBXSLT_VERSION(),
                                  XML::LibXSLT::LIBXSLT_RUNTIME_VERSION();
};

use constant LM => 'LM';
use constant AM => 'AM';
use constant PML_NS => "http://ufal.mff.cuni.cz/pdt/pml/";
use constant SUPPORTED_PML_VERSIONS => " 1.1 1.2 ";

###################################
# DIAGNOSTICS
###################################

sub XSLT_BUG {
  return $XSLT_BUG;
}

sub DEBUG {
  if (@_) { $DEBUG=$_[0] };
  return $DEBUG
}

sub _die {
  my $msg = join q{},@_;
  chomp $msg;
  if ($DEBUG) {
    local $Carp::CarpLevel=1;
    confess($msg);
  } else {
    die "$msg\n";
  }
}

sub _debug {
  return unless $DEBUG;
  my $level = 1;
  my $node = undef;
  if (ref($_[0])) {
    $level=$_[0]->{level};
    $node=$_[0]->{node};
    shift;
  }
  return unless abs($DEBUG)>=$level;
  my $msg=join q{},@_;
  chomp $msg;
  $msg =~ s/\%N/_element_address($node)/e;
  print STDERR "Treex::PML: $msg\n"
}

sub _warn {
  my $msg = join q{},@_;
  chomp $msg;
  if ($DEBUG<0) {
    Carp::cluck("Treex::PML: WARNING: $msg");
  } else {
    warn("Treex::PML: WARNING: $msg\n");
  }
}



1;
__END__

=head1 NAME

Treex::PML::Instance::Common

=head1 DESCRIPTION

This module provides constants and diagnostic functions used by other
parts of L<Treex::PML::Instance> implementation.

This module is not intended for direct use.

=head1 FUNCTIONS

=over 5

=item DEBUG($level?)

Set or get current debug level.

=item XSLT_BUG

Returns 1 if the version of the underlying XSLT library is 1.1.27
which cannot be used because it contains a serious bug.

=back

=head1 SEE ALSO

L<Treex::PML::Instance>, L<Treex::PML::Schema::Constants>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
