#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2008-2023 -- leonerd@leonerd.org.uk

package Circle::FE::Term 0.232470;

use v5.26;
use warnings;

use File::ShareDir qw( dist_file );

=head1 NAME

C<Circle::FE::Term> - Terminal frontend for the C<Circle> application host

=cut

my %theme_vars;

{
   my $theme_filename;

   foreach ( $ENV{CIRCLE_FE_TERM_THEME},
             "$ENV{HOME}/.circle-fe-term.theme",
             dist_file( "circle-fe-term", "circle-fe-term.theme" ) ) {
      defined $_ or next;
      -e $_ or next;

      $theme_filename = $_;
      last;
   }

   defined $theme_filename or die "Cannot find a circle-fe-term.theme";

   open( my $themefh, "<", $theme_filename ) or die "Cannot read $theme_filename - $!";

   while( <$themefh> ) {
      m/^\s*#/ and next; # skip comments
      m/^\s*$/ and next; # skip blanks

      m/^(\S*)=(.*)$/ and $theme_vars{$1} = $2, next;
      print STDERR "Unrecognised theme line: $_";
   }
}

sub get_theme_var
{
   my $class = shift;
   my ( $varname ) = @_;
   return $theme_vars{$varname} if exists $theme_vars{$varname};
   print STDERR "No such theme variable $varname\n";
   return undef;
}

sub translate_theme_colour
{
   my $class = shift;
   my ( $colourname ) = @_;

   return $colourname if $colourname =~ m/^#/; # Literal #rrggbb
   return $theme_vars{$colourname} if exists $theme_vars{$colourname}; # hope
   print STDERR "No such theme colour $colourname\n";
   return undef;
}

sub get_theme_colour
{
   my $class = shift;
   my ( $varname ) = @_;
   return $theme_vars{$varname} if exists $theme_vars{$varname};
   print STDERR "No such theme variable $varname for a colour\n";
   return undef;
}

my %theme_pens;

sub get_theme_pen
{
   my $class = shift;
   my ( $varname ) = @_;
   return $theme_pens{$varname} ||= Tickit::Pen->new( fg => $class->get_theme_colour( $varname ) );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
