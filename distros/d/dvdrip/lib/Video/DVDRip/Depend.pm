# $Id: Depend.pm 2377 2009-02-22 18:49:50Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Depend;
use Locale::TextDomain qw (video.dvdrip);

@ISA = qw ( Video::DVDRip::Base );

my $DEBUG = 0;

use Carp;
use strict;

my @DVDRIP_BIN_FILES = qw (
    dvdrip              execflow
    dvdrip-master       dvdrip-multitee
    dvdrip-progress     dvdrip-splitpipe
    dvdrip-subpng
);

my @DVDRIP_MASTER_BIN_FILES = qw (
    execflow              
    dvdrip-master       
);

my $OBJECT;

my $ORDER = 0;
my %TOOLS = (
    "dvd::rip" => {
        order       => ++$ORDER,
        command     => "dvdrip",
        comment     => __ "All internal command files",
        optional    => 0,
        dont_cache  => 1,
        exists      => 1,
        get_version => sub {
            my $missing_file_cnt = 0;
            my @files = $Video::DVDRip::ISMASTER ?
                @DVDRIP_MASTER_BIN_FILES : @DVDRIP_BIN_FILES;
            foreach my $dvdrip_file ( @files ) {
                if ( !__PACKAGE__->get_full_path($dvdrip_file) ) {
                    ++$missing_file_cnt;
                    print STDERR __x( "ERROR: '{file}' not found in PATH\n",
                        file => $dvdrip_file )
                        unless $Video::DVDRip::MAKE_TEST;
                }
            }
            return $missing_file_cnt == @DVDRIP_BIN_FILES ? ""
                : $missing_file_cnt == 0 ? $Video::DVDRip::VERSION
                : "incomplete";
        },
        convert   => 'default',
        __convert => sub {
            my ($version) = @_;
            return $version eq ''           ? 0
                : $version  eq 'incomplete' ? 0
                : $Video::DVDRip::VERSION;
        },
        min           => $Video::DVDRip::VERSION,
        suggested     => $Video::DVDRip::VERSION,
        installed     => undef,                     # set by ->new
        installed_num => undef,                     # set by ->new
        min_num       => undef,                     # set by ->new
        suggested_num => undef,                     # set by ->new
        installed_ok  => undef,                     # set by ->new
    },
    transcode => {
        order       => ++$ORDER,
        command     => "transcode",
        comment     => __ "dvd::rip is nothing without transcode",
        optional    => 0,
        version_cmd => "transcode -v",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /v(\d+\.\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert       => 'default',
        min           => "0.6.14",
        max           => undef,
        suggested     => "1.0.2",
        installed     => undef,       # set by ->new
        installed_num => undef,       # set by ->new
        min_num       => undef,       # set by ->new
        suggested_num => undef,       # set by ->new
        installed_ok  => undef,       # set by ->new
        cluster       => 1,
    },
    ImageMagick => {
        order       => ++$ORDER,
        command     => "convert",
        comment     => __ "Needed for preview image processing",
        optional    => 0,
        version_cmd => "convert -version",
        get_version => sub {
            my ($cmd) = @_;
            my ($output) = qx[$cmd 2>&1];
            #-- GraphicsMagick is compatible with ImageMagick 5.5.2.
            return "5.5.2" if $output =~ /GraphicsMagick\s+(\d+\.\d+(\.\d+)?)/i;
            $output =~ /ImageMagick\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "4.0.0",
        suggested => "6.2.3",
    },
    ffmpeg => {
        order       => ++$ORDER,
        command     => "ffmpeg",
        comment     => __ "FFmpeg video converter command line program",
        optional    => 1,
        version_cmd => "ffmpeg -version",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /version ([^\s]+)/i;
            return $1;
        },
        convert       => 'default',
        min           => "0.4.10",
    },
    xvid4conf => {
        order       => ++$ORDER,
        command     => "xvid4conf",
        comment     => __ "xvid4 configuration tool",
        optional    => 1,
        version_cmd => "xvid4conf -v",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "1.6",
        suggested => "1.12",
    },
    subtitle2pgm => {
        order       => ++$ORDER,
        command     => "subtitle2pgm",
        comment     => __ "Needed for subtitles",
        optional    => 1,
        version_cmd => "subtitle2pgm -h",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /version\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "0.3",
        suggested => "0.3",
    },
    lsdvd => {
        order       => ++$ORDER,
        command     => "lsdvd",
        comment     => __ "Needed for faster DVD TOC reading",
        optional    => 1,
        version_cmd => "lsdvd -V",
        get_version => sub {
            my ($cmd) = @_;
            qx[lsdvd -V 2>&1] =~ /lsdvd\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "0.15",
        suggested => "0.15",
    },
    rar => {
        order       => ++$ORDER,
        command     => Video::DVDRip::Depend->config('rar_command'),
        comment     => __ "Needed for compressed vobsub subtitles",
        optional    => 1,
        version_cmd => "",
        get_version => sub {
            my $cmd = Video::DVDRip::Depend->config('rar_command')." '-?'";
            qx[$cmd 2>&1] =~ /rar\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "2.71",
        max       => "2.99",
        suggested => "2.71",
    },
    mplayer => {
        order       => ++$ORDER,
        command     => "mplayer",
        comment     => __ "Needed for subtitle vobsub viewing",
        optional    => 1,
        version_cmd => "mplayer --help",
        get_version => sub {
            my ($cmd) = @_;
            my $out = qx[$cmd 2>&1];
            if ( $out =~ /CVS|SVN/i ) {
                return "cvs";
            }
            else {
                $out =~ /MPlayer.*?(\d+\.\d+(\.\d+)?)/i;
                return $1;
            }
        },
        convert   => 'default',
        min       => "0.90",
        suggested => "1.00",
    },
    ogmtools => {
        order       => ++$ORDER,
        command     => "ogmmerge",
        comment     => __ "Needed for OGG/Vorbis",
        optional    => 1,
        version_cmd => "ogmmerge -V",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /v(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "1.0.0",
        suggested => "1.5",
        cluster   => 1,
    },
    dvdxchap => {
        order       => ++$ORDER,
        command     => "dvdxchap",
        comment     => __ "For chapter progress bar (ogmtools)",
        optional    => 1,
        version_cmd => "dvdxchap -V",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /v(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "1.0.0",
        suggested => "1.5",
    },
    mjpegtools => {
        order       => ++$ORDER,
        command     => "mplex",
        comment     => __ "Needed for (S)VCD encoding",
        optional    => 1,
        version_cmd => "mplex --help",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /version\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "1.6.0",
        suggested => "1.6.2",
    },
    xine => {
        order       => ++$ORDER,
        command     => "xine",
        comment     => __ "Can be used to view DVD's/files",
        optional    => 1,
        version_cmd => "xine -version",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /v(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "0.9.13",
        suggested => "0.9.15",
    },
    fping => {
        order       => ++$ORDER,
        command     => "fping",
        comment     => __ "Only for cluster mode master",
        optional    => 1,
        version_cmd => "fping -v",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /Version\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "2.2",
        suggested => "2.4",
    },
    hal => {
        order       => ++$ORDER,
        command     => "lshal",
        comment     => __"Used for DVD device scanning",
        optional    => 1,
        version_cmd => "lshal -v",
        get_version => sub {
            my ($cmd) = @_;
            qx[$cmd 2>&1] =~ /version\s+(\d+\.\d+(\.\d+)?)/i;
            return $1;
        },
        convert   => 'default',
        min       => "0.5",
        suggested => "0.5.7",
    },
);

sub convert_default {
    my ($ver) = @_;
    return 990000 if $ver =~ /cvs|svn/i;
    $ver =~ m/(\d+)(\.(\d+))?(\.(\d+))?(\.\d+)?/;
    $ver = $1 * 10000 + $3 * 100 + $5;
    $ver = $ver - 1 + $6 if $6;
    return $ver;
}

sub convert_none {
    return $_[0];
}

sub new {
    my $class = shift;

    return $OBJECT if $OBJECT;

    my $OBJECT = bless {}, $class;

    $OBJECT->load_tool_version_cache;

    my $dependencies_ok = 1;

    my ( $tool, $def );
    while ( ( $tool, $def ) = each %TOOLS ) {
        my $get_version = $def->{get_version};
        my $convert     = $def->{convert};
        if ( $convert eq 'default' ) {
            $convert = \&convert_default;
        }
        elsif ( $convert eq 'none' ) {
            $convert = \&convert_none;
        }

        $DEBUG && print "[depend] $tool => ";

        my $version = $OBJECT->get_cached_version($def)
            || &$get_version($def->{version_cmd});

        if ( $version ne '' ) {
            $DEBUG && print "$version ";
            $def->{installed}     = $version;
            $def->{installed_num} = &$convert($version);
            $DEBUG && print "=> $def->{installed_num}\n";
        }
        else {
            $DEBUG && print "NOT INSTALLED\n";
            $def->{installed} = __ "not installed";
        }

        $def->{max_num} = &$convert( $def->{max} ) if defined $def->{max};
        $def->{min_num} = &$convert( $def->{min} );
        $def->{suggested_num} = &$convert( $def->{suggested} );
        $def->{installed_ok}  = $def->{exists} && ($def->{installed_num} >= $def->{min_num});
        $def->{installed_ok}  = 0
            if defined $def->{max}
            and $def->{installed_num} > $def->{max_num};
        $dependencies_ok = 0
            if not $def->{optional}
            and not $def->{installed_ok};
    }

    $OBJECT->{ok} = $dependencies_ok;

    $OBJECT->update_tool_version_cache;

    return $OBJECT;
}

sub load_tool_version_cache {
    my $self = shift;

    my $dir      = "$ENV{HOME}/.dvdrip";
    my $filename = "$dir/tool_version_cache";

    return unless -f $filename;

    open( IN, $filename ) or die "can't read $filename";
    while (<IN>) {
        chomp;
        if ( /LD_ASSUME_KERNEL=(.*)/
            && $1 ne $ENV{LD_ASSUME_KERNEL} ) {

            #-- discard cache if LD_ASSUME_KERNEL changed
            #-- in the meantime
            unlink $filename;
            last;
        }
        my ( $tool, $path, $mtime, $size, $version ) = split( /\t/, $_ );
        my $def = $self->tools->{$tool};
        $def->{path}           = $path;
        $def->{mtime}          = $mtime;
        $def->{size}           = $size;
        $def->{cached_version} = $version;
    }
    close IN;

    1;
}

sub update_tool_version_cache {
    my $self = shift;

    my $dir      = "$ENV{HOME}/.dvdrip";
    my $filename = "$dir/tool_version_cache";

    mkdir $dir, 0755 or die "can't create $dir" if not -d $dir;

    open( OUT, ">$filename" ) or die "can't write $filename";
    print OUT "LD_ASSUME_KERNEL=$ENV{LD_ASSUME_KERNEL}\n";
    while ( my ( $tool, $def ) = each %{ $self->tools } ) {
        print OUT $tool . "\t"
            . $def->{path} . "\t"
            . $def->{mtime} . "\t"
            . $def->{size} . "\t"
            . $def->{installed} . "\n";
    }
    close OUT;

    1;
}

sub get_cached_version {
    my $self = shift;
    my ($tool_def) = @_;

    return if $tool_def->{dont_cache};

    my $version = $tool_def->{cached_version};

    my $path = $self->get_full_path( $tool_def->{command} );
    if ( $path ne $tool_def->{path} ) {
        $tool_def->{path} = $path;
        $version = undef;
    }

    $tool_def->{exists} = $path ne '';

    my $size = -s $path;
    if ( $size != $tool_def->{size} ) {
        $tool_def->{size} = $size;
        $version = undef;
    }

    my $mtime = ( stat $path )[9];
    if ( $mtime != $tool_def->{mtime} ) {
        $tool_def->{mtime} = $mtime;
        $version = undef;
    }

    #-- Don't cache the version number if the tool
    #-- is found on the harddrive but cached as
    #-- missing, otherwise dvd::rip doesn't check
    #-- tools that crashed due to NPTL issues in
    #-- the last run but the NPTL settings may have
    #-- changed in the meantime.
    $version = undef if -x $path && $version eq 'missing';

    return $version;
}

sub get_full_path {
    my $self = shift, my ($file) = @_;

    return $file if $file =~ m!^/!;

    if ( not -x $file ) {
        foreach my $p ( split( /:/, $ENV{PATH} ) ) {
            $file = "$p/$file", last if -x "$p/$file";
        }
    }

    return $file if -x $file;
    return;
}

sub ok    { shift->{ok} }
sub tools { \%TOOLS }

sub has {
    my $self = shift;
    my ($command) = @_;
    return 0 if not exists $TOOLS{$command};
    return $TOOLS{$command}->{installed_ok};
}

sub exists {
    my $self = shift;
    my ($command) = @_;
    return 0 if not exists $TOOLS{$command};
    return $TOOLS{$command}->{exists};
}

sub version {
    my $self = shift;
    my ($command) = @_;
    return if not exists $TOOLS{$command};
    return $TOOLS{$command}->{installed_num};
}

sub gen_depend_table {
    my $tools = \%TOOLS;

    print <<__EOF;
<table border="1" cellpadding="4" cellspacing="1">
<tr class="tablehead">
  <td><b>Tool</b></td>
  <td><b>Comment</b></td>
  <td><b>Mandatory</b></td>
  <td><b>Suggested</b></td>
  <td><b>Minimum</b></td>
  <td><b>Maximum</b></td>
</tr>
__EOF

    foreach my $tool (
        sort { $tools->{$a}->{order} <=> $tools->{$b}->{order} }
        keys %{$tools}
        ) {
	next if $tool eq 'dvd::rip';
	my $def = $tools->{$tool};
        $def->{max} ||= "-";
        $def->{mandatory} = !$def->{optional} ? "Yes" : "No";
        print <<__EOF;
<tr>
  <td valign="top">$tool</td>
  <td valign="top">$def->{comment}</td>
  <td valign="top">$def->{mandatory}</td>
  <td valign="top">$def->{suggested}</td>
  <td valign="top">$def->{min}</td>
  <td valign="top">$def->{max}</td>
</tr>
__EOF
    }

    print "</table>\n";
}

sub installed_tools_as_text {
    my $self = shift;

    my $tools = \%TOOLS;

    my $format = "  %-20s %-10s\n";
    my $text   = "\n" . sprintf( $format, __ "Program", __ "Version" );

    $text .= "  " . ( "-" x 31 ) . "\n";

    foreach my $tool (
        sort { $tools->{$a}->{order} <=> $tools->{$b}->{order} }
        keys %{$tools}
        ) {
        my $def = $tools->{$tool};
        $text .= sprintf( $format, $tool, $def->{installed} );
    }

    $text .= "  " . ( "-" x 31 ) . "\n";

    return $text;
}

1;
