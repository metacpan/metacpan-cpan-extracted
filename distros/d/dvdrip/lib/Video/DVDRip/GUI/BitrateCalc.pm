# $Id: BitrateCalc.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::BitrateCalc;
use Locale::TextDomain qw (video.dvdrip);

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $bitrate_ff;

sub open_window {
	my $self = shift;
	
	return if $bitrate_ff;
	
	$self->build;
	
	1;
}

sub build {
	my $self = shift;
	
	my $context = $self->get_context;
	
	$bitrate_ff = Gtk2::Ex::FormFactory->new (
	    context   => $context,
	    parent_ff => $self->get_form_factory,
            sync      => 1,
            content   => [
		Gtk2::Ex::FormFactory::Window->new (
		    title => __"dvd::rip - Storage and bitrate calculation details",
		    customize_hook => sub {
			my ($gtk_window) = @_;
			$_[0]->parent->set(
		          default_width  => 400,
		          default_height => 400,
			);
			1;
		    },
		    closed_hook => sub {
		        $bitrate_ff->close if $bitrate_ff;
			$bitrate_ff = undef;
			1;
		    },
		    content => [
		        Gtk2::Ex::FormFactory::VBox->new (
			    expand => 1,
			    content => [
			        $self->build_calc_list,
				Gtk2::Ex::FormFactory::DialogButtons->new (
				    clicked_hook_after => sub {
					$bitrate_ff->close;
					$bitrate_ff=undef;
				    },
				),
			    ],
			),
		    ],
                ),
		
            ],
	);
	
	$bitrate_ff->build;
	$bitrate_ff->update;
	$bitrate_ff->show;

	1;
}

sub build_calc_list {
	my $self = shift;

	Gtk2::SimpleList->add_column_type(
		'bitrate_calc_text',
		type	 => "Glib::Scalar",
		renderer => "Gtk2::CellRendererText",
		attr     => sub {
		    my ($treecol, $cell, $model, $iter, $col_num) = @_;
		    my $info = $model->get($iter, $col_num);
		    my $op   = $model->get($iter, 1);
		    $cell->set ( text       => $info );
		    $cell->set ( weight     => $op =~ /[=~]/ ? 700 : 500);
		    1;
		},
	);

	return Gtk2::Ex::FormFactory::VBox->new (
	    expand => 1,
	    content => [
		Gtk2::Ex::FormFactory::List->new (
		    attr           => "bitrate_calc.sheet",
		    expand         => 1,
		    scrollbars     => [ "never", "automatic" ],
		    columns        => [
			__"Description", __"Operator", __"Value", __"Unit"
		    ],
		    types	   => [
	    		("bitrate_calc_text") x 4, "int"
		    ],
		    selection_mode => "none",
		),
	    ],
	);
}

1;
