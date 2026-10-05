use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd qw(getcwd);
use Uniform::HTTP::FastPath;

is Uniform::HTTP::FastPath::ABI_VERSION(), 1, 'Perl ABI unchanged';
is Uniform::HTTP::FastPath::NATIVE_ABI_VERSION(), 1, 'native ABI version';
ok Uniform::HTTP::FastPath::native_compatible(1, 1), 'native layout supported';
for my $args ([], [1], [1, 1, 1], [2, 1], [1, 2], [undef, 1],
    [1, undef], [[], 1], [1, {}], ['1x', 1], [1, '-1']) {
    ok !Uniform::HTTP::FastPath::native_compatible(@$args), 'bad handshake rejected';
}
my $dir = Uniform::HTTP::FastPath::native_include_dir();
ok(File::Spec->file_name_is_absolute($dir), 'include directory is absolute');
my $header = File::Spec->catfile($dir, 'uniform_http_fastpath.h');
ok -f $header, 'native header ships and installs alongside Perl module';
my $cwd = getcwd();
chdir File::Spec->rootdir() or die $!;
is Uniform::HTTP::FastPath::native_include_dir(), $dir, 'header location survives a directory change';
chdir $cwd or die $!;
open my $fh, '<', $header or die $!;
my $text = do { local $/; <$fh> };
like $text, qr/#define UHTTP_NATIVE_ABI_VERSION 1\b/, 'header ABI matches runtime';
like $text, qr/#define UHTTP_PRIVATE_LAYOUT_VERSION 1\b/, 'storage revision matches';
my $request = Uniform::HTTP::Request->new(method => 'GET', target => '/');
is $request->method, 'GET', 'ordinary operation needs no native extension';
ok !exists $INC{'Uniform/HTTP/NativeTest.pm'}, 'author XS fixture is not loaded';
done_testing;
