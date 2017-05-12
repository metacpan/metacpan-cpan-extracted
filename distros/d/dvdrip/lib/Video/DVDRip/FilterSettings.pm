# $Id: FilterSettings.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::FilterSettings;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;
use Video::DVDRip::FilterList;

use Carp;
use strict;

sub filters			{ shift->{filters}			}

sub new {
    my $class = shift;

    my $self = {
        # list of FilterSettingsInstance objects
        filters => [],
    };

    return bless $self, $class;
}

sub get_selected_filters {
    my $self = shift;

    my @selected;
    my $filters = Video::DVDRip::FilterList->get_filter_list->filters;

    foreach my $filter_instance ( @{ $self->filters } ) {
        push @selected, $filter_instance
            if exists $filters->{ $filter_instance->filter_name };
    }

    return \@selected;
}

sub get_filter_instance {
    my $self = shift;
    my %par  = @_;
    my ($id) = @par{'id'};

    foreach my $filter_instance ( @{ $self->filters } ) {
        return $filter_instance if $filter_instance->id == $id;
    }

    croak "can't find filter instance with id $id";
}

sub get_filter_instance_index {
    my $self = shift;
    my %par  = @_;
    my ($id) = @par{'id'};

    my $i       = 0;
    my $filters = $self->filters;

    ++$i while $i < @{$filters} and $filters->[$i]->id != $id;

    croak "can't find filter filter instance with id $id"
        if $i == @{$filters};

    return $i;
}

sub get_next_filter_instance_id {
    my $self = shift;

    my $max_id;
    foreach my $filter_instance ( @{ $self->filters } ) {
        $max_id = $filter_instance->id
            if $filter_instance->id > $max_id;
    }

    return $max_id + 1;
}

sub allocate_suffixes {
    my $self = shift;

    my %suffix_cnt = ();

    foreach my $filter ( @{ $self->filters } ) {
        my $suffix = $suffix_cnt{ $filter->filter_name }++ || 0;
        $filter->set_suffix($suffix);
    }

    1;
}

sub set_value {
    my $self = shift;
    my %par  = @_;
    my ( $id, $option, $idx, $value )
        = @par{ 'id', 'option', 'idx', 'value' };

    $self->get_filter_instance( id => $id )->set_value(
        option => $option,
        idx    => $idx,
        value  => $value,
    );

    1;
}

sub get_value {
    my $self = shift;
    my %par  = @_;
    my ( $id, $option, $idx ) = @par{ 'id', 'option', 'idx' };

    return $self->get_filter_instance( id => $id )->get_value(
        option => $option,
        idx    => $idx,
    );
}

sub check_filter_color_mode_ok {
    my $self          = shift;
    my %par           = @_;
    my ($filter_name) = @par{'filter_name'};

    my $filter
        = Video::DVDRip::FilterList->get_filter( filter_name => $filter_name,
        );

    return 1 if $filter->can_rgb and $filter->can_yuv;
    return 1 if !$filter->can_video;

    foreach my $instance ( @{ $self->filters } ) {
        next if !$instance->get_filter->can_video;
        if ( $filter->can_rgb ) {
            if ( not $instance->get_filter->can_rgb ) {
                croak "msg:Filter is RGB only, but you "
                    . "selected non RGB filters already.";
            }
        }
        else {
            if ( not $instance->get_filter->can_yuv ) {
                croak "msg:Filter is YUV only, but you "
                    . "selected non YUV filters already.";
            }
        }
    }

    1;
}

sub add_filter {
    my $self          = shift;
    my %par           = @_;
    my ($filter_name) = @par{'filter_name'};

    $self->check_filter_color_mode_ok( filter_name => $filter_name );

    my $filter_instance = Video::DVDRip::FilterSettingsInstance->new(
        id          => $self->get_next_filter_instance_id,
        filter_name => $filter_name,
    );

    push @{ $self->filters }, $filter_instance;

    return $filter_instance;
}

