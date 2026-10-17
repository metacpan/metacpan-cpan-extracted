use Modern::Perl;
use Path::Tiny;
use Test::HexDifferences; 
use Test::More;
use Text::Diff;

BEGIN { use_ok 'ZX81::Tape', 'make_p', 'dump_p', 'list_p' }

for my $input_bas_file (path("t/input")->children(qr/\.bas$/)) {
	my $input_basename = $input_bas_file->basename(".bas");
    my $exp_p_file = path("t/expected")->child("$input_basename.p");
	my $exp_dump_file = path("t/expected")->child("$input_basename.txt");
	my $exp_list_file = path("t/expected")->child("$input_basename.bas");
	
	# make .p file from .bas and compare to expected
	make_p($input_bas_file, "$input_basename.p");
	compare_p("$input_basename.p", $exp_p_file);
	
	if (Test::More->builder->is_passing) {
		unlink "$input_basename.p";
	}
	
	# make dump file from .p and compare to expected
	dump_p($exp_p_file, "$input_basename.txt");
	compare_text("$input_basename.txt", $exp_dump_file);
	
	if (Test::More->builder->is_passing) {
		unlink "$input_basename.txt";
	}
	
	# make list file from .p and compare to expected
	list_p($exp_p_file, "$input_basename.bas");
	compare_text("$input_basename.bas", $exp_list_file);
	
	if (Test::More->builder->is_passing) {
		unlink "$input_basename.bas";
	}
	
	# round-trip
	list_p($exp_p_file, "$input_basename.2.bas");
	make_p("$input_basename.2.bas", "$input_basename.2.p");
	compare_p("$input_basename.2.p", $exp_p_file);
	
	if (Test::More->builder->is_passing) {
		unlink "$input_basename.2.bas", "$input_basename.2.p";
	}
}

done_testing;

sub compare_p {
	my($got_p, $exp_p) = @_;
	
	my $got_bytes = path($got_p)->slurp_raw; 
	my $exp_bytes = path($exp_p)->slurp_raw;

	eq_or_dump_diff($got_bytes, $exp_bytes, { address => 0x4009 }, 
					"diff $got_p $exp_p");
	if ($got_bytes ne $exp_bytes) {
		if ($ENV{DEVELOPPER}) {
			dump_p($got_p, "$got_p.txt");
			dump_p($exp_p, "$exp_p.txt");
			system "start \"\" WinMergeU.exe $got_p.txt $exp_p.txt";
		}
	}

	if (Test::More->builder->is_passing) {
		unlink "$got_p.txt", "$exp_p.txt";
	}
}

sub compare_text {
	my($got_txt, $exp_txt) = @_;
	
	my $diff = diff("$got_txt", "$exp_txt");
	ok $diff eq '', "diff $got_txt $exp_txt";
	if ($diff ne '') {
		warn $diff;
		if ($ENV{DEVELOPPER}) {
            system "start \"\" WinMergeU.exe $got_txt $exp_txt";
		}
	}
}
