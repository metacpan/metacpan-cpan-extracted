package XML::Handler::Machine2GraphViz;

=head1 NAME

XML::Handler::Machine2GraphViz;

=head1 SYNOPSIS

    use XML::Filter::Machine2GraphViz;

    my $m = Machine( .... );
    binmode STDOUT;

  ## Short form:

    print machine_2_graphviz( $m )->as_png;
    
  ## Long form:

    my $h = XML::Handler::Machine2GraphViz->new;

    $m->generate_description( $h );

    print $h->graphviz->as_png;

=head1 DESCRIPTION

A SAX2 processor that turns SAX machine descriptions in to a GraphViz object.

=cut

$VERSION = 0.2;

use XML::Filter::Dispatcher;
use Exporter;

@ISA = qw( XML::Filter::Dispatcher Exporter );

@EXPORT = qw( machine2graphviz );
%EXPORT_TAGS = ( all => \@EXPORT );

use strict;
use GraphViz;

sub _empty($) { !defined $_[0] || ! length $_[0] }

sub new {
    my $proto = shift;

    my $self = $proto->SUPER::new(
        Rules => {
            "//part" => sub {
                my ( $self, $elt ) = @_;

                my $attrs = $elt->{Attributes};
                my $id    = $attrs->{id}->{Value};
                my $desc  = $attrs->{description}->{Value};
                my $type  = $attrs->{type}->{Value};
                my $name  = $attrs->{name}->{Value};

                $self->push( {
                    id => $id,
                } );

                my $label = $desc;

                if ( _empty $label ) {
                    $label = $name || "";
                    $label .= "($type)" if ! _empty $type;
                    $label = "<<Unnamed, id= $id>>" if _empty $label;
                }

                $label =~ s/ *\(/\\n(/;

                $self->{GraphViz}->add_node(
                    $id,
                    label => $label,
                    fontsize => 12,
                    fontname => "Helvetica",
                );

            },

            "//sax-machine" => \&XML::Filter::Dispatcher::push,

            ## studiously avoid machine handlers, they're redundant and
            ## we can't properly graph machines until GraphViz.pm
            ## supports nested graphs :)
            "//part/handler" => sub {
                my ( $self, $elt ) = @_;

                my $attrs = $elt->{Attributes};
                my $handler_id = $attrs->{"handler-id"}->{Value};
                my $handler_name = $attrs->{"name"}->{Value};

                ## This usually happens only for Exhaust nodes.
                return if _empty $handler_id;

                $self->{GraphViz}->add_edge(
                    $self->peek->{id},
                    $handler_id
                );
            },
        },
    );

    return $self;
}


sub start_document {
    my $self = shift;

    $self->{GraphViz} = GraphViz->new(
        rankdir => "LR",
    );

    $self->SUPER::start_document( @_ );
}


sub graphviz {
    return shift()->{GraphViz};
}


sub machine2graphviz {
    my $machine = shift;

    my $h = __PACKAGE__->new;
    $machine->generate_description( $h );
    $h->graphviz || GraphViz->new;
}


=head1 LIMITATIONS

Exports 1 functio by default, do

    use XML::Filter::Machine2GraphViz ();

to prevent this.

Does not show the machines yet, GraphViz.pm needs to be upgraded to deal with
nested graphs to do this.  It does clustering, but not nested graphs at the
moment (v1.4).

=head1 AUTHOR

    Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

    Copyright 2002, Barrie Slaymaker, All Rights Reserved.

You may use this module under the terms of the Artistic, GNU Public, or
BSD licenses, your choise.

=cut

1;
