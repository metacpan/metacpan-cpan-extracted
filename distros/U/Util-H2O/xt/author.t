#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Author tests for the Perl module L<Util::H2O>.

=head1 Author, Copyright, and License

Copyright (c) 2020-2022 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use File::Spec::Functions qw/ updir catfile abs2rel catdir /;
use File::Glob 'bsd_glob';

our ($BASEDIR,@PERLFILES);
BEGIN {
	$BASEDIR = catdir($FindBin::Bin,updir);
	@PERLFILES = (
		catfile($BASEDIR,qw/ lib Util H2O.pm /),
		bsd_glob("$BASEDIR/{t,xt}/*.{t,pm}"),
	);
}

use Test::More tests => 3*@PERLFILES + 6;
BEGIN { use_ok 'Util::H2O' }
note explain \@PERLFILES;

use File::Temp qw/tempfile/;
my $critfn;
BEGIN {
	my $fh; ($fh,$critfn) = tempfile UNLINK=>1;
	print $fh <<'END_CRITIC';
severity = 3
verbose = 9
[ErrorHandling::RequireCarping]
severity = 4
[RegularExpressions::RequireExtendedFormatting]
severity = 2
[Variables::ProhibitReusedNames]
severity = 4
END_CRITIC
	close $fh;
}
use Test::Perl::Critic -profile=>$critfn;
use Test::MinimumVersion;
use Test::Pod;
use Test::DistManifest;
use Pod::Simple::SimpleTree;
use Capture::Tiny qw/capture_merged/;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)
sub warns (&) { my @w; { local $SIG{__WARN__} = sub { push @w, shift }; shift->() } @w }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn)

subtest 'MANIFEST' => sub { manifest_ok() };

pod_file_ok($_) for @PERLFILES;

my @tasks;
for my $file (@PERLFILES) {
	critic_ok($file);
	minimum_version_ok($file, '5.006');
	open my $fh, '<', $file or die "$file: $!";  ## no critic (RequireCarping)
	while (<$fh>) {
		s/\A\s+|\s+\z//g;
		push @tasks, [abs2rel($file,$BASEDIR), $., $_] if /TO.?DO/i;
	}
	close $fh;
}

subtest 'namespace::clean' => sub { plan tests=>4;
	# This is just a copy of the test from the main tests with namespace::clean added in.
	{
		package Yet::Another;  ## no critic (ProhibitMultiplePackages)
		use Util::H2O;
		use namespace::clean;
		h2o -classify, { hello=>sub{"World!"} }, qw/abc/;
		sub test { return "<".shift->abc.">" }
	}
	my $o = new_ok 'Yet::Another', [ abc=>"def" ];
	is $o->hello, "World!", 'getter';
	is $o->test, "<def>", 'method';
	ok !exists &Yet::Another::h2o, 'cleaned';
};

subtest 'destroy errors' => sub { plan tests=>2;
	# Possible To-Do for Later: For a reason I can't explain yet, the warning from the destructor is not always captured by the signal handler here.
	# Strangely, this same test changed its behavior in this current commit (-classify=>{...}) when in the main test file,
	# but when I moved the test into this test file, it changed its behavior again. This feels really buggy!
	# perlbrew exec perl -e 'sub Foo::DESTROY{warn"x"}my$x=bless{},"Foo";local$SIG{__WARN__}=sub{print"<<".shift().">>"};$x=undef'
	# Both the "local" and the "$x=undef" appear to be significant in the above.
	# So for now, I have moved this test to the author tests so I can use Capture::Tiny.
	#is grep({/foobar/} warns {
	like capture_merged {
		my $exp;
		my $od = h2o -destroy=>sub {
			is ref $_[0], $exp, 'destructor called as expected' or diag explain $_[0];
			die "this warning is expected: foobar" }, {};  ## no critic (RequireCarping)
		$exp = ref $od;
		$od = undef;
	#}), 0, 'warning from constructor was not captured by __WARN__';
	}, qr/^this warning is expected: foobar at .+/s, 'destructor error becomes warning';
};

subtest 'synopsis code' => sub { plan tests=>8;
	my $verbatim = getverbatim($PERLFILES[0], qr/\b(?:synopsis)\b/i);
	is @$verbatim, 1, 'verbatim block count' or diag explain $verbatim;
	is capture_merged {
		my $code = <<"END_CODE"; eval "{$code\n;1}" or die $@; ## no critic (ProhibitStringyEval, RequireCarping)
			use warnings; use strict;
			$$verbatim[0]
			;
			is_deeply \$hash, { foo=>'bar', x=>'z', more=>'cowbell' }, 'synopsis \$hash';
			is_deeply \$struct, { hello => { perl => "world!" } }, 'synopsis \$struct';
			isa_ok \$one, 'Point';
			is_deeply \$one, { x=>1, y=>2 }, 'synopsis \$one';
			isa_ok \$two, 'Point';
			is_deeply \$two, { x=>3, y=>4 }, 'synopsis \$two';
END_CODE
	}, "bar\nworld!\nbeans\n0.927\n", 'output of synopsis correct';
};

