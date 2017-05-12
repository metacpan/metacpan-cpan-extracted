# $Id: FilterList.pm 2287 2007-03-17 16:53:44Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::FilterList;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;
use Data::Dumper;
use FileHandle;

use Video::DVDRip::CPAN::Scanf;

my $DEBUG = 0;

my $FILTER_LIST;
my %FILTER_SELECTION_CB = (
    logo => sub {
        my %par = @_;
        my ( $x1, $y1, $x2, $y2, $filter_setting )
            = @par{ 'x1', 'y1', 'x2', 'y2', 'filter_setting' };

        $filter_setting->set_value(
            option_name => 'pos',
            idx         => 0,
            value       => $x1,
        );

        $filter_setting->set_value(
            option_name => 'pos',
            idx         => 1,
            value       => $y1,
        );

        1;
    },
    logoaway => sub {
        my %par = @_;
        my ( $x1, $y1, $x2, $y2, $filter_setting )
            = @par{ 'x1', 'y1', 'x2', 'y2', 'filter_setting' };

        $filter_setting->set_value(
            option_name => 'pos',
            idx         => 0,
            value       => $x1,
        );

        $filter_setting->set_value(
            option_name => 'pos',
            idx         => 1,
            value       => $y1,
        );

        $filter_setting->set_value(
            option_name => 'size',
            idx         => 0,
            value       => $x2 - $x1,
        );

        $filter_setting->set_value(
            option_name => 'size',
            idx         => 1,
            value       => $y2 - $y1,
        );

        1;
    },
    mask => sub {
        my %par = @_;
        my ( $x1, $y1, $x2, $y2, $filter_setting )
            = @par{ 'x1', 'y1', 'x2', 'y2', 'filter_setting' };

        $filter_setting->set_value(
            option_name => 'lefttop',
            idx         => 0,
            value       => $x1,
        );

        $filter_setting->set_value(
            option_name => 'lefttop',
            idx         => 1,
            value       => $y1,
        );

        $filter_setting->set_value(
            option_name => 'rightbot',
            idx         => 0,
            value       => $x2,
        );

        $filter_setting->set_value(
            option_name => 'rightbot',
            idx         => 1,
            value       => $y2,
        );

        1;
    },
);

sub filters			{ shift->{filters}			}
sub set_filters			{ shift->{filters}		= $_[1]	}

sub get_filter_list {
    my $class = shift;

    # cache instance per process
    return $FILTER_LIST if $FILTER_LIST;

    my $dir      = "$ENV{HOME}/.dvdrip";
    my $filename = "$dir/tc_filter_list";

    mkdir $dir, 0755 or die "can't create $dir" if not -d $dir;

    my $transcode_modpath = qx[ tcmodinfo -p 2>/dev/null ];
    chomp $transcode_modpath;

    $DEBUG && print STDERR "transcode module path: $transcode_modpath\n";

    # empty list if tcmodinfo not available
    return $FILTER_LIST = $class->new() if not $transcode_modpath;

    my $filter_mtime     = ( stat($filename) )[9];
    my $transcode_mtime  = ( stat($transcode_modpath) )[9];
    my $FilterList_mtime = (
        stat(
            $class->search_perl_inc(
                rel_path => "Video/DVDRip/FilterList.pm"
            )
        )
    )[9];

    # create new list of no file avaiable or if file
    # is older than transcode's modpath, or if dvd::rip's
    # FilterList module is newer.
    if (   not -f $filename
        or $filter_mtime < $transcode_mtime
        or $filter_mtime < $FilterList_mtime ) {
        $FILTER_LIST = $class->new();
        $FILTER_LIST->scan( modpath => $transcode_modpath );
        $FILTER_LIST->save( filename => $filename );
        return $FILTER_LIST;
    }

    return $FILTER_LIST = $class->load( filename => $filename );
}

sub new {
    my $class = shift;

    my $self = { filters => {}, };

    return bless $self, $class;
}

sub load {
    my $class      = shift;
    my %par        = @_;
    my ($filename) = @par{'filename'};

    my $fh = FileHandle->new;
    open( $fh, $filename ) or croak "can't read $filename";
    my $data = join( '', <$fh> );
    close $fh;

    my $filter_list;
    eval($data);
    croak "can't load $filename. Perl error: $@" if $@;

    return bless $filter_list, $class;
}

