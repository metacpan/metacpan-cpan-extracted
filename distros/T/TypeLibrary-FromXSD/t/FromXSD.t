#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use Capture::Tiny qw(capture_stdout);
use Test::More;
use TypeLibrary::FromXSD;

{
    my $tl = TypeLibrary::FromXSD->new(
        xsd         => File::Spec->catfile( dirname(__FILE__), 'test.xsd' ),
        version_add => 0.02,
    );
    
    my $code = capture_stdout { $tl->run };
    
    like $code, qr/package Library;/;
}

{
    my $file = File::Spec->catfile( dirname(__FILE__), 'MyTestOuput.pm' );

    my $tl = TypeLibrary::FromXSD->new(
        xsd         => File::Spec->catfile( dirname(__FILE__), 'test.xsd' ),
        namespace   => 'Test::Library',
        version_add => 0.02,
        output      => $file,
    );

    my $stdout = capture_stdout { $tl->run };
    my $check  = do{ local (@ARGV, $/) = File::Spec->catfile( dirname(__FILE__), 'check.txt' ); <> };

    my $generated_code = do{ local (@ARGV, $/) = $file; <> };

    is $generated_code, $check;

    is_deeply [split /\n/, $generated_code], [split /\n/, $check];

    unlink $file;

    ok !-f $file;
}

{
    my $tl = TypeLibrary::FromXSD->new(
        xsd         => File::Spec->catfile( dirname(__FILE__), 'test2.xsd' ),
        version_add => 0.02,
    );
    
    my $code = capture_stdout { $tl->run };
    
    like $code, qr/use DateTime;/;
    like $code, qr/ISODateTime/;
}

{
    my $tl = TypeLibrary::FromXSD->new(
        xsd         => File::Spec->catfile( dirname(__FILE__), 'test3.xsd' ),
        version_add => 0.02,
    );
    
    my $code = capture_stdout { $tl->run };
    
    unlike $code, qr/use DateTime;/;
}

{
    my $file = File::Spec->catfile( dirname(__FILE__), 'MyTestOutput.pm' );

    my $tl = TypeLibrary::FromXSD->new(
        xsd         => File::Spec->catfile( dirname(__FILE__), 'test.xsd' ),
        version_add => 0.02,
        output      => $file,
    );

    my $stdout         = capture_stdout { $tl->run };
    my $generated_code = do{ local (@ARGV, $/) = $file; <> };

    like $generated_code, qr/package MyTestOutput;/;
    unlink $file;

    ok !-f $file;
}

done_testing();