sub del_filter {
    my $self = shift;
    my %par  = @_;
    my ($id) = @par{'id'};

    my $index = $self->get_filter_instance_index( id => $id );
    my ($instance) = splice @{ $self->filters }, $index, 1;

    return $instance;
}

sub filter_used {
    my $self          = shift;
    my %par           = @_;
    my ($filter_name) = @par{'filter_name'};

    foreach my $filter_instance ( @{ $self->filters } ) {
        return 1 if $filter_instance->filter_name eq $filter_name;
    }

    return 0;
}

sub move_instance {
    my $self = shift;
    my %par  = @_;
    my ( $id, $before_id ) = @par{ 'id', 'before_id' };

    return if $id == 0;               # no move of 'pre', 'post' markers
    return if $before_id eq "pre";    # 'pre' marker is topmost

    my $from_instance = $self->get_filter_instance( id => $id );
    my $from_filter   = $from_instance->get_filter;

    my $append_to_pre;
    if ( $before_id eq 'post' ) {
        $append_to_pre = 1;
        $before_id     = $self->get_first_post_filter_instance->id;
    }

    my ( $before_instance, $before_filter );
    $before_instance = $self->get_filter_instance( id => $before_id )
        if $before_id;
    $before_filter = $before_instance->get_filter
        if $before_instance;

    # no post in pre queue
    return if not $from_filter->is_pre and $append_to_pre;

    # no post before pre
    return
        if not $from_filter->is_pre
        and $before_instance
        and $before_instance->queue eq 'pre';

    # no pre at the end
    return if not $from_filter->is_post and not $before_instance;

    # no pre before post, if we don't append it to the pre list
    return
        if not $append_to_pre
        and not $from_filter->is_post
        and $before_instance
        and $before_instance->queue eq 'post';

    # queue move?
    if ($from_instance->queue eq 'pre'
        and ( not $before_instance
            or $before_instance && $before_instance->queue eq 'post' )
        ) {
        $from_instance->set_queue("post");
        $from_instance->set_value(
            option_name => "pre",
            value       => 0,
            idx         => 0
        );
    }
    elsif (
        $from_instance->queue eq 'post'
        and (  $append_to_pre
            or $before_instance && $before_instance->queue eq 'pre' )
        ) {
        $from_instance->set_queue("pre");
        $from_instance->set_value(
            option_name => "pre",
            value       => 1,
            idx         => 0
        );
    }

    my $from_idx = $self->get_filter_instance_index( id => $id );
    my $to_idx = $before_id
        ? $self->get_filter_instance_index( id => $before_id )
        : @{ $self->filters };

    if ( $from_idx < $to_idx ) {
        splice @{ $self->filters }, $to_idx, 0, $self->filters->[$from_idx];
        splice @{ $self->filters }, $from_idx, 1;
    }
    else {
        splice @{ $self->filters }, $to_idx, 0, $self->filters->[$from_idx];
        splice @{ $self->filters }, $from_idx + 1, 1;
    }

    1;
}

sub get_first_post_filter_instance {
    my $self = shift;

    foreach my $instance ( @{ $self->filters } ) {
        return $instance if $instance->post;
    }

    return;
}

sub get_prepend_instance {
    my $self = shift;
    my %par  = @_;
    my ($id) = @par{'id'};

    my $prepend_instance;
    foreach my $instance ( @{ $self->filters } ) {
        return $prepend_instance if $instance->id == $id;
        $prepend_instance = $instance;
    }

    return;
}

sub get_filter_config_strings {
    my $self            = shift;
    my %par             = @_;
    my ($with_suffixes) = @par{'with_suffixes'};

    $self->allocate_suffixes if $with_suffixes;

    my @config_strings;
    foreach my $instance ( @{ $self->filters } ) {
        my $filter_name = $instance->filter_name;
        $filter_name .= "#" . $instance->suffix
            if $with_suffixes
            and $instance->suffix;

        push @config_strings,
            {
            filter  => $filter_name,
            options => $instance->get_config_string,
            enabled => $instance->enabled,
            };
    }

    return \@config_strings;
}