sub save {
    my $self       = shift;
    my %par        = @_;
    my ($filename) = @par{'filename'};

    my $data_sref = $self->get_save_data;

    my $fh = FileHandle->new;

    open( $fh, "> $filename" ) or confess "can't write $filename";
    print $fh q{# $Id: FilterList.pm 2287 2007-03-17 16:53:44Z joern $},
        "\n";
    print $fh
        "# This file was generated by Video::DVDRip Version $Video::DVDRip::VERSION\n\n";

    print $fh ${$data_sref};
    close $fh;

    1;
}

sub get_save_data {
    my $self = shift;

    my $dd = Data::Dumper->new( [$self], ['filter_list'] );
    $dd->Indent(1);
    $dd->Purity(1);
    my $data = $dd->Dump;

    return \$data;
}

sub scan {
    my $self      = shift;
    my %par       = @_;
    my ($modpath) = @par{'modpath'};

    print STDERR
        "[filterlist] (re)scanning transcode's module path $modpath...\n";

    my @filter_names = grep !/^(pv|preview)$/,
        map {m!/filter_([^/]+)\.so$!} glob("$modpath/filter_*");

    my %filters;
    foreach my $filter_name (@filter_names) {
        my $filter
            = Video::DVDRip::Filter->new( filter_name => $filter_name );
        next if !$filter || !$filter->capabilities;
        $filters{$filter_name} = $filter;
    }

    $self->set_filters( \%filters );

    1;
}

sub get_filter {
    my $self          = shift;
    my %par           = @_;
    my ($filter_name) = @par{'filter_name'};

    $self = $self->get_filter_list if not ref $self;

    croak "Filter '$filter_name' unknown"
        if not exists $self->filters->{$filter_name};

    return $self->filters->{$filter_name};
}

package Video::DVDRip::Filter;
use Locale::TextDomain qw (video.dvdrip);

use Carp;
use Text::Wrap;

sub filter_name			{ shift->{filter_name}			}
sub desc			{ shift->{desc}				}
sub version			{ shift->{version}			}
sub author			{ shift->{author}			}
sub capabilities		{ shift->{capabilities}			}
sub frames_needed		{ shift->{frames_needed}		}
sub options			{ shift->{options}			}
sub options_by_name		{ shift->{options_by_name}		}

sub can_video			{ shift->capabilities =~ /V/ 		}
sub can_audio			{ shift->capabilities =~ /A/ 		}
sub can_rgb			{ shift->capabilities =~ /R/ 		}
sub can_yuv			{ shift->capabilities =~ /Y/ 		}
sub can_multiple		{ shift->capabilities =~ /M/ 		}

sub is_pre			{ shift->capabilities =~ /E/ 		}
sub is_post			{ shift->capabilities =~ /O/ 		}
sub is_pre_post			{ $_[0]->is_pre and $_[0]->is_post	}

sub new {
    my $class         = shift;
    my %par           = @_;
    my ($filter_name) = @par{'filter_name'};

    $DEBUG && print STDERR "Scan: tcmodinfo -i $filter_name ... ";

    my $config;
    eval {
        local $SIG{ALRM} = sub { die "alarm" };
        alarm 2;
        $config = qx[ tcmodinfo -i $filter_name 2>/dev/null ];
        alarm 0;
    };

    if ( $@ ) {
        $DEBUG && print STDERR "TIMEOUT\n";
        return;
    }
    
    $DEBUG && print STDERR "OK\n------\n$config\n------\n";

    my $line;
    my ( %options, @options );

    my ( $desc, $version, $author, $capabilities, $frames_needed );
    my $in_config = 0;

    while ( $config =~ /(.*)/g ) {
        $line = $1;
        if ( not $in_config ) {
            next if $line !~ /^START/;
            $in_config = 1;
        }
        next if $line !~ /^"/;
        if ( not $desc ) {
            my @csv_fields = ( $line =~ /"([^"]+)"/g );
            shift @csv_fields;
            $desc          = shift @csv_fields;
            $version       = shift @csv_fields;
            $author        = shift @csv_fields;
            $capabilities  = shift @csv_fields;
            $frames_needed = shift @csv_fields;
            next;
        }

        my $option = Video::DVDRip::FilterOption->new(
            config      => $line,
            filter_name => $filter_name,
        );
        return if $option->option_name !~ /^\w+$/;
        $options{ $option->option_name } = $option;
        push @options, $option;
    }

    $capabilities =~ s/O/E/ if $filter_name eq 'logoaway';

    my $self = {
        filter_name     => $filter_name,
        desc            => $desc,
        version         => $version,
        author          => $author,
        capabilities    => $capabilities,
        frames_needed   => $frames_needed,
        options         => \@options,
        options_by_name => \%options,
    };

    return bless $self, $class;
}

