package WebSource::Parser;

use strict;
use XML::LibXML;
use HTML::TreeBuilder;

{
  package MyTreeBuilder;
  our @ISA = ('HTML::TreeBuilder');

  sub start {
    my ($self,$tag,$attr,$attrseq,$origtext) =@_;
    my %nattr;
    my @naseq;
    # Clean up attributes
    foreach my $a (@$attrseq) {
      if($a =~ m#[^\w_:\-]#) {
        $self->{verbose} and warn "Bad attribute $a detected and removed";
      } else {
        push @naseq, ($a);
        $nattr{$a} = $attr->{$a};
      }
    }
    $self->SUPER::start($tag,\%nattr,\@naseq,$origtext);
  }
  sub text {
    my ($self,$origtext,$iscdata) = @_;
    if(!$iscdata) {
      $origtext =~ /Sion/ and print "Text : $origtext\n";
      if($origtext =~ m/\0/) {
        $self->{verbose} and warn "Decected null char\n";
        $origtext =~ s/\0//g;
      }
      if($origtext =~ m/\&\#[0-9]\;/) {
        warn "Bad entity detected";
        $origtext =~ s/\&\#[0-9]\;//g;
       }
    }
    $self->SUPER::text($origtext,$iscdata);
  }

}

our @ISA = ("XML::LibXML");
=head1 NAME

WebSource::Parser - A XML/HTML parser extending XML::LibXML

=head1 DESCRIPTION

A simple XML::LibXML extention to be more robust in parsing HTML by
using HTML::TreeBuilder

=head1 SYNOPSIS

my $parser = WebSource::Parser->new;

=head1 METHODS

=over 2

=item B<< $parser = WebSource::Parser->new; >>

Create a new WebSource::Parser

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(verbose => 1, @_);
  return $self;
}

=item B<< $parser->parse_html_file($file); >>

Parse an html file

=cut

sub parse_html_file {
  my $self = shift;
  my $file = shift;
  my $tb = MyTreeBuilder->new;
#  $tb->xml_mode(1);
  $tb->parse_file($file);
  return $self->SUPER::parse_string($tb->as_XML);
}

=item B<< $parser->parse_html_string($string); >>

Parse an html string

=cut

sub parse_html_string {
  my $self = shift;
  my $string = shift;
  my $tb = MyTreeBuilder->new;
  $tb->parse($string);
  $tb->eof;
  return $self->SUPER::parse_string($tb->as_XML);
}

=item B<< $parser->parse_html_string($string); >>

Parse an HTML string chunk and return the corresponding nods

=cut

sub parse_html_chunks {
  my $self = shift;
  my $string = shift;
  my $tb = MyTreeBuilder->new;
  $tb->parse($string);
  $tb->eof;
  return map { $self->SUPER::parse_string($tb->as_XML) } $tb->guts();
}

=head1 SEE ALSO

  XML::LibXML

=cut

1;
