# $Id: Encoding.pm,v 1.2 2004/05/15 15:56:26 cvspetr Exp $

package XML::SAX::ExpatXS::Encoding;
require 5.004;

use strict;
use vars qw(@ISA %Encoding_Table @Encoding_Path $have_File_Spec);
use XML::SAX::ExpatXS;
use Carp;

require DynaLoader;

@ISA = qw(DynaLoader);


$have_File_Spec = $INC{'File/Spec.pm'} || do 'File/Spec.pm';

%Encoding_Table = ();
if ($have_File_Spec) {
  @Encoding_Path = (grep(-d $_,
                         map(File::Spec->catdir($_, qw(XML SAX ExpatXS Encodings)),
                             @INC)),
                    File::Spec->curdir);
}
else {
  @Encoding_Path = (grep(-d $_, map($_ . '/XML/SAX/ExpatXS/Encodings', @INC)), '.');
}
  
sub load_encoding {
  my ($file) = @_;

  $file =~ s!([^/]+)$!\L$1\E!;
  $file .= '.enc' unless $file =~ /\.enc$/;
  unless ($file =~ m!^/!) {
    foreach (@Encoding_Path) {
      my $tmp = ($have_File_Spec
                 ? File::Spec->catfile($_, $file)
                 : "$_/$file");
      if (-e $tmp) {
        $file = $tmp;
        last;
      }
    }
  }

  local(*ENC);
  open(ENC, $file) or croak("Couldn't open encmap $file:\n$!\n");
  binmode(ENC);
  my $data;
  my $br = sysread(ENC, $data, -s $file);
  croak("Trouble reading $file:\n$!\n")
    unless defined($br);
  close(ENC);

  my $name = XML::SAX::ExpatXS::LoadEncoding($data, $br);
  croak("$file isn't an encmap file")
    unless defined($name);

  $name;
}  # End load_encoding


################################################################

package XML::SAX::ExpatXS::Encinfo;

sub DESTROY {
  my $self = shift;
  XML::SAX::ExpatXS::FreeEncoding($self);
}


################################################################

package XML::SAX::ExpatXS::ContentModel;
use overload '""' => \&asString, 'eq' => \&thiseq;

sub EMPTY  () {1}
sub ANY    () {2}
sub MIXED  () {3}
sub NAME   () {4}
sub CHOICE () {5}
sub SEQ    () {6}

sub isempty {
  return $_[0]->{Type} == EMPTY;
}

sub isany {
  return $_[0]->{Type} == ANY;
}

sub ismixed {
  return $_[0]->{Type} == MIXED;
}

sub isname {
  return $_[0]->{Type} == NAME;
}

sub name {
  return $_[0]->{Tag};
}

sub ischoice {
  return $_[0]->{Type} == CHOICE;
}

sub isseq {
  return $_[0]->{Type} == SEQ;
}

sub quant {
  return $_[0]->{Quant};
}

sub children {
  my $children = $_[0]->{Children};
  if (defined $children) {
    return @$children;
  }
  return undef;
}

sub asString {
  my ($self) = @_;
  my $ret;

  if ($self->{Type} == NAME) {
    $ret = $self->{Tag};
  }
  elsif ($self->{Type} == EMPTY) {
    return "EMPTY";
  }
  elsif ($self->{Type} == ANY) {
    return "ANY";
  }
  elsif ($self->{Type} == MIXED) {
    $ret = '(#PCDATA';
    foreach (@{$self->{Children}}) {
      $ret .= '|' . $_;
    }
    $ret .= ')';
  }
  else {
    my $sep = $self->{Type} == CHOICE ? '|' : ',';
    $ret = '(' . join($sep, map { $_->asString } @{$self->{Children}}) . ')';
  }

  $ret .= $self->{Quant} if $self->{Quant};
  return $ret;
}

sub thiseq {
  my $self = shift;

  return $self->asString eq $_[0];
}


1;

__END__

=head1 NAME

XML::SAX::ExpatXS::Encoding - Encoding support for XML::SAX::ExpatXS

=head1 DESCRIPTION

This module is derived from XML::Parser::Expat. It provides XML::SAX::ExpatXS
parser with support of not-built-in encodings. 

=head1 AUTHORS

Larry Wall <F<larry@wall.org>>

and

Clark Cooper <F<coopercc@netheaven.com>> authored XML::Parser::Expat.

Petr Cimprich <F<petr@gingerall.cz>> addapted it for XML::SAX::ExpatXS.

=cut
