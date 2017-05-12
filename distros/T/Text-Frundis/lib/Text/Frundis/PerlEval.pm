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
# Eval of perl code to compile new user defined macros
#
package Text::Frundis::PerlEval;

use utf8;
use v5.12;
use strict;
use warnings;
use open qw(:std :utf8);

use Text::Frundis::Object qw(@Arg);
use Text::Frundis::Processing;

our @Arg;

sub _compile_perl_code {    # [[[
    my $self = shift;
    my ($macro, $text, $type) = @_;
    my $key = $type eq "macro" ? "macros" : "filters";
    local $@;
    {
        local $SIG{'__WARN__'} = sub {
            Text::Frundis::Processing::diag_error("perl_eval:$type:$_[0]");
        };
        $self->{$key}{$macro}{code} = eval qq(sub { $text });
    }
    if ($@) {
        Text::Frundis::Processing::diag_fatal("perl_eval:$type:$@");
    }
}    # ]]]

1;

# vim:foldmarker=[[[,]]]:foldmethod=marker:sw=4:sts=4:expandtab
