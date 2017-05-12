package Tibco::Rv::Inline;


use vars qw/ $VERSION $TIBRV_VERSION_RELEASE $TIBRV_VERSION_MINOR %CONFIG /;


BEGIN
{
   $VERSION = '1.15';
   my ( $env_err ) = q/
one of: TIB_HOME, TIB_RV_HOME, or TIBRV_DIR must be set
TIB_HOME must be your base Tibco directory, and it must contain "tibrv"; or:
TIB_RV_HOME or TIBRV_DIR must be your Rendezvous installation directory
/;
   unless ( exists $ENV{TIB_RV_HOME} )
   {
      if ( exists $ENV{TIBRV_DIR} )
      {
         $ENV{TIB_RV_HOME} = $ENV{TIBRV_DIR};
      } elsif ( exists $ENV{TIB_HOME} ) {
         $ENV{TIB_RV_HOME} = "$ENV{TIB_HOME}/tibrv";
      }
   }
   die $env_err
      unless ( -d "$ENV{TIB_RV_HOME}/include" and -d "$ENV{TIB_RV_HOME}/lib" );
   ( $TIBRV_VERSION_RELEASE, $TIBRV_VERSION_MINOR ) =
      scalar( `$ENV{TIB_RV_HOME}/bin/rvd --not-really-a-thing 2>/dev/null` )
         =~ /Version (\d+)\.(\d+)./g;
   die "Could not find rvd 6.x or 7.x"
      unless ( $TIBRV_VERSION_RELEASE == 6 or $TIBRV_VERSION_RELEASE == 7 );

   %CONFIG =
   (
      AUTO_INCLUDE => <<END,
#include <tibrv/cm.h>
#define TIBRV_VERSION_RELEASE $TIBRV_VERSION_RELEASE
#define TIBRV_VERSION_MINOR $TIBRV_VERSION_MINOR
END
      AUTOWRAP => 'ENABLE',
      TYPEMAPS => 'typemap',
      LIBS => "-L$ENV{TIB_RV_HOME}/lib -ltibrv -ltibrvcm",
      INC => "-I$ENV{TIB_RV_HOME}/include",
   );
}

use Inline C => Config => %CONFIG;
sub Inline { return \%CONFIG }


1;


=pod

=head1 NAME

Tibco::Rv::Inline - Tibco Inline handler

=head1 SYNOPSIS

   use Inline with => 'Tibco::Rv::Inline';
   use Inline C => 'DATA', NAME => __PACKAGE__,
      VERSION => $Tibco::Rv::Inline::VERSION;

=head1 DESCRIPTION

Configure Inline::C for Tibco::Rv (internal-only module).

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
