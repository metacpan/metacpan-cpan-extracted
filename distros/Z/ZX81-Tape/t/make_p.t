use Modern::Perl;
use Path::Tiny;
use Test::HexDifferences; 
use Test::More;
use Text::Diff;

BEGIN { use_ok 'ZX81::Tape', 'make_p', 'dump_p' }

for my $bas_file (path("t/input")->children(qr/\.bas$/)) {
    my $exp_p_file = path("t/expected")->child($bas_file->basename(".bas") . ".p");
    my $exp_txt_file = path("t/expected")->child($bas_file->basename(".bas") . ".txt");
    my $p_file = $bas_file->basename(".bas").".p";
    my $txt_file = $bas_file->basename(".bas").".txt";
	
	# make .p file
    make_p($bas_file, $p_file);

	# compare with .p file made by zxtext2p
	if (-f $exp_p_file) {
		my $p_bytes = path($p_file)->slurp_raw; 
		my $exp_p_bytes = path($exp_p_file)->slurp_raw;

		eq_or_dump_diff($p_bytes,$exp_p_bytes,{ address => 0x4009 }, "diff $p_file $exp_p_file");
		if ($p_bytes ne $exp_p_bytes) {
			if ($ENV{DEVELOPPER}) {
				dump_p($p_file, "$p_file.txt");
				dump_p($exp_p_file, "$exp_p_file.txt");
				system "start \"\" WinMergeU.exe $p_file.txt $exp_p_file.txt";
			}
		}
	}

	# make dump file
    dump_p($p_file, $txt_file);

	my $diff = diff(
		"$txt_file",
		"$exp_txt_file",
		{ STYLE => 'Table' }
	);
    ok $diff eq '', "diff $txt_file $exp_txt_file";
	if ($diff ne '') {
		warn $diff;
		if ($ENV{DEVELOPPER}) {
            system "start \"\" WinMergeU.exe $txt_file $exp_txt_file";
		}
	}

	if (Test::More->builder->is_passing) {
		unlink $p_file;
		unlink $txt_file;
		unlink "$p_file.txt";
		unlink "$exp_p_file.txt";
	}
}

done_testing;
