#!/usr/bin/env perl
# Copyright (c) 2014, 2015 Yon <anaseto@bardinflor.perso.aquilenet.fr>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
# Object interface for use in user macros and filters
#
package Text::Frundis::Object;

use utf8;
use v5.12;
use strict;
use warnings;
use open qw(:std :utf8);

use Exporter 'import';
use Text::Frundis::Processing;

our @Arg;    # Macro line arguments (so common that a global variable is handy)
our @EXPORT_OK = qw(@Arg);

sub new {    # [[[
    my $class = shift;
    my $self  = shift;
    bless $self, $class;
}    # ]]]

# methods, in alphabetic order

sub args {    # [[[
    shift;
    return \@Arg;
}    # ]]]

sub call {    # [[[
    shift;
    Text::Frundis::Processing::call(@_);
}    # ]]]

sub _call_perl_macro {    # [[[
    my $self  = shift;
    my $macro = shift;
    $self->{macros}{$macro}{code}->($self);
}    # ]]]

sub diag_warning {    # [[[
    shift;
    Text::Frundis::Processing::diag_error(@_);
}    # ]]]

sub diag_error {    # [[[
    shift;
    Text::Frundis::Processing::diag_error(@_);
}    # ]]]

sub diag_fatal {    # [[[
    shift;
    Text::Frundis::Processing::diag_fatal(@_);
}    # ]]]

sub escape {    # [[[
    shift;
    Text::Frundis::Processing::escape(@_);
}    # ]]]

sub escape_text {    # [[[
    shift;
    Text::Frundis::Processing::escape_text(@_);
}    # ]]]

sub file {    # [[[
    my $self = shift;
    return ${ $self->{file} };
}    # ]]]

sub flag {    # [[[
    my $self = shift;
    my @arg  = @_;
    if (@arg == 1) {
        return $self->{flags}{ $arg[0] };
    }
    elsif (@arg == 2) {
        return unless $self->process;
        unless ($self->{allowed_flags}{ $_[0] }
            and $self->{allowed_flags}{ $_[0] } !~ /^_/)
        {
            $self->{allowed_flags}{ $_[0] } = 1;
        }
        $self->{flags}{ $_[0] } = $_[1];
    }
    else {
        $self->diag_error("perl:method flag has one or two arguments");
    }
}    # ]]]

sub format {    # [[[
    my $self = shift;
    return $self->{format};
}    # ]]]

sub get_close_delim {    # [[[
    shift;
    Text::Frundis::Processing::get_close_delim();
}    # ]]]

sub ivars {    # [[[
    my $self = shift;
    return $self->{ivars};
}    # ]]]

sub lnum {    # [[[
    my $self = shift;
    return $self->{state}{lnum};
}    # ]]]

sub loX_entry_infos {    # [[[
    my $self = shift;
    return if $self->process;
    Text::Frundis::Processing::loX_entry_infos(@_);
}    # ]]]

sub macro {    # [[[
    my $self = shift;
    return $self->{state}{macro};
}    # ]]]

sub new_id {    # [[[
    my $self = shift;
    my $id   = shift;
    $id = Text::Frundis::Processing::escape_text($id);
    $self->{ID}{$id} = Text::Frundis::Processing::xhtml_gen_href("", $id);
}    # ]]]

sub param {    # [[[
    my $self = shift;
    if (@_ == 1) {
        return $self->{params}{ $_[0] };
    }
    elsif (@_ == 2) {
        return unless $self->process;
        unless ($self->{allowed_params}{ $_[0] }
            and $self->{allowed_params}{ $_[0] } !~ /^_/)
        {
            $self->{allowed_params}{ $_[0] } = 1;
        }
        $self->{params}{ $_[0] } = $_[1];
    }
    else {
        diag_error("perl:method param has one or two arguments");
    }
}    # ]]]

sub parse_options {    # [[[
    shift;
    Text::Frundis::Processing::parse_options(@_);
}    # ]]]

sub phrasing_macro_begin {    # [[[
    shift;
    Text::Frundis::Processing::phrasing_macro_begin(@_);
}    # ]]]

sub phrasing_macro_end {    # [[[
    shift;
    Text::Frundis::Processing::phrasing_macro_end(@_);
}    # ]]]

sub process {    # [[[
    my $self = shift;
    return ${ $self->{process} };
}    # ]]]

sub text {    # [[[
    my $self = shift;
    my @arg  = @_;
    if (@arg == 0) {
        return $self->{state}{text};
    }
    elsif (@arg == 1) {
        $self->{state}{text} = $arg[0];
    }
    else {
        diag_error("perl:method text has one or two arguments");
    }
}    # ]]]

sub vars {    # [[[
    return shift->{vars};
}    # ]]]

sub xhtml_gen_href {    # [[[
    shift;
    Text::Frundis::Processing::xhtml_gen_href(@_);
}    # ]]]

sub xhtml_loX {    # [[[
    my $self = shift;
    return unless $self->process;
    Text::Frundis::Processing::xhtml_loX(@_);
}    # ]]]

1;

# vim:foldmarker=[[[,]]]:foldmethod=marker:sw=4:sts=4:expandtab