sub get_option {
    my $self          = shift;
    my %par           = @_;
    my ($option_name) = @par{'option_name'};

    croak "Option '$option_name' unknown for filter '".$self->filter_name."'"
        if not exists $self->options_by_name->{$option_name};

    return $self->options_by_name->{$option_name};
}

sub get_info {
    my $self = shift;

    $Text::Wrap::columns = 32;

    my @info = (
        [ "Name",      wrap( "", "", $self->filter_name ), ],
        [ "Desc",      wrap( "", "", $self->desc ), ],
        [ "Version",   wrap( "", "", $self->version ), ],
        [ "Author(s)", wrap( "", "", $self->author ), ],
    );

    my $info;
    $info .= "Video, " if $self->can_video;
    $info .= "Audio, " if $self->can_audio;
    $info =~ s/, $//;

    push @info, [ "Type", $info ];

    $info = "";
    $info .= "RGB, " if $self->can_rgb;
    $info .= "YUV, " if $self->can_yuv;
    $info =~ s/, $//;

    push @info, [ "Color", $info ];

    $info = "";
    $info .= "PRE, "  if $self->is_pre;
    $info .= "POST, " if $self->is_post;
    $info =~ s/, $//;
    $info ||= "unknown";

    push @info, [ "Pre/Post", $info ];
    push @info, [ "Multiple", ( $self->can_multiple ? "Yes" : "No" ) ];

    return \@info;
}

sub av_type {
    my $self = shift;

    my $info = "";
    $info .= __("Video").", " if $self->can_video;
    $info .= __("Audio").", " if $self->can_audio;
    $info =~ s/, $//;

    return $info;
}

sub colorspace_type {
    my $self = shift;

    return "--" if !$self->can_video;
    
    my $info = "";
    $info .= "RGB, " if $self->can_rgb;
    $info .= "YUV, " if $self->can_yuv;
    $info =~ s/, $//;

    return $info;
}

sub pre_post_type {
    my $self = shift;

    my $info = "";
    $info .= "PRE, "  if $self->is_pre;
    $info .= "POST, " if $self->is_post;
    $info =~ s/, $//;
    $info ||= "unknown";

    return $info;
}

sub multiple_type {
    my $self = shift;
    return $self->can_multiple ? __"Yes" : __"No";
}

sub get_selection_cb {
    my $self = shift;

    return $FILTER_SELECTION_CB{ $self->filter_name };
}

sub get_dummy_instance {
    my $self = shift;
    return Video::DVDRip::FilterSettingsInstance->new (
        id          => -1,
        filter_name => $self->filter_name
    );
}

package Video::DVDRip::FilterOption;
use Locale::TextDomain qw (video.dvdrip);

use Carp;
use Text::Wrap;

