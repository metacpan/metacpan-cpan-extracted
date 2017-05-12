package UR::Object::View::Default::Html;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
use IO::File;

class UR::Object::View::Default::Html {
    is => 'UR::Object::View::Default::Xsl',
    has => {
        output_format => { value => 'html' },
        transform => { value => 1 },
        toolkit => { value => 'html' },
    }
};

1;

=pod

=head1 NAME

UR::Object::View::Default::Html - represent object state in HTML format 

=head1 SYNOPSIS

  #####
  
  package Acme::Product::View::OrderStatus::Html;

  class Acme::Product::View::OrderStatus::Html {
    is => 'UR::Object::View::Default::Html',
  };

  sub _generate_content {
    my $self = shift;
    my $subject = $self->subject;
    my $html = ...
    ....
    return $html;
  }

  #####

  $o = Acme::Product->get(1234);

  $v = $o->create_view(
      perspective => 'order status',
      toolkit => 'html',
      aspects => [
        'id',
        'name',
        'qty_on_hand',
        'outstanding_orders' => [   
          'id',
          'status',
          'customer' => [
            'id',
            'name',
          ]
        ],
      ],
  );

  $html1 = $v->content;

  $o->qty_on_hand(200);
  
  $html2 = $v->content;

=head1 DESCRIPTION

This class implements basic HTML views of objects.  It has standard behavior for all text views.

=head1 SEE ALSO

UR::Object::View::Default::Text, UR::Object::View, UR::Object::View::Toolkit::XML, UR::Object::View::Toolkit::Text, UR::Object

=cut