subtest 'cookbook code' => sub { plan tests=>22;
	my $codes = getverbatim($PERLFILES[0], qr/\b(?:cookbook)\b/i);
	is @$codes, 7, 'verbatim block count';
	my ($c_map,$c_cfg,$c_db1,$c_db2,$c_auto,$c_up1,$c_up2) = @$codes;
	# pairmap
	is capture_merged {
		eval "{ use warnings; use strict; $c_map\n;1}" or die $@;  ## no critic (ProhibitStringyEval, RequireCarping)
	}, "123456\n", 'pairmap example output correct';
	# Config::Tiny
	is capture_merged {
		my ($tfh, $config_filename) = tempfile(UNLINK=>1);
		print $tfh "[foo]\nbar=quz\n";
		close $tfh;
		my $code2 = <<"END CODE"; eval "{$code2\n;1}" or die $@;  ## no critic (ProhibitStringyEval, RequireCarping)
			use warnings; use strict;
			use feature 'say';
			use Config::Tiny 2.27;
			$c_cfg
END CODE
		open my $fh, '<', $config_filename or die $!;  ## no critic (RequireCarping)
		my $cfg = do { local $/=undef; <$fh> };
		close $fh;
		is $cfg, "[foo]\nbar=Hello, World!\n", 'config file correct';
	}, "quz\n", 'config output correct';
	# test statement in docs about nested hashes
	my $config = Config::Tiny->new({%{ h2o -recurse, { hello => { world => "xyz" }} }});
	isa_ok $config, 'Config::Tiny';
	like ref($config->{hello}), $Util::H2O::_PACKAGE_REGEX, 'nested hash as expected';  ## no critic (ProtectPrivateVars)
	is $config->{hello}->world, "xyz", 'call method in nested hash';
	# Debugging
	( my $exp1 = "$c_db2\n" ) =~ s/^\ //mg;
	is capture_merged {
		eval "{ use warnings; use strict; $c_db1\n;1}" or die $@;  ## no critic (ProhibitStringyEval, RequireCarping)
	}, $exp1, 'debugging output correct';
	# Autoloading Example
	is capture_merged {
		eval "{ use warnings; use strict; $c_auto\n;1}" or die $@;  ## no critic (ProhibitStringyEval, RequireCarping)
	}, "", 'autoloading output empty';
	my $auto = new_ok 'HashLikeObj';
	is $auto->foobar, undef, 'read unknown hash key';
	$auto->abc(1234);
	is $auto->defghi(5678), 5678, 'setter rv';
	is_deeply $auto, { abc=>1234, defghi=>5678 }, 'hash as expected';
	# Upgrading to Moo
	is capture_merged {
		eval "{ use warnings; use strict; $c_up1\n;1}" or die $@;  ## no critic (ProhibitStringyEval, RequireCarping)
	}, "", 'upgrading output 1 empty';
	my $x = new_ok "My::Class", [ foo=>"bar", details => new_ok "My::Class::Details", [ a=>123, b=>456 ] ];
	is_deeply $x, { foo=>"bar", details=>{a=>123,b=>456} }, 'data structure 1 is correct';
	is capture_merged {
		eval "{ use warnings; use strict; $c_up2\n;1}" or die $@;  ## no critic (ProhibitStringyEval, RequireCarping)
	}, "", 'upgrading output 2 empty';
	my $y = new_ok "My::Class2", [ foo=>"bar", details => new_ok "My::Class2::Details", [ a=>123, b=>456 ] ];
	is_deeply $y, { foo=>"bar", details=>{a=>123,b=>456} }, 'data structure 2 is correct';
	ok exception { My::Class2->new( foo=>"bar", details=>My::Class::Details->new(a=>444,b=>555) ) }, 'type checking works';
};

diag "To-","Do Report: ", 0+@tasks, " To-","Dos found";
diag "### TO","DOs ###" if @tasks;
diag "$$_[0]:$$_[1]: $$_[2]" for @tasks;
diag "### ###" if @tasks;
diag "To run coverage tests:\nperl Makefile.PL && make authorcover && firefox cover_db/coverage.html\n"
	. "rm -rf cover_db && make distclean && git clean -dxn";

sub getverbatim {
	my ($file,$regex) = @_;
	my $tree = Pod::Simple::SimpleTree->new->parse_file($file)->root;
	my ($curhead,@v);
	for my $e (@$tree) {
		next unless ref $e eq 'ARRAY';
		if (defined $curhead) {
			if ($e->[0]=~/^\Q$curhead\E/) { $curhead = undef }
			elsif ($e->[0] eq 'Verbatim') { push @v, $e->[2] }
		}
		elsif ($e->[0]=~/^head\d\b/ && $e->[2]=~$regex)
			{ $curhead = $e->[0] }
	}
	return \@v;
}
