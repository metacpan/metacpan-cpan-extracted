#!perl

# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2018-2026 Sven Kirmess
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

use 5.006;
use strict;
use warnings;

use Test::MockModule 0.14;
use Test::More 0.88;

use Test::Pod::Links;

use constant CLASS => 'Test::Pod::Links';

{

    chdir 'corpus/dist2' or die "chdir failed: $!";

    my $done_testing = 0;
    my $skip_all     = 0;
    my @skip_all_args;
    my $module = Test::MockModule->new('Test::Builder');
    $module->redefine( 'done_testing', sub { $done_testing++; return; } );
    $module->redefine( 'skip_all', sub { @skip_all_args = @_; $skip_all++; return; } );

    my @pod_file_ok_args;
    my $tpl = Test::MockModule->new( CLASS() );
    $tpl->redefine( 'pod_file_ok', sub { my $self = shift; push @pod_file_ok_args, [@_]; return; } );

    my $obj = CLASS()->new;
    is( $obj->all_pod_files_ok(), undef, 'all_pod_files_ok returned undef' );
    is( $done_testing,            1,     '... done_testing was called once' );
    is( $skip_all,                0,     '... skip_all was never called' );
    is( scalar @pod_file_ok_args, 1,     'pod_file_ok was called once' );

    is_deeply( [@pod_file_ok_args], [ ['lib/Local/Pod.pod'] ], '... with the correct filenames' );

}

#
done_testing();

exit 0;
