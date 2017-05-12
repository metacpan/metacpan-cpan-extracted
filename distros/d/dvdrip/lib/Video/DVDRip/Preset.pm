# $Id: Preset.pm 2357 2008-10-01 10:03:59Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Preset;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use strict;
use Carp;

sub name			{ shift->{name}				}
sub title			{ shift->{title}			}
sub auto			{ shift->{auto}				}
sub auto_clip			{ shift->{auto_clip}			}
sub frame_size			{ shift->{frame_size}			}

sub tc_clip1_top		{ shift->{tc_clip1_top}			}
sub tc_clip1_bottom		{ shift->{tc_clip1_bottom}		}
sub tc_clip1_left		{ shift->{tc_clip1_left}		}
sub tc_clip1_right		{ shift->{tc_clip1_right}		}
sub tc_zoom_width		{ shift->{tc_zoom_width}		}
sub tc_zoom_height		{ shift->{tc_zoom_height}		}
sub tc_clip2_top		{ shift->{tc_clip2_top}			}
sub tc_clip2_bottom		{ shift->{tc_clip2_bottom}		}
sub tc_clip2_left		{ shift->{tc_clip2_left}		}
sub tc_clip2_right		{ shift->{tc_clip2_right}		}
sub tc_fast_resize		{ shift->{tc_fast_resize}		}

sub set_name			{ shift->{name}			= $_[1]	}
sub set_title			{ shift->{title}		= $_[1]	}
sub set_auto			{ shift->{auto}			= $_[1]	}
sub set_auto_clip		{ shift->{auto_clip}		= $_[1]	}
sub set_frame_size		{ shift->{frame_size}		= $_[1]	}
sub set_tc_clip1_top		{ shift->{tc_clip1_top}		= $_[1]	}
sub set_tc_clip1_bottom		{ shift->{tc_clip1_bottom}	= $_[1]	}
sub set_tc_clip1_left		{ shift->{tc_clip1_left}	= $_[1]	}
sub set_tc_clip1_right		{ shift->{tc_clip1_right}	= $_[1]	}
sub set_tc_zoom_width		{ shift->{tc_zoom_width}	= $_[1]	}
sub set_tc_zoom_height		{ shift->{tc_zoom_height}	= $_[1]	}
sub set_tc_clip2_top		{ shift->{tc_clip2_top}		= $_[1]	}
sub set_tc_clip2_bottom		{ shift->{tc_clip2_bottom}	= $_[1]	}
sub set_tc_clip2_left		{ shift->{tc_clip2_left}	= $_[1]	}
sub set_tc_clip2_right		{ shift->{tc_clip2_right}	= $_[1]	}
sub set_tc_fast_resize		{ shift->{tc_fast_resize}    	= $_[1]	}

sub new {
    my $type = shift;
    my %par  = @_;
    my ( $name, $title, $tc_zoom_width, $tc_zoom_height, $tc_fast_resize )
        = @par{
        'name',          'title',
        'tc_zoom_width', 'tc_zoom_height',
        'tc_fast_resize'
        };
    my ( $tc_clip1_top, $tc_clip1_bottom, $tc_clip1_left, $tc_clip1_right )
        = @par{
        'tc_clip1_top',  'tc_clip1_bottom',
        'tc_clip1_left', 'tc_clip1_right'
        };
    my ( $tc_clip2_top, $tc_clip2_bottom, $tc_clip2_left, $tc_clip2_right )
        = @par{
        'tc_clip2_top',  'tc_clip2_bottom',
        'tc_clip2_left', 'tc_clip2_right'
        };
    my ( $auto, $auto_clip, $frame_size ) = @par{ 'auto', 'auto_clip', 'frame_size' };

    my $self = {
        name            => $name,
        title           => $title,
        auto            => $auto,
        auto_clip       => $auto_clip,
        frame_size      => $frame_size,
        tc_clip1_top    => $tc_clip1_top,
        tc_clip1_bottom => $tc_clip1_bottom,
        tc_clip1_left   => $tc_clip1_left,
        tc_clip1_right  => $tc_clip1_right,
        tc_zoom_width   => $tc_zoom_width,
        tc_zoom_height  => $tc_zoom_height,
        tc_clip2_top    => $tc_clip2_top,
        tc_clip2_bottom => $tc_clip2_bottom,
        tc_clip2_left   => $tc_clip2_left,
        tc_clip2_right  => $tc_clip2_right,
        tc_fast_resize  => $tc_fast_resize,
    };

    return bless $self, $type;
}

sub attributes {
    my $self = shift;

    my @attr = grep /^tc/, keys %{$self};

    return \@attr;
}

1;
