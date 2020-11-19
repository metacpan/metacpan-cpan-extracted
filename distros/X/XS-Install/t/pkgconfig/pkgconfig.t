use strict;
use warnings;
use Cwd;
use Test::More;
use Test::Deep;
use XS::Install;

$ENV{PKG_CONFIG_PATH} = Cwd::abs_path('t/pkgconfig');

chdir 't/pkgconfig/mod' or die $!;

subtest 'basic' => sub {
    my $args = XS::Install::makemaker_args(
        NAME       => 'TestMod',
        PKG_CONFIG => 'mylib',
    );
    
    like $args->{INC}, qr#-I/prefix/include#;
    unlike $args->{INC}, qr#-kewlflag#;
    like $args->{CCFLAGS}, qr#-kewlflag#;
    like $args->{dynamic_lib}{OTHERLDFLAGS}, qr#-L/prefix/lib/arch -lmylib1 -lmylib2#;
};

subtest 'BIN_SHARE' => sub {
    subtest 'explicit' => sub {
        my $args = XS::Install::makemaker_args(
            NAME      => 'TestMod',
            BIN_SHARE => {
                PKG_CONFIG => 'mylib',
            },
        );
        
        unlike $args->{INC}, qr#-I/prefix/include#;
        unlike $args->{CCFLAGS}, qr#-kewlflag#;
        unlike $args->{dynamic_lib}{OTHERLDFLAGS}, qr#-lmylib1#;
        
        
        open my $fh, '<', 'blib/info' or die $!;
        my $content = join '', <$fh>;
        close $fh;
        my $info = eval $content;
        like $info->{INC}, qr#-I/prefix/include#;
        like $info->{CCFLAGS}, qr#-kewlflag#;
        like $info->{LINK}, qr#-L/prefix/lib/arch -lmylib1 -lmylib2#;
    };
    
    subtest 'auto' => sub {
        my $args = XS::Install::makemaker_args(
            NAME       => 'TestMod',
            PKG_CONFIG => 'mylib',
            BIN_SHARE  => {},
        );
        
        like $args->{INC}, qr#-I/prefix/include#;
        like $args->{CCFLAGS}, qr#-kewlflag#;
        like $args->{dynamic_lib}{OTHERLDFLAGS}, qr#-lmylib1#;
        
        
        open my $fh, '<', 'blib/info' or die $!;
        my $content = join '', <$fh>;
        close $fh;
        my $info = eval $content;
        like $info->{INC}, qr#-I/prefix/include#;
        like $info->{CCFLAGS}, qr#-kewlflag#;
        like $info->{LINK}, qr#-L/prefix/lib/arch -lmylib1 -lmylib2#;
    };
    
    subtest 'exclude' => sub {
        my $args = XS::Install::makemaker_args(
            NAME       => 'TestMod',
            PKG_CONFIG => '-mylib1',
            BIN_SHARE  => {PKG_CONFIG => 'mylib2'},
        );
        
        like $args->{INC}, qr#-I/prefix/include#;
        like $args->{CCFLAGS}, qr#-kewlflag#;
        like $args->{dynamic_lib}{OTHERLDFLAGS}, qr#-lmylib1#;
        
        open my $fh, '<', 'blib/info' or die $!;
        my $content = join '', <$fh>;
        close $fh;
        my $info = eval $content;
        like $info->{INC}, qr#-I/prefix/include#;
        unlike $info->{CCFLAGS}, qr#-kewlflag#;
        like $info->{LINK}, qr#-L/prefix/lib/arch -lmylib2#;
    };
};

done_testing();