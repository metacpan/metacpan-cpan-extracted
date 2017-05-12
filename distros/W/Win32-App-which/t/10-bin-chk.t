use strict;
use warnings;
use Test::More;

my @scripts = qw( which );

use Module::Build;

plan tests => 1+9*@scripts;

is(0+keys %{Module::Build->current->scripts}, 0+@scripts, "script count")
  or map { diag $_ } keys %{Module::Build->current->scripts};

foreach (@scripts) {
    my $s = "$_.cmd";

    # Checks that the scripts are prepared with the proper extension
    my @files = grep { -f $_ } map { ("blib/script/$_", "blib/bin/$_") } ($s, "$s~");
    ok(@files ge 1, "$s ready for install");
    ok(@files eq 1, "only one file") or map { diag($_) } @files;

    # Checks that the toolchain does not create bloat
    foreach (map { ("blib/script/$_", "blib/bin/$_") } map { ("$_.cmd", "$_.bat", "$_.pl") } $s) {
	ok(! -f "$_", "$_ has not been created");
    }

    SKIP: {
	skip "($s not prepared)", 1 unless @files gt 0;

	# Check that EOL is Windows-style
	open my $f, '<', $files[0];
	binmode $f;
	my ($content) = do { local $/; (<$f>) };
	close $f;
	$content =~ s/\r\n//g;
	ok($content !~ /[\n\r]/, "only CRLF in $files[0]") or diag length($content);
    }
}
