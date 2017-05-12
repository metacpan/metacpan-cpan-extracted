# $Id: Logger.pm 2326 2007-08-05 16:58:33Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Logger;
use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub gtk_text_view		{ shift->{gtk_text_view}		}
sub project			{ shift->{project}			}
sub fh				{ shift->{fh}				}

sub set_gtk_text_view		{ shift->{gtk_text_view}	= $_[1]	}
sub set_project			{ shift->{project}		= $_[1]	}
sub set_fh			{ shift->{fh}			= $_[1]	}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $gtk_text_view, $project, $fh )
        = @par{ 'gtk_text_view', 'project', 'fh' };

    my $self = bless {
        gtk_text_view => $gtk_text_view,
        fh            => $fh,
        project       => $project,
    }, $class;

    return bless $self, $class;
}

sub insert_project_logfile {
    my $self = shift;

    my $project       = $self->project       or return;
    my $gtk_text_view = $self->gtk_text_view or return;

    $gtk_text_view->get("buffer")->set_text("") if $self->gtk_text_view;

    if ( -r $project->logfile ) {
        open( IN, $project->logfile );
        my $buffer = $gtk_text_view->get("buffer");
        my $iter   = $buffer->get_end_iter;
        my @lines;
        my $cnt;
        while (<IN>) {
            ++$cnt;
            push @lines, $_;
            shift @lines if @lines > 20;
        }
        close IN;
        $cnt -= 20;
        unshift @lines, "[truncated $cnt lines]\n" if $cnt > 0;
        for (@lines) {
            my ( $date, $line ) = split( /\t/, $_, 2 );
            if ( $line eq '' ) {
                $line = $date;
                $date = "";
            }
            else {
                $line = " " . $line;
            }
            $buffer->insert_with_tags_by_name( $iter, $date, "date" );
            $buffer->insert( $iter, $line );
        }

        #-- timing problems without the Idle handler...
        Glib::Idle->add(
            sub {
                $iter = $buffer->get_end_iter;
                $gtk_text_view->scroll_to_iter( $iter, 0.0, 0, 0.0, 0.0 );
                0;
            }
        );
    }

    1;
}

sub log {
    my $self = shift;

    my $date = localtime(time);
    my $line = $_[0];
    $line =~ s/\s*$/\n/;

    my $gtk_text_view = $self->gtk_text_view;
    my $fh            = $self->fh;
    my $project       = $self->project;

    if ($gtk_text_view) {
        my $buffer = $gtk_text_view->get("buffer");
        my $iter   = $buffer->get_end_iter;
        $buffer->insert_with_tags_by_name( $iter, $date, "date" );
        $buffer->insert( $iter, " " . $line );

        #-- timing problems without the Idle handler...
        Glib::Idle->add(
            sub {
                $iter = $buffer->get_end_iter;
                $gtk_text_view->scroll_to_iter( $iter, 0.0, 0, 0.0, 0.0 );
                0;
            }
        );
    }

    if ($fh) {
        print $fh "$date:   $line";
    }

    if ($project) {
        open( OUT, ">>" . $project->logfile );
        binmode OUT, ":utf8";
        print OUT "$date\t$line";
        close OUT;
    }

    1;
}

sub nuke {
    my $self = shift;

    my $gtk_text_view = $self->gtk_text_view;
    my $project       = $self->project;

    $gtk_text_view->get("buffer")->set_text("") if $gtk_text_view;
    unlink $project->logfile                    if $project;

    $self->log( __ "Logfile nuked." );

    1;
}

1;
