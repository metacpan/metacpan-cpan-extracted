###############################################################################
# XML::Template::Subroutine
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Subroutine;

use strict;
use Exporter;
use POSIX qw(strftime);

use vars qw(@ISA @EXPORT_OK $AUTOLOAD);


@ISA       = qw(Exporter);
@EXPORT_OK = qw(defined set_date_vars);


=pod

=head1 NAME

XML::Template::Subroutine - The default XML::Template subroutine handling 
module.

=head1 SYNOPSIS

XML::Template supports calling subroutines on variables (e.g.,
C<${varname}.subname (params)>).  You can associate a Perl module with a
subroutine in the XML::Template configuration file (see
L<XML::Template::Config>.  Whenever the subroutine is encountered, the
module will be loaded and the method with the same name as the
XML::Template subroutine will be called with the following parameters: the
name of the variable the subroutine is being called on, the variable's
value, an array of additional parameters to the XML::Template subroutine.  
If no Perl module is associated with a subroutine, the subroutine is
called from this module.  Tpically, these subroutines are not called
directly but from the method C<subroutine> in L<XML::Template::Process>.

=head1 XML::Template SUBROUTINES

=head2 defined

Returns true if the variable is defined.

=cut

sub defined {
  my $class   = shift;
  my $process = shift;
  my ($var, $value) = @_;

  return CORE::defined $value;
}

=pod

=head2 set_date_vars

This subroutine is used to set various date related variables in the 
current variable context.  It should be called on a variable whose value 
is in the MySQL datetime format.  It take an addition parameter, 
C<prefix>, which is prepended to each date variable set.  Variables are 
set for the year, month, day, hour, minute, and second.

=cut

sub set_date_vars {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $prefix) = @_;

  my $vars = $process->{_vars};

  $value =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/;
  $vars->set ($prefix . "_year", $1);
  $vars->set ($prefix . "_month", $2);
  $vars->set ($prefix . "_day", $3);
  $vars->set ($prefix . "_hour", $4);
  $vars->set ($prefix . "_minute", $5);
  $vars->set ($prefix . "_second", $6);

  return '';
}

=pod

=head2 format_date

This subroutine returns a date in the format specified by the additional
parameter C<format>.  It currently only supports variable values in the
MySQL datetime format.

=cut

sub format_date {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $format) = @_;

  if ($value =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/) {
    my $year = $1 - 1900;
    my $mon  = $2 - 1;
    return strftime ($format, $6, $5, $4, $3, $mon, $year);
  }

  return '';
}

=pod

=head2 replace

This subroutine replaces a substring of the value identified by a regular
expression with another string.  The first additional parameter is the
regular expression, the second is the replacement string.

=cut

sub replace {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, $pattern, $replace) = @_;

  $value =~ s/$pattern/$replace/;
  $process->{_vars}->set ($var, $value);

  return '';
}

=pod

=head2 encrypt

This subroutine encrypts the value and returns the result.

=cut

sub encrypt {
  my $class   = shift;
  my $process = shift;
  my ($var, $value) = @_;

  srand;
  my @salt_chars = ('A' .. 'Z', 0 .. 9, 'a' .. 'z', '.', '/');
  my $salt = join '', @salt_chars[rand 64, rand 64];
  my $encrypted = crypt ($value, $salt); 

  return $encrypted;
}

sub AUTOLOAD {
  my $class   = shift;
  my $process = shift;
  my ($var, $value, @params) = @_;

  if ($AUTOLOAD !~ /DESTROY$/) {
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return defined $value ? $value->$method (@params) : undef;
  }
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
