use strict;
use FindBin;
use Tk;
use Test::More tests => 14;

my $file = "$FindBin::Bin/file.txt";

BEGIN { use_ok('Tk::DiffText') };

my $mw = MainWindow->new();
my $w  = $mw->DiffText();

my $ta = $w->Subwidget('text_a');
my $tb = $w->Subwidget('text_b');


load: {
	my $got;
	my $exp = "foo\nbar\nbaz\n";
	my @idx = ('1.0', 'end - 1 chars');
	my $fh;

	$w->load(a => ["foo\n", "bar\n", "baz\n"]);

	is($ta->get(@idx), $exp, 'load(a => [list])');

	$w->load(a => "foo\nbar\nbaz\n");
	is($ta->get(@idx), $exp, 'load(a => string)');

	SKIP: {
		if (open(FH, '>', $file)) {
			print FH $exp;
			close(FH);
		}
		else {
			skip("Can't create cross-platform test file [$!]", 10);
		}

		$w->load(a => $file);
		is($ta->get(@idx), $exp, 'load(a => file)');
	
		open(FH, "< $file");
		$w->load(a => *FH);
		is($ta->get(@idx), $exp, 'load(a => *FH)');
	
		seek(FH, 0, 0);
		$w->load(a => \*FH);
		is($ta->get(@idx), $exp, 'load(a => \*FH)');
	
	
		open($fh, "< $file");
		$w->load(a => $fh);
		is($ta->get(@idx), $exp, 'load(a => $fh)');
	
		seek($fh, 0, 0);
		$w->load(a => \$fh);
		is($ta->get(@idx), $exp, 'load(a => \$fh)');
		close($fh);
	
		eval {require IO::File};
		skip('IO::File not available', 5) if $@;
	
		seek(FH, 0, 0);
		$w->load(a => *FH{IO});
		is($ta->get(@idx), $exp, 'load(a => *FH{IO})');
	
		seek(FH, 0, 0);
		$w->load(a => \*FH{IO});
		is($ta->get(@idx), $exp, 'load(a => \*FH{IO})');
	
		close(FH);

		{
			local $^W; # no warnings 'deprecated' would require perl 5.6

			open(FH, "< $file");
			$w->load(a => *FH{FILEHANDLE});
			is($ta->get(@idx), $exp, 'load(a => *FH{FILEHANDLE})');
		
			seek(FH, 0, 0);
		
			$w->load(a => \*FH{FILEHANDLE});
			is($ta->get(@idx), $exp, 'load(a => \*FH{FILEHANDLE})');
		}

		close(FH);

		$fh = IO::File->new($file, 0);
		$w->load(a => $fh);
		is($ta->get(@idx), $exp, 'load(a => IO::File)');
		$fh->close;

		unlink($file);
	}
}

_sdiff: {
	SKIP: {
		eval {require Algorithm::Diff};
		skip('Algorithm::Diff not available', 1) if $@;

		my $a = ["foo\n", "bar\n",    "baz"];
		my $b = ["bar\n", "bazaar\n", "quux\n"];

		my $got = Tk::DiffText::_sdiff($a, $b);
	
		my $exp = [
			['-',   1,   undef],
			['u',   2,     1  ],
			['c',   3,     2  ],
			['+', undef,   3  ],
		];
	
		is_deeply($got, $exp, '_sdiff()');
	}
}