sub option_name			{ shift->{option_name}			}
sub desc			{ shift->{desc}				}
sub format			{ shift->{format}			}
sub fields			{ shift->{fields}			}
sub switch			{ shift->{switch}			}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $config, $filter_name ) = @par{ 'config', 'filter_name' };

    my @csv_fields = ( $config =~ /"([^"]*)"/g );

    my $name    = shift @csv_fields;
    my $desc    = shift @csv_fields;
    my $format  = shift @csv_fields;
    my $default = shift @csv_fields;

    my $switch;
    if ( $format eq '' ) {

        # on/off only, no value
        push @csv_fields, "0", "1";
        $format = "%B";
        $switch = 1;
    }
    elsif ( $format eq '%s' ) {
        push @csv_fields, "", "";
    }

    # cpaudio reports '%c' - stupid, %c scans ASCII code
    $format = '%s' if $format eq '%c';

    # logoaway reports '%2x' - stupid, we get spaces this way
    $format =~ s/\%2x/\%02x/g;

    my $scan_format = $format;
    $scan_format =~ s/\%\%//g;    # eliminate quoted %
    my $default_format = $format;
    $default_format =~ s/\%\%//g;    # eliminate quoted %

    my @field_formats = ( $scan_format =~ /\%(.)/g );
    my @default_values
        = Video::DVDRip::CPAN::Scanf::sscanf( $default_format, $default );

    my @fields;
    while (@csv_fields) {
        my $range_from = shift @csv_fields;
        my $range_to   = shift @csv_fields;
        my $type       = shift @field_formats;

        push @fields,
            Video::DVDRip::FilterOptionField->new(
                default    => shift @default_values,
                range_from => $range_from,
                range_to   => $range_to,
                fractional => ( $type eq 'f' ),
                text       => ( $type eq 's' ),
            );
    }

    print "WARNING: [$filter_name] Option $name has fields left!\n"
        if @default_values;

    my $self = {
        option_name => $name,
        desc        => $desc,
        format      => $format,
        fields      => \@fields,
        switch      => $switch,
    };

    return bless $self, $class;
}

sub get_wrapped_desc {
    my $self = shift;

    local($Text::Wrap::columns) = 24;

    return join( "\n", wrap( "", "", $self->desc ) );
}

package Video::DVDRip::FilterOptionField;
use Locale::TextDomain qw (video.dvdrip);

sub default			{ shift->{default}			}
sub range_from			{ shift->{range_from}			}
sub range_to			{ shift->{range_to}			}
sub fractional			{ shift->{fractional}			}
sub switch			{ shift->{switch}			}
sub checkbox			{ shift->{checkbox}			}
sub combo			{ shift->{combo}			}
sub text			{ shift->{text}				}

#-----------------------------------------------------------
# checkbox vs. switch
# ===================
#
# Both are checkboxes on the GUI, but the internal
# parameter code generation differs:
#
# switch: the parameter has no option value. It's there or
# 	  it's not there.
#
# checkbox: the parameter has either 0 or 1 as option value.
#-----------------------------------------------------------

sub new {
    my $class = shift;
    my %par = @_;
    my  ($default, $range_from, $range_to, $fractional, $switch) =
    @par{'default','range_from','range_to','fractional','switch'};
    my  ($text) =
    @par{'text'};

    my ( $checkbox, $combo );

    $range_to = undef
        if $range_to eq 'oo'
        or $range_to < $range_from;

    $range_from = -99999999
        if $range_from eq ''
        or $range_from =~ /\D/;

    $range_to = 99999999
        if $range_to eq ''
        or $range_to =~ /\D/;

    if ( not $fractional and $range_from !~ /\D/ and $range_to !~ /\D/ ) {
        if ( $range_from == 0 and $range_to == 1 ) {
            $checkbox = 1;
        }
        elsif ( $range_to ne ''
            and $range_from ne ''
            and $range_to - $range_from < 20 ) {
            $combo = 1;
        }
    }

    my $self = {
        default    => $default,
        range_from => $range_from,
        range_to   => $range_to,
        fractional => $fractional,
        switch     => $switch,
        checkbox   => $checkbox,
        combo      => $combo,
        text       => $text,
    };

    return bless $self, $class;
}

sub get_range_text {
    my $self = shift;

    return "Default: " . ( $self->default ? "on" : "off" )
        if $self->checkbox
        or $self->switch;
    return "Default: " . $self->default if $self->text;

    my $frac = $self->fractional ? " (fractional)" : "";

    my $range_from = $self->range_from;
    my $range_to   = $self->range_to;

    foreach my $range ( $range_from, $range_to ) {
        $range = "WIDTH"  if $range eq 'W' or $range eq 'width';
        $range = "HEIGHT" if $range eq 'H' or $range eq 'height';
    }

    $range_from = "-oo" if $range_from == -99999999;
    $range_to   = "oo"  if $range_to == 99999999;

    my $default = $self->default;
    $default = "<empty>" if $default eq '';

    my $info = "Valid values$frac: $range_from .. $range_to "
        . "(Default: $default)";

    return $info;
}

1;
