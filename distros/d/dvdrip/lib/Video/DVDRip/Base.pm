# $Id: Base.pm 2280 2007-03-17 10:56:47Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Base;
use Locale::TextDomain qw (video.dvdrip);

use Video::DVDRip::Config;
use Video::DVDRip::FilterList;

use Carp;
use strict;
use FileHandle;
use IO::Pipe;
use Fcntl;
use Data::Dumper;

# load preferences ---------------------------------------------------
my $CONFIG_OBJECT = Video::DVDRip::Config->new;
$Video::DVDRip::PREFERENCE_FILE ||= "$ENV{HOME}/.dvdriprc";
$CONFIG_OBJECT->set_filename($Video::DVDRip::PREFERENCE_FILE);
$CONFIG_OBJECT->save if not -f $Video::DVDRip::PREFERENCE_FILE;
$CONFIG_OBJECT->load;

# detect installed tool versions -------------------------------------
require Video::DVDRip::Depend;
my $DEPEND_OBJECT = Video::DVDRip::Depend->new;

# pre load transcode's filter list -----------------------------------
Video::DVDRip::FilterList->get_filter_list
    if $DEPEND_OBJECT->version("transcode") >= 603;

# init some config settings ------------------------------------------
# (this depends on a loaded Config and Depend, that's why we call it here)
$CONFIG_OBJECT->init_settings;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub config {
    my $thingy = shift;
    my ($name) = @_;
    return $CONFIG_OBJECT->get_value($name);
}

sub set_config {
    my $thingy = shift;
    my ( $name, $value ) = @_;
    $CONFIG_OBJECT->set_value( $name, $value );
    return $value;
}

sub config_object {
    $CONFIG_OBJECT;
}

sub depend_object {
    $DEPEND_OBJECT;
}

sub has {
    my $self = shift;
    my ($command) = @_;

    return $self->depend_object->has($command);
}

sub exists {
    my $self = shift;
    my ($command) = @_;

    return $self->depend_object->exists($command);
}

sub version {
    my $self = shift;
    my ($command) = @_;

    return $self->depend_object->version($command);
}

sub debug_level { $Video::DVDRip::DEBUG || shift->{debug_level} }

sub set_debug_level {
    my $thing = shift;
    my $debug;
    if ( ref $thing ) {
        $thing->{debug_level} = shift if @_;
        $debug = $thing->{debug_level};
    }
    else {
        $Video::DVDRip::DEBUG = shift if @_;
        $debug = $Video::DVDRip::DEBUG;
    }

    if ($debug) {
        $Video::DVDRip::DEBUG::TIME = scalar( localtime(time) );
        print STDERR "--- START ------------------------------------\n",
            "$$: $Video::DVDRip::DEBUG::TIME - DEBUG LEVEL $debug\n";
    }

    return $debug;
}

sub dump {
    my $self = shift;
    push @_, $self if not @_;

    my $dd = Data::Dumper->new( \@_ );
    $dd->Indent(1);
    print $dd->Dump;

    1;
}

sub print_debug {
    my $self = shift;

    my $debug = $Video::DVDRip::DEBUG;
    $debug = $self->{debug_level} if ref $self and $self->{debug_level};

    if ($debug) {
        print STDERR join( "\n", @_ ), "\n";
    }

    1;
}

sub system {
    my $self = shift;
    my %par  = @_;
    my ( $command, $err_ignore, $return_rc )
        = @par{ 'command', 'err_ignore', 'return_rc' };

    $self->log("Executing command: $command");

    $self->print_debug("executing command: $command");

    my $catch = `($command) 2>&1`;
    my $rc    = $?;

    $self->print_debug("got: rc=$rc catch=$catch");

    croak "Error executing command $command:\n$catch" if $rc;

    return $return_rc ? $? : $catch;
}

sub popen {
    my $self = shift;
    my %par  = @_;
    my ( $command, $callback ) = @par{ 'command', 'callback' };

    return $self->popen_with_callback(@_) if $callback;

    $self->print_debug("executing command: $command");
    $self->log("Executing command: $command");

    my $fh = FileHandle->new;
    open( $fh, "($command) 2>&1 |" )
        or croak "can't fork $command";

    my $flags = '';
    fcntl( $fh, F_GETFL, $flags )
        or die "Can't get flags: $!\n";
    $flags |= O_NONBLOCK;
    fcntl( $fh, F_SETFL, $flags )
        or die "Can't set flags: $!\n";

    return $fh;
}

sub popen_with_callback {
    my $self = shift;
    my %par  = @_;
    my ( $command, $callback, $catch_output )
        = @par{ 'command', 'callback', 'catch_output' };

    $self->print_debug("executing command: $command");
    $self->log("Executing command: $command");

    my $fh = FileHandle->new;
    open( $fh, "($command) 2>&1 |" )
        or croak "can't fork $command";
    select $fh;
    $| = 1;
    select STDOUT;
    return $fh if not $callback;

    my ( $output, $buffer );
    while ( read( $fh, $buffer, 512 ) ) {
        &$callback($buffer);
        $output .= $_ if $catch_output;
    }

    close $fh;

    return $output;
}

sub format_time {
    my $self   = shift;
    my %par    = @_;
    my ($time) = @par{'time'};

    my ( $h, $m, $s );
    $h = int( $time / 3600 );
    $m = int( ( $time - $h * 3600 ) / 60 );
    $s = $time % 60;

    return sprintf( "%02d:%02d:%02d", $h, $m, $s );
}

