package UR::Object::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

class UR::Object::View::Default::Text {
    is => 'UR::Object::View',
    has_constant => [
        perspective => { value => 'default' },
        toolkit     => { value => 'text' },
    ],
    has => [
        indent_text => { is => 'Text', default_value => '  ', doc => 'indent child views with this text' },
    ],
};

# general view API

sub _create_widget {
    # The "widget" for a text view is a pair of items:
    # - a scalar reference to hold the content
    # - an I/O handle to which it will display (the "window" it lives in)

    # Note that the former could be something tied to an object, 
    # a file, or other external storage, though it is 
    # simple by default.  The later might also be tied.
    
    # The later is STDOUT unless overridden/changed.
    my $self = shift;
    my $scalar_ref = '';
    my $fh = 'STDOUT';
    return [\$scalar_ref,$fh];
}

sub show {
    # Showing a text view typically prints to STDOUT
    my $self = shift;
    my $widget = $self->widget();
    my ($content_ref,$output_stream) = @$widget;
    $output_stream->print($$content_ref,"\n");
}

sub _update_subject_from_view {
    Carp::confess('currently text views are read-only!');
}

sub _update_view_from_subject {
    my $self = shift;
    my $content = $self->_generate_content(@_);
    my $widget = $self->widget();
    my ($content_ref,$fh) = @$widget;
    $$content_ref = $content;
    return 1;
}

# text view API

sub content {
    # retuns the current value of the scalar ref containing the text content.
    my $self = shift;

    my $widget = $self->widget();
    if (@_) {
        die "the widget reference for a view isn't changeable.  change its content.."; 
    }
    my ($content_ref,$output_stream) = @$widget;
    return $$content_ref;
}

sub output_stream {
    # retuns the current value of the handle to which we render.
    my $self = shift;
    my $widget = $self->widget();
    if (@_) {
        return $widget->[1] = shift;
    }
    my ($content_ref,$output_stream) = @$widget;
    return $output_stream;
}

sub _generate_content {
    my $self = shift;

    # the header line is the class followed by the id
    my $text = $self->subject_class_name;
    $text =~ s/::/ /g;
    my $subject = $self->subject();
    if ($subject) {
        my $subject_id_txt = $subject->id;
        $subject_id_txt = "'$subject_id_txt'" if $subject_id_txt =~ /\s/;
        $text .= " $subject_id_txt";
    }

    # Don't recurse back into something we're already in the process of showing
    if ($self->_subject_is_used_in_an_encompassing_view()) {
        $text .= " (REUSED ADDR)\n";
    } else {
        $text .= "\n";
        # the content for any given aspect is handled separately
        my @aspects = $self->aspects;
        my @sorted_aspects = map { $_->[1] }
                             sort { $a->[0] <=> $b->[0] }
                             map { [ $_->number, $_ ] }
                             @aspects;
        for my $aspect (@sorted_aspects) {
            next if $aspect->name eq 'id';
            my $aspect_text = $self->_generate_content_for_aspect($aspect);
            $text .= $aspect_text;
        }
    }

    return $text;
}

sub _generate_content_for_aspect {
    # This does two odd things:
    # 1. It gets the value(s) for an aspect, then expects to just print them
    #    unless there is a delegate view.  In which case, it replaces them 
    #    with the delegate's content.
    # 2. In cases where more than one value is returned, it recycles the same
    #    view and keeps the content.
    # 
    # These shortcuts make it hard to abstract out logic from toolkit-specifics

    my $self = shift;
    my $aspect = shift;

    my $subject = $self->subject;  
    my $indent_text = $self->indent_text;

    my $aspect_text = $indent_text . $aspect->label . ": ";

    if (!$subject) {
        $aspect_text .= "-\n";
        return $aspect_text;
    }

    my $aspect_name = $aspect->name;

    my @value;
    eval {
        @value = $subject->$aspect_name;
    };

    if (@value == 0) {
        $aspect_text .= "-\n";
        return $aspect_text;
    }

    if (@value == 1 and ref($value[0]) eq 'ARRAY') {
        @value = @{$value[0]};
    }

    unless ($aspect->delegate_view) {
        $aspect->generate_delegate_view;
    }

    # Delegate to a subordinate view if needed.
    # This means we replace the value(s) with their
    # subordinate widget content.
    if (my $delegate_view = $aspect->delegate_view) {
        # TODO: it is bad to recycle a view here??
        # Switch to a set view, which is the standard lister.
        foreach my $value ( @value ) {
            if (Scalar::Util::blessed($value)) {
                $delegate_view->subject($value);
            }
            else {
                $delegate_view->subject_id($value);
            }
            $delegate_view->_update_view_from_subject();
            $value = $delegate_view->content();
        }
    }

    if (@value == 1 and defined($value[0]) and index($value[0],"\n") == -1) {
        # one item, one row in the value or sub-view of the item:
        $aspect_text .= $value[0] . "\n";
    }
    else {
        my $aspect_indent;
        if (@value == 1) {
            # one level of indent for this sub-view's sub-aspects
            # zero added indent for the identity line b/c it's next-to the field label

            # aspect1: class with id ID
            #  sub-aspect1: value1
            #  sub-aspect2: value2
            $aspect_indent = $indent_text;
        }
        else {
            # two levels of indent for this sub-view's sub-aspects
            # just one level for each identity

            # aspect1: ... 
            #  class with id ID
            #   sub-aspect1: value1
            #   sub-aspect2: value2
            #  class with id ID
            #   sub-aspect1: value1
            #   sub-aspect2: value2
            $aspect_text .= "\n";
            $aspect_indent = $indent_text . $indent_text;
        }

        for my $value (@value) {
            my $value_indented = '';
            if (defined $value) {
                my @rows = split(/\n/,$value);
                $value_indented = join("\n", map { $aspect_indent . $_ } @rows);
                chomp $value_indented;
            }
            $aspect_text .= $value_indented . "\n";
        }
    }
    return $aspect_text;
}

1;


=pod

=head1 NAME

UR::Object::View::Default::Text - object views in text format

=head1 SYNOPSIS

  $o = Acme::Product->get(1234);

  # generates a UR::Object::View::Default::Text object:
  $v = $o->create_view(
      toolkit => 'text',
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


  $txt1 = $v->content;

  $o->qty_on_hand(200);
  
  $txt2 = $v->content;


=head1 DESCRIPTION

This class implements basic text views of objects.  It is used for command-line tools,
and is the base class for other specific text formats like XML, HTML, JSON, etc.

=head1 WRITING A SUBCLASS

  # In Acme/Product/View/OutstandingOrders/Text.pm

  package Acme::Product::View::OutstandingOrders::Text;
  use UR;

  class Acme::Product::View::OutstandingOrders::Text { 
    is => 'UR::Object::View::Default::Text' 
  };

  sub _initial_aspects {
    return (
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
    );
  }

  $v = $o->create_view(perspective => 'outstanding orders', toolkit => 'text');
  print $v->content;

=head1 SEE ALSO

UR::Object::View, UR::Object::View::Toolkit::Text, UR::Object

=cut

