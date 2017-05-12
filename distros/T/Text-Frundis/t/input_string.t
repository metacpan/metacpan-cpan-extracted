#!/usr/bin/env perl
# Copyright (c) 2015 Yon <anaseto@bardinflor.perso.aquilenet.fr>
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

use utf8;
use v5.12;
use strict;
use warnings;
use warnings qw(FATAL utf8);
use open qw(:std :utf8);
use Test::More tests => 1;
use Test::Differences;
use lib 'lib';
use Text::Frundis;

my $buffer;

open my $fh, '>', \$buffer or die $!;

select $fh;

my $frundis = Text::Frundis->new;

$frundis->add_macro(
    PP => sub {
        my $self = shift;
        $self->call('P');
    },
);

$frundis->add_filter(
    tr => sub {
        my $self = shift;
        my $text = $self->text;
        chomp $text;
        $text =~ tr/a/A/;
        print $text;
    },
);

$frundis->process_source(
    input_string => <<EOS,
.X ftag -t tr2 -code "my\$self=shift;my\$text=\$self->text;\\
    chomp \$text;\$text =~ tr/n/N/;print\$text;"
Some Text.
.PP
Another paragraph.
.Bf -t tr
banana
.Ef
.Bf -t tr2
banana
.Ef
EOS
    target_format => 'latex',
    use_carp => 1,
);

eq_or_diff($buffer, <<EOS, "input_string");
Some Text.

Another paragraph.
bAnAnAbaNaNa

EOS
