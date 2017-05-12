package Wx::Perl::PodEditor::XMLParser;

use strict;
use warnings;
use XML::Twig;

our $VERSION = 0.01;

sub new {
    my ($class) = @_;
    
    my $self = bless {}, $class;
    
    $self;
}

sub parse {
    my ($self,$xml) = @_;
    
    my $twig = XML::Twig->new(
        twig_handlers => {
            'symbol'                   => \&_process_symbol,
            'paragraph[@fontsize="18"]' => \&_head1,
            'paragraph[@fontsize="16"]' => \&_head2,
            'paragraph[@fontsize="14"]' => \&_head3,
            'paragraph[@fontsize="12"]' => \&_head4,
            'paragraph[@fontsize="10"]' => \&_text,
        },
    );
    
    $twig->{pod}  = "=pod\n\n";
    $twig->parse( $xml );
    $twig->{pod} .= "=cut";
    
    $twig->{pod};
}

sub _head1 {
    my ($obj,$elem) = @_;
    
    $obj->{podhead}   = 18;
    $obj->{paragraph} = 1;
    
    _head( $obj, $elem );
}

sub _head2 {
    my ($obj,$elem) = @_;
    
    $obj->{podhead}   = 16;
    $obj->{paragraph} = 1;
    
    _head( $obj, $elem );
}

sub _head3 {
    my ($obj,$elem) = @_;
    
    $obj->{podhead}   = 14;
    $obj->{paragraph} = 1;
    
    _head( $obj, $elem );
}

sub _head4 {
    my ($obj,$elem) = @_;
    
    $obj->{podhead}   = 12;
    $obj->{paragraph} = 1;
    
    _head( $obj, $elem );
}

sub _text {
    my ($twig,$elem) = @_;
    
    $twig->{pod} .= $elem->text . "\n";
}

sub _process_symbol {
    my ($twig,$elem) = @_;
    
    my $symbol = $elem->text;
    $twig->{pod} .= chr( $symbol );
}

sub _process_text {
    my ($obj,$elem) = @_;
    
    my $weight  = $elem->{att}->{fontweight};
    my $style   = $elem->{att}->{fontstyle};
    my $text    = $elem->text;
    my $is_head = 0;
    
    if( defined $obj->{podhead} ){
        #$obj->{pod} .= _head( $obj );
        _head( $obj );
        $is_head     = 1;
    }
    
    if( defined $weight ){
        $obj->{pod} .= 'B<' . $text . '>';
    }
    
    if( defined $style ){
        $obj->{pod} .= 'I<' . $text . '>';
    }

    if( not defined $weight and 
        not defined $style and 
        not defined $obj->{podhead} ){
        $text =~ s/"//g;
        $obj->{pod} .=  $text;
        if( $is_head ){
            $obj->{pod} .= "\n\n";
            $is_head     = 0;
        }
    }

}

sub _head {
    my ($twig,$elem) = @_;
    
    my %map = (
        18 => 1,
        16 => 2,
        14 => 3,
        12 => 4,
    );
    
    $twig->{pod} .= '=head' . $map{ $twig->{podhead} } . " " . $elem->text . "\n";
    $twig->{podhead} = undef;
}


1;

=head1 NAME

Wx::Perl::PodEditor::XMLParser - Parser for the XML exported by the RichTextCtrl

=head1 SYNOPSIS

=head1 SAMPLE XML

  <?xml version="1.0" encoding="UTF-8"?>
  <richtext version="1.0.0.0" xmlns="http://www.wxwidgets.org">
    <paragraphlayout textcolor="#000000" fontsize="8" fontstyle="90" fontweight="0" fontunderlined="0" fontface="MS Shell Dlg 2" alignment="1" parspacingafter="0" parspacingbefore="0" linespacing="10">
      <paragraph fontsize="18" leftindent="0" leftsubindent="0">
        <text>ljfsldj</text>
      </paragraph>
      <paragraph fontsize="10" leftindent="0" leftsubindent="0">
        <text></text>
      </paragraph>
      <paragraph fontsize="10" leftindent="0" leftsubindent="0">
        <text>asldj</text>
      </paragraph>
    </paragraphlayout>
  </richtext>