sub stripped_exception {
    my $text = $@;
    $text =~ s/\s+at\s+[^\s]+\s+line\s+\d+\.?//;
    $text =~ s/^msg:\s*//;
    return $text;
}

my $logger;

sub logger {$logger}

sub set_logger {
    my $self = shift;
    my ($set_logger) = @_;
    return $logger = $set_logger;
}

sub log {
    shift;
    return if not defined $logger;
    $logger->log(@_);
    1;
}

sub clone {
    my $self = shift;

    require Storable;
    return Storable::dclone($self);
}

sub combine_command_options {
    my $self = shift;
    my %par  = @_;
    my ( $cmd, $cmd_line, $options ) = @par{ 'cmd', 'cmd_line', 'options' };

    # split command line into separate commands
    $cmd_line =~ s/\s+$//;
    $cmd_line .= ";" if $cmd_line !~ /;$/;
    my @parts = grep !/^$/,
        ( $cmd_line
            =~ m!(.*?)\s*(\(|\)|;|&&|\|\||\`which nice\`\s+-n\s+[\d-]+|execflow\s+(?:-n\s*\d+)?)\s*!g
        );
    # walk through and process requested command
    foreach my $part (@parts) {
        next if $part !~ s/^$cmd\s+//;
        my $options_href
            = $self->get_shell_options( options => $part . " " . $options );
        $part = "$cmd " . join( " ", values %{$options_href} );
    }

    # remove trailing semicolon
    pop @parts;

    # join parts and return
    $cmd = join( " ", @parts );

    return $cmd;
}

sub get_shell_options {
    my $self      = shift;
    my %par       = @_;
    my ($options) = @par{'options'};

    my %options;
    my @words = map { /\s/ ? "'$_'" : $_ } $self->get_shell_words($options);

    my $opt;
    for ( my $i = 0; $i < @words; ++$i ) {
        $words[$i] = "'$words[$i]'" if $words[$i] =~ /\s/;
        if ( $words[$i] =~ /^(-+\D.*)/ ) {

            # why \D? Answer: minus followed by a number is
            # surley a value, no option.
            $opt = $1;
            if ( $i + 1 != @words and $words[ $i + 1 ] !~ /^-/ ) {
                $options{$opt} = "$opt $words[$i+1]";
                ++$i;
            }
            else {
                $options{$opt} = "$opt";
            }
        }
        else {
            $options{$opt} .= " " . $words[$i];
        }
    }

    return \%options;
}

# This subroutine is taken from "shellwords.pl" (standard Perl
# library) and slightly modified (mainly usage of lexical
# variables instead of globals).

sub get_shell_words {
    my $thing = shift;

    local ($_) = join( '', @_ ) if @_;

    my ( @words, $snippet, $field );

    s/^\s+//;
    while ( $_ ne '' ) {
        $field = '';
        for ( ;; ) {
            if (s/^"(([^"\\]|\\.)*)"//) {
                ( $snippet = $1 ) =~ s#\\(.)#$1#g;
            }
            elsif (/^"/) {
                die "Unmatched double quote: $_\n";
            }
            elsif (s/^'(([^'\\]|\\.)*)'//) {
                ( $snippet = $1 ) =~ s#\\(.)#$1#g;
            }
            elsif (/^'/) {
                die "Unmatched single quote: $_\n";
            }
            elsif (s/^\\(.)//) {
                $snippet = $1;
            }
            elsif (s/^([^\s\\'"]+)//) {
                $snippet = $1;
            }
            else {
                s/^\s+//;
                last;
            }
            $field .= $snippet;
        }
        push( @words, $field );
    }

    return @words;
}

sub apply_command_template {
    my $self = shift;
    my %par  = @_;
    my ( $template, $opts ) = @par{ 'template', 'opts' };

    $template =~ s/<(.*?)>/__DVDRIP_REPEATED_GROUP__/;
    my ($group_tmpl) = "$1 ";

    my $opts_href = shift @{$opts};

    $template = $self->apply_template(
        template  => $template,
        opts_href => $opts_href,
    );

    my $group = "";

    foreach my $group_opts_href ( @{$opts} ) {
        $opts_href->{$_} = $group_opts_href->{$_}
            for keys %{$group_opts_href};
        $group .= $self->apply_template(
            template  => $group_tmpl,
            opts_href => $opts_href,
        );
    }

    $template =~ s/__DVDRIP_REPEATED_GROUP__/$group/;

    return $template;
}

sub apply_template {
    my $self = shift;
    my %par  = @_;
    my ( $template, $opts_href ) = @par{ 'template', 'opts_href' };

    $template =~ s{\%(\(.*?\)|.)}{
			my $var = $1;
			if ( $var =~ s/^\((.*)\)$/$1/ ) {
				$var =~ s/\%(.)/$opts_href->{$1}/g;
				my $eval = $var;
				$var = eval $eval;
				if ( $@ ) {
					my $err = $@;
					$err =~ s/at\s+\(.*//;
					warn "Perl expression ( $eval ) => $err";
				}
			} else {
				$var = $opts_href->{$var};
			}
			$var;
		}eg;

    return $template;
}

sub search_perl_inc {
    my $self       = shift;
    my %par        = @_;
    my ($rel_path) = @par{'rel_path'};

    my $file;

    foreach my $INC (@INC) {
        $file = "$INC/$rel_path";
        last if -e $file;
        $file = "";
    }

    return $file;
}

1;