sub get_max_frames_needed {
    my $self = shift;

    my $max_frames_needed = 0;

    foreach my $instance ( @{ $self->filters } ) {
        $max_frames_needed = $instance->get_filter->frames_needed
            if $instance->get_filter->frames_needed > $max_frames_needed;
    }

    return $max_frames_needed;
}

package Video::DVDRip::FilterSettingsInstance;
use Locale::TextDomain qw (video.dvdrip);

use Carp;

sub id				{ shift->{id}				}
sub filter_name			{ shift->{filter_name}			}
sub options			{ shift->{options}			}

sub suffix			{ shift->{suffix}			}
sub queue			{ shift->{queue}			}
sub enabled			{ shift->{enabled}			}

sub set_suffix			{ shift->{suffix}		= $_[1]	}
sub set_queue			{ shift->{queue}		= $_[1]	}
sub set_enabled			{ shift->{enabled}		= $_[1]	}

sub post			{ not shift->{pre}			}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $id, $filter_name, $suffix ) = @par{ 'id', 'filter_name', 'suffix' };

    my $self = bless {
        id          => $id,
        filter_name => $filter_name,
        suffix      => $suffix,
        enabled     => 1,
        options     => {},
        queue       => 'pre',
    }, $class;

    $self->set_queue('post')
        if $self->get_filter->is_post
        and not $self->get_filter->is_pre_post;

    $self->set_queue('post')
        if $self->get_filter->is_pre_post
        and
        not eval { $self->get_filter->get_option( option_name => 'pre' )->fields->[0]
        ->default };

    return bless $self, $class;
}

sub get_filter {
    my $self = shift;

    return Video::DVDRip::FilterList->get_filter(
        filter_name => $self->filter_name );
}

sub set_value {
    my $self = shift;
    my %par  = @_;
    my ( $option_name, $idx, $value ) = @par{ 'option_name', 'idx', 'value' };

    my $filter_name = $self->filter_name;
    my $fields = $self->get_filter->get_option( option_name => $option_name )
        ->fields;

    if ( $idx < 0 or $idx >= @{$fields} ) {
        croak "msg:Illegal field index $idx (filter $filter_name, "
            . "option $option_name)";
    }

    my $field = $fields->[$idx];

    my $range_from = $field->range_from;
    my $range_to   = $field->range_to;

    if (    $range_from <= $value
        and $range_to >= $value ) {
        $self->options->{$option_name}->[$idx] = $value;
    }
    else {
        return;
    }

    1;
}

sub get_value {
    my $self = shift;
    my %par  = @_;
    my ( $option_name, $idx ) = @par{ 'option_name', 'idx' };

    my $filter_name = $self->filter_name;
    my $fields = $self->get_filter->get_option( option_name => $option_name )
        ->fields;

    if ( $idx < 0 or $idx >= @{$fields} ) {
        croak "msg:Illegal field index $idx (filter $filter_name, "
            . "option $option_name)";
    }

    return $fields->[$idx]->default
        if not defined $self->options->{$option_name}->[$idx];

    return $self->options->{$option_name}->[$idx];
}

sub get_config_string {
    my $self = shift;

    my $filter = $self->get_filter;

    my $config;
    foreach my $option ( @{ $filter->options } ) {
        if ( $option->switch ) {
            if ($self->get_value(
                    option_name => $option->option_name,
                    idx         => 0
                )
                ) {
                $config .= ":" . $option->option_name;
            }
            next;
        }
        my @values;
        for ( my $idx = 0; $idx < @{ $option->fields }; ++$idx ) {
            push @values,
                $self->get_value(
                option_name => $option->option_name,
                idx         => $idx,
                );
        }
        next if join( '', @values ) eq '';
        $config .= ":" . $option->option_name . "=";
        $config .= sprintf( $option->format, @values );
    }

    $config =~ s/^://;

    return $config;
}

1;
