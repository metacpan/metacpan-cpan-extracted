package Win32::OLE::CrystalRuntime::Application::Base;
use strict;
use warnings;

our $VERSION='0.11';

=head1 NAME

Win32::OLE::CrystalRuntime::Application::Base - Perl CrystalRuntime.Application Base Object

=head1 SYNOPSIS

  use base qw{Win32::OLE::CrystalRuntime::Application::Base};

=head1 DESCRIPTION

This package provide methods common to all Win32::OLE::CrystalRuntime::Application objects. 

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $application=Win32::OLE::CrystalRuntime::Application->new;

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head2 debug

=cut

sub debug {shift->{"debug"}||0};

=head1 FUNCTIONS

=head2 list_collection

Returns a perl list given a CrystalRuntime collection

  my @list=$app->list_collection($collection); #()
  my $list=$app->list_collection($collection); #[]

=cut

sub list_collection {
  my $self=shift;
  my $collection=shift;
  my @list=();
  if ($collection->Count > 0) {
    foreach my $index (1 .. $collection->Count) {
      push @list, $collection->Item($index);
    }
  }
  return wantarray ? @list : \@list;
}

=head1 BUGS

=head1 SUPPORT

Please try Business Objects.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>stopllc,tld=>com,account=>mdavis
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

Crystal Reports XI Technical Reference Guide - http://support.businessobjects.com/documentation/product_guides/boexi/en/crxi_Techref_en.pdf

L<Win32::OLE>, L<Win32::OLE::CrystalRuntime::Application>, L<Win32::OLE::CrystalRuntime::Application::Report>

=cut

1;
