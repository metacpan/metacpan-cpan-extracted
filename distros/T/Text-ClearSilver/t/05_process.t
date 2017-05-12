#!perl -w

use strict;
use Test::More;
use SelectSaver;

use Text::ClearSilver;

for(1 .. 10){
    note $_;

    my $tcs = Text::ClearSilver->new();

    isa_ok $tcs, 'Text::ClearSilver';
    my $out;
    $tcs->process(\'<?cs var:foo ?>', { foo => 'bar' }, \$out);
    is $out, 'bar', 'process to scalar ref';

    $out = '';

    {
        open my $ofp, '>', \$out;
        my $ss = SelectSaver->new($ofp);
        $tcs->process(\'<?cs var:foo ?>', { foo => 'baz' });

        print "-"; # should not be closed
    }

    is $out, 'baz-', 'process with defout';


    $tcs = Text::ClearSilver->new(
        VarEscapeMode => 'html',
        TagStart      => 'tcs',
        dataset       => { common_var => 'ok' },
    );

    like $tcs->dataset->dump, qr/\b Config \b/xms, 'dataset includes Config';
    like $tcs->dataset->dump, qr/\b VarEscapeMode \b/xms, 'dataset includes VarEscapeMode';
    like $tcs->dataset->dump, qr/\b TagStart \b/xms, 'dataset includes TagStart';

    $tcs->process(\'<?tcs var:foo ?>', { foo => '<bar>' }, \$out);
    is $out, '&lt;bar&gt;', 'with Config';

    $tcs->process(\'<?tcs var:foo ?>', { foo => '<bar>' }, \$out, VarEscapeMode => 'none');
    is $out, '<bar>', 'config in place';

    $tcs->process(\'<?tcs var:html_escape(foo) ?>', { foo => '<bar>' }, \$out, VarEscapeMode => 'none');
    is $out, '&lt;bar&gt;', 'config in place';

    $tcs->process(\'<?tcs var:common_var ?>', {}, \$out);
    is $out, 'ok', 'dataset from instance';

    my $hdf = Text::ClearSilver::HDF->new();
    $hdf->read_file('t/data/basic.hdf');
    $tcs->process('basic.tcs', $hdf, \$out, { load_path => ['t/data'], TagStart => 'cs' });

    my $gold = do{
        local $/;
        open my $in, '<', 't/data/basic.gold' or die $!;
        scalar <$in>;
    };

    is $out, $gold, 'load_path';

    $tcs->process('basic.tcs', $hdf, '05_process.out', { load_path => ['t/data'], TagStart => 'cs' });
    $out = do{
        local $/;
        open my $in, '<', '05_process.out' or die $!;
        scalar <$in>;
    };
    unlink '05_process.out';

    is $out, $gold, 'output to a file';

    eval {
        Text::ClearSilver->new()->process("no such file.tcs", {});
    };
    like $@, qr/\b NotFoundError \b/xms;

    if($_ == 5) {
        my $old_cache = $tcs->clear_cache;

        ok ref($old_cache), 'HASH';
        is join(' ', keys %{$old_cache}), 't/data/basic.tcs', 'clear_cache';
    }
    elsif(($_ % 4) == 0) {
        my $t = time() - $_;
        utime $t, $t, 't/data/basic.tcs';
    }
}

done_testing;
