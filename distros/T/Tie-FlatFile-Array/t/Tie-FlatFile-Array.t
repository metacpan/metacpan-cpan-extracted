
use Test::More tests => 10;
use strict;
use warnings;
no warnings 'once';
use Tie::FlatFile::Array;
use t::FF_Common;
use File::Spec::Functions qw(catfile splitpath);
use Fcntl;
use Fatal qw(open close);

t::FF_Common::init();

my @search = (
	[ 'www.google.com', 38119, 'QX', 8 ],
	[ 'www.yahoo.com', 21569, 'TL', 42 ],
	[ 'www.ask.com', 19834, 'RA', 17 ],
	[ 'www.lycos.com', 12763, 'AC', 69 ],
	[ 'www.go.com', 10991, 'GO', 114 ],
);
my $pkfmt = 'A30NA2L';
my ($data, @scopy);
my @array;

my $basefile = catfile($Common{tempdir}, 't.base.dbf');

# Create a "base-file" to test against.
unslurp_file($basefile,
	map { pack $pkfmt, @$_ } @search
	);

# Test using array indexes.
unlink testfile(1);
tie @array, 'Tie::FlatFile::Array', testfile(1),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
foreach my $nx (0..$#search) {
	$array[$nx] = $search[$nx];
}
untie @array;
ok(diff($basefile, testfile(1)), 'use indexes');

# Test using push.
unlink testfile(2);
tie @array, 'Tie::FlatFile::Array', testfile(2),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
push @array, $_ for (@search);
untie @array;
ok(diff($basefile, testfile(2)), 'use push');

# Test EXTEND.
unlink testfile(3), testfile('3b');
unslurp_file(testfile(3),
	map { pack $pkfmt, @$_ } @search[2,4]
	);
tie @array, 'Tie::FlatFile::Array', testfile('3b'),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
@array = @search[2,4];
untie @array;
ok(diff(testfile(3),testfile('3b')),'extend');

# Test reading from the file
my @lines;
my $reclen = length pack $pkfmt, (1) x 30;
unslurp_file(testfile(4), slurp_file(testfile('3b')));
open (FH, '<', testfile('4'));
open (OFH, '>', testfile('4b'));
{
	local $/ = \$reclen;
	while (my $ln = <FH>) {
		print OFH "@{[ unpack $pkfmt, $ln ]}\n";
	}
}
close(OFH);
close(FH);

open (OFH, '>', testfile('4c'));
tie @array, 'Tie::FlatFile::Array', testfile(4),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };

foreach my $index (0..$#array) {
	my $list = $array[$index];
	print OFH "@$list\n";
}

untie @array;
close(OFH);
ok(diff(testfile('4b'),testfile('4c')),'unpack the file two ways');

# Test that opening and closing a file does not change it.
copy_binary(testfile(4),testfile(5));
my $version1 = slurp_file(testfile(5));
tie @array, 'Tie::FlatFile::Array', testfile(5),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
untie @array;
my $version2 = slurp_file(testfile(5));
ok(length($version1) > 0,'test file 5 (copy of 4) has content');
ok($version1 eq $version2, 'opening and closing a file does not change it');

# Test using 'unshift'.
my @moresearch = (
	[ 'www.aie.com', 61994, 'TP', 160773],
	[ 'web.yani.net', 7152, 'YB', 82647 ],
	[ 'host.fox.com', 60833, 'CX', 4552601 ],
	);
copy_binary($basefile,testfile(7));
tie @array, 'Tie::FlatFile::Array', testfile('7'),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
my $unshift = unshift @array, @moresearch;
untie @array;

tie @array, 'Tie::FlatFile::Array', testfile('7b'),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
@array = (@moresearch, @search);
untie @array;
ok(diff(testfile(7),testfile('7b')), 'unshift');

# Test 'unshift' another way (against using 'pack').
unslurp_file(testfile(8),
	map { pack $pkfmt, @$_ } (@moresearch,@search) );
ok(diff(testfile(7),testfile(8)),'compare using unshift to using map');

# Test the return value from 'unshift.'
ok((@search + @moresearch) == $unshift, 'unshift return value');

# Test that going out of bounds produces an error.
# my ($dummy, $evalerr);
# tie @array, 'Tie::FlatFile::Array', testfile('8'),
# 	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
# eval { $dummy = $array[14] };
# $evalerr = $@;
# untie @array;
# ok($evalerr =~ /^\Qindex (14) out of bounds/,'going out of bounds produces an error');

# Test that going out of bounds produces "undef".
tie @array, 'Tie::FlatFile::Array', testfile('8'),
	O_RDWR | O_CREAT, 0644, { packformat => $pkfmt };
$data = $array[14];
ok(!defined($data),'going out of bounds produces "undef"');
untie @array;

t::FF_Common::cleanup;

