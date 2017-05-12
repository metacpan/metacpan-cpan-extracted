package Text::Editor::Easy::Zone;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Zone - A "zone" is a part of a window. Several "Text::Editor::Easy" objects can share the same "zone".
But only one "Text::Editor::Easy" object can be on the top of its zone. So , in a particular zone, only one "Text::Editor::Easy" object is visible.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use threads; # debug
use Scalar::Util qw(refaddr);

# A modifier en une référence de scalaire...
sub new {
    my ( $classe, $hash_ref ) = @_;

    if ( ! defined $hash_ref or ref $hash_ref ne 'HASH' ) {
        $hash_ref = {};
    }

    my $trace_ref = $hash_ref->{'trace'};
    if ( $trace_ref ) {

# Hash "%Trace" must be seen by all future created threads but needn't be  a shared hash
# ===> will be duplicated by perl thread creation mecanism
        %Text::Editor::Easy::Trace = %{$trace_ref};
        delete $hash_ref->{'trace'};
    }
    #Text::Editor::Easy::trace_test();

    #Text::Editor::Easy::Comm::verify_model_thread( $trace_ref );
    my $zone = bless $hash_ref, $classe;
    my $name = $hash_ref->{'name'};
    if ( defined $name ) {
        # le thread Data n'est peut être pas opérationnel
        #Text::Editor::Easy::Async->reference_zone($hash_ref);
        Text::Editor::Easy->reference_zone($hash_ref);
    }
    if ( my $event_ref = $hash_ref->{'events'} ) {
        #print "Des évènements pour la zone $name\n";
        Text::Editor::Easy->reference_zone_events( $name, $event_ref );
    }

    return $zone;
}

sub whose_name {
    my ( $self, $name ) = @_;

    return if ( !defined $name );
    return Text::Editor::Easy->zone_named($name);
}

sub coordinates {
    my ( $self ) = @_;
    
    my ( $win_width, $win_height, $win_x, $win_y ) = Text::Editor::Easy->window->get;
    
    #print "WIN X = $win_x\n";
    no warnings;
    my $size_ref = $self->{'size'};
    my $x = $size_ref->{'-x'} + $size_ref->{'-relx'}*$win_width;
    my $y = $size_ref->{'-y'} + $size_ref->{'-rely'}*$win_height;
    my $height = $size_ref->{'-height'} + $size_ref->{'-relheight'}*$win_height;
    my $width = $size_ref->{'-width'} + $size_ref->{'-relwidth'}*$win_width;
    return ( $x, $y, $width, $height );
}

sub on_top_editor {
    my ( $self ) = @_;
    
    print "Dans on_top_editor de Zone ", $self->{'name'}, "\n";
    
    my $id = Text::Editor::Easy->on_top_ref_editor($self);
    print "Dans on_top_editor de Zone ", $self->{'name'}, ", id = $id\n";
    return Text::Editor::Easy->get_from_id( $id );
}

sub list {
    my ($self, $complete) = @_;

    return Text::Editor::Easy->zone_list( $complete );
}

my %resize_sub = (
    'right' => \&resize_right,
    'left' => \&resize_left,
    'top' => \&resize_top,
    'bottom' => \&resize_bottom,
);

sub resize {
    my ( $self, $where, $how_many_ref, @coordinates ) = @_;
    
    #print "Dans resize de Zone : where = $where|@coordinates| tid = ", threads->tid, "\n";
    return if ( ! defined $where or ! defined $resize_sub{$where} );
    $resize_sub{ $where }->( $self, $how_many_ref, @coordinates );
    return;
}

sub resize_right {
    my ( $self, $how_many_ref, @coordinates ) = @_;
    # Seul "x" de $options_ref nous intéresse
    #print "x vaut $how_many_ref->{'x'}\n";
    my $new_zone_ref = {
        'name' => $self->{'name'},
        'size' => {
            '-x' => $coordinates[0],
            '-y' => $coordinates[1],
            '-width' => $how_many_ref->{'x'},
            '-height' => $coordinates[3],
        },
    };
    Text::Editor::Easy->reference_zone($new_zone_ref);
    Text::Editor::Easy->graphic_zone_update( $self->{'name'}, $new_zone_ref );
}

sub resize_left {
    my ( $self, $how_many_ref, @coordinates ) = @_;
    # Seul "x" de $options_ref nous intéresse
    print "x vaut $how_many_ref->{'x'}\n";
    my $new_zone_ref = {
        'name' => $self->{'name'},
        'size' => {
            '-x' => $coordinates[0] + $how_many_ref->{'x'},
            '-y' => $coordinates[1],
            '-width' => $coordinates[2] - $how_many_ref->{'x'},
            '-height' => $coordinates[3],
        },
    };
    Text::Editor::Easy->reference_zone($new_zone_ref);
    Text::Editor::Easy->graphic_zone_update( $self->{'name'}, $new_zone_ref );
}

sub resize_top {
    my ( $self, $how_many_ref, @coordinates ) = @_;
    # Seul "y" de $how_many_ref nous intéresse
    print "y vaut $how_many_ref->{'y'}\n";
    my $new_zone_ref = {
        'name' => $self->{'name'},
        'size' => {
            '-x' => $coordinates[0],
            '-y' => $coordinates[1] + $how_many_ref->{'y'},
            '-width' => $coordinates[2],
            '-height' => $coordinates[3] - $how_many_ref->{'y'},
        },
    };
    Text::Editor::Easy->reference_zone($new_zone_ref);
    Text::Editor::Easy->graphic_zone_update( $self->{'name'}, $new_zone_ref );
}

sub resize_bottom {
    my ( $self, $how_many_ref, @coordinates ) = @_;
    # Seul "y" de $how_many_ref nous intéresse
    print "y vaut $how_many_ref->{'y'}\n";
    my $new_zone_ref = {
        'name' => $self->{'name'},
        'size' => {
            '-x' => $coordinates[0],
            '-y' => $coordinates[1],
            '-width' => $coordinates[2],
            '-height' => $how_many_ref->{'y'},
        },
    };
    Text::Editor::Easy->reference_zone($new_zone_ref);
    Text::Editor::Easy->graphic_zone_update( $self->{'name'}, $new_zone_ref );
}

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;


















