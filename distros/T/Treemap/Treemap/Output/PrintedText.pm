package Treemap::Output::PrintedText;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require Treemap::Output;

our @ISA = qw( Treemap::Output Exporter );
our @EXPORT_OK = (  );
our @EXPORT = qw( );
our $VERSION = '0.01';


# ------------------------------------------
# Methods:
# ------------------------------------------

sub save
{
   my $self = shift;
   return 1;
}

sub rect
{
   my $self = shift;
   $self->{DEPTH} = $self->{DEPTH} | 0;
   print " " x ($self->{DEPTH} * 3);
   print "rect: @_\n";
   $self->{DEPTH}++;
}

sub text
{
   my $self = shift;
   $self->{DEPTH}--;
   print " " x ($self->{DEPTH} * 3);
   print "text: @_\n";
}

sub width
{
   return "1024";
}

sub height
{
   return "768";
}

sub font_height
{
   return "10";
}

sub padding
{
   return "10";
}

1;

__END__

=head1 NAME

Treemap::Output::PrintedText

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use Treemap;
  use Treemap::Input::Dir;
  use Treemap::Output::PrintedText;
  
  my $dir = Treemap::Input::Dir->new();
  my $text = Treemap::Output::PrintedText->new(  WIDTH=>1024, HEIGHT=>768 );
  $dir->load( "/home" );

  my $treemap = new Treemap( INPUT=>$dir, OUTPUT=>$imager );
  $treemap->map();

=head1 DESCRIPTION

This object is primarily for debugging Treemap's calling of Treemap::Output
methods.

Implements Treemap::Output methods which allows Treemap to call appropriate
print functions to output in text what would be drawn graphically.

=head1 METHODS

B<new>
   Creates a new object. There are no attributes to be set.

=head1 SEE ALSO

L<Treemap>, L<Treemap::Output>

=head1 AUTHORS

Simon Ditner <simon@uc.org>, and Eric Maki <eric@uc.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
