
use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Wx::Perl::IconDepot') };

use Wx;
use Module::Load::Conditional qw( can_load );

my $num_of_tests = 205;
unless (can_load(modules => {'Image::LibRSVG' => '0.07'})) { 
	$num_of_tests = 133;
}

my @iconpath = ('t/Themes');
my @theme = qw( png_1 png_2 svg_1 );

my $listvalidate = sub { return &ListCompare(@_) };
my $imgvalidate = sub { my $img = shift; return $img->IsOk };

my $depot = new Wx::Perl::IconDepot( \@iconpath );
ok (defined $depot, "creation");

$depot->SetThemes(@theme);

my @tests = (
	{
		name => 'Available themes',
		args => [],
		method => 'AvailableThemes',
		expected => [ 'png_1', 'png_2', 'svg_1' ]
	},
	{
		name => 'Active themes',
		args => [],
		method => 'GetActiveThemes',
		expected => [ 'png_1', 'png_2', 'svg_1' ]
	},

	# Testing available contexts
	{
		name => 'All available contexts',
		args => ['png_1' ],
		method => 'AvailableContexts',
		expected => [ 'Actions', 'Applications', ]
	},
	{
		name => 'Available contexts in name',
		args => ['png_1', 'edit-cut' ],
		method => 'AvailableContexts',
		expected => [ 'Actions', ]
	},
	{
		name => 'No available contexts in name',
		args => ['png_1', 'does-not-exist' ],
		method => 'AvailableContexts',
		expected => [ ]
	},
	{
		name => 'Available contexts in name and size',
		args => ['png_1', 'edit-cut', 32 ],
		method => 'AvailableContexts',
		expected => [ 'Actions', ]
	},
	{
		name => 'No available contexts in name and size 1',
		args => ['png_1', 'does-not-exist', 32 ],
		method => 'AvailableContexts',
		expected => [ ]
	},
	{
		name => 'No available contexts in name and size 2',
		args => ['png_1', 'edit-cut', 45 ],
		method => 'AvailableContexts',
		expected => [ ]
	},
	{
		name => 'Available contexts in size',
		args => ['png_1', undef, 22 ],
		method => 'AvailableContexts',
		expected => [ 'Actions', 'Applications', ]
	},
	{
		name => 'No available contexts in size',
		args => ['png_1', undef, 46 ],
		method => 'AvailableContexts',
		expected => [ ]
	},

	# Testing available icons
	{
		name => 'All available icons',
		args => ['png_1' ],
		method => 'AvailableIcons',
		expected => [ 'accessories-text-editor', 'document-new', 'document-save', 'edit-cut', 'edit-find',
			'help-browser', 'multimedia-volume-control', 'system-file-manager' ]
	},
	{
		name => 'Available icons in size',
		args => ['png_1', 32 ],
		method => 'AvailableIcons',
		expected => [ 'accessories-text-editor', 'edit-cut', 'edit-find', 'help-browser' ]
	},
	{
		name => 'No available icons in size',
		args => ['png_1', 47 ],
		method => 'AvailableIcons',
		expected => [ ]
	},
	{
		name => 'Available icons in size and context',
		args => ['png_1', 32, 'Actions' ],
		method => 'AvailableIcons',
		expected => [ 'edit-cut', 'edit-find', ]
	},
	{
		name => 'No available icons in size and context 1',
		args => ['png_1', 48, 'Actions' ],
		method => 'AvailableIcons',
		expected => [ ]
	},
	{
		name => 'No available icons in size and context 2',
		args => ['png_1', 32, 'Blobber' ],
		method => 'AvailableIcons',
		expected => [ ]
	},
	{
		name => 'Available icons in context',
		args => ['png_1', undef, 'Actions' ],
		method => 'AvailableIcons',
		expected => [ 'document-new', 'document-save', 'edit-cut', 'edit-find' ]
	},
	{
		name => 'No available icons in context',
		args => ['png_1', undef, 'Blobber' ],
		method => 'AvailableIcons',
		expected => [ ]
	},

	# Testing available sizes
	{
		name => 'All available sizes',
		args => ['png_1' ],
		method => 'AvailableSizes',
		expected => [ 22, 32 ]
	},
	{
		name => 'Available sizes in name',
		args => ['png_1', 'edit-cut'],
		method => 'AvailableSizes',
		expected => [ 32 ]
	},
	{
		name => 'No available sizes in name',
		args => ['png_1', 'does-not-exist'],
		method => 'AvailableSizes',
		expected => [ ]
	},
	{
		name => 'Available sizes in name and context',
		args => ['png_1', 'edit-cut', 'Actions'],
		method => 'AvailableSizes',
		expected => [ 32 ]
	},
	{
		name => 'No available sizes in name and context 1',
		args => ['png_1', 'does-not-exist', 'Actions' ],
		method => 'AvailableSizes',
		expected => [ ]
	},
	{
		name => 'No available sizes in name and context 2',
		args => ['png_1', 'edit-cut', 'Blobber' ],
		method => 'AvailableSizes',
		expected => [ ]
	},
	{
		name => 'Available sizes in context',
		args => ['png_1', undef, 'Actions'],
		method => 'AvailableSizes',
		expected => [ 22, 32 ]
	},
	{
		name => 'No available sizes in context',
		args => ['png_1', undef, 'Blobber'],
		method => 'AvailableSizes',
		expected => [ ]
	},

	# Testing finding icon files
	{
		name => 'Find correct size',
		args => ['document-new', 22, 'Actions' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG1/actions/22/document-new.png' ]
	},
	{
		name => 'Find incorrect size',
		args => ['document-new', 32, 'Actions' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG1/actions/22/document-new.png' ]
	},
	{
		name => 'Find incorrect context',
		args => ['document-new', 22, 'Applications' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG1/actions/22/document-new.png' ]
	},
	{
		name => 'Find in fallback theme',
		args => ['arrow-down', 22, 'Actions' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG2/actions/22/arrow-down.png' ]
	},
	{
		name => 'Find nothing',
		args => ['no-exist', 22, 'Applications' ],
		method => 'FindImage',
		expected => [ undef ]
	},

	# Tests for loading bitmapped icons

	{
		name => 'Loading non existing without forcing missing image',
		args => ['does-not-exist', 22],
		method => 'GetImage',
		expected => 0,
		validate => 'image',
		checksize => 22,
	},
	{
		name => 'Loading non existing, forcing missing image',
		args => ['does-not-exist', 22, undef, 1],
		method => 'GetImage',
		expected => 1,
		validate => 'image',
		checksize => 22,
	},


);

# More tests for loading bitmapped icons
my @names = $depot->AvailableIcons('png_1');
my @sizes = $depot->AvailableSizes('png_1');
&CreateImageTests(\@names, \@sizes, {
	validate => 'image',
});

# Tests for loading svg icons
my @svgnames = $depot->AvailableIcons('svg_1');
my @svgsizes = $depot->AvailableSizes('svg_1');
&CreateImageTests(\@svgnames, \@svgsizes, {
	validate => 'image',
	is_svg => 1,
});

for (@tests) {
	my $checksize;
	if (exists $_->{checksize}) {
		$checksize = $_->{checksize}
	}
	my $args = $_->{args};
	my $expected = $_->{expected};
	my $is_svg = 0;
	if (exists $_->{is_svg}) {
		$is_svg = $_->{is_svg}
	}
	my $method = $depot->can($_->{method});
	my $name = $_->{name};
	my $validate = 'list';
	if (exists $_->{validate}) {
		$validate = $_->{validate}
	}
	my @result = &$method($depot, @$args);
	if ($validate eq 'list') {
		ok(&ListCompare($expected, \@result), $name);
	} elsif ($validate eq 'image') {
		my $img = $result[0];
		my $outcome = 0;
		if ((defined $img) and ($img->IsOk)) { $outcome = 1 }
		is ($outcome, $expected, $name);
		if (defined $checksize) {
			SKIP: {
				skip 'Previous test returned no image.', 1 unless $outcome;
				ok((($img->GetHeight eq $checksize) and ($img->GetWidth eq $checksize)), 'Check size');
			}
		}
	} else {
		ok(&$validate($expected, \@result), $name);
	}
}

done_testing($num_of_tests);

sub CreateImageTests {
	my ($nms, $szs, $empty) = @_;
	my @methods = qw(GetBitmap GetIcon GetImage);
	for (@methods) {
		my $method = $_;
		for (@$nms) {
			my $name = $_;
			for (@$szs) {
				my $size = $_;
				my %test = %$empty;
				$test{name} = "$method, $name, $size";
				$test{checksize} = $size;
				$test{method} = $method;
				$test{args} = [ $name, $size ];
				$test{expected} = 1;
				$test{validate} = 'image';
				push @tests, \%test;
			}
		}
	}
}

sub ListCompare {
	my ($l1, $l2) = @_;
	my $size1 = @$l1;
	my $size2 = @$l2;
	if ($size1 ne $size2) { return 0 }
	foreach my $item (0 .. $size1 - 1) {
		my $test1 = $l1->[$item];
		unless (defined $test1) { $test1 = 'UNDEF' }
		my $test2 = $l2->[$item];
		unless (defined $test2) { $test2 = 'UNDEF' }
		if ($test1 ne $test2) { return 0 }
	}
	return 1
}

sub PrintListResult {
	my ($l1, $l2) = @_;
	print "Expected: ";
	&PrintResult(@$l1);
	print "     Got: ";
	&PrintResult(@$l2);
}

sub PrintResult {
	for (@_) {
		if (defined($_)) {
			print "$_ ; "
		} else {
			print "UNDEF ; "
		}
	}
	print "\n"
}

