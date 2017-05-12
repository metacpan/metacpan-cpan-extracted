#!/usr/bin/perl -w

use strict;
use FindBin;
#use lib "$FindBin::Bin/../inc";
#use lib "$FindBin::Bin/../lib";
#use lib "$FindBin::Bin/../../Parse-Binary/lib";
use Test::More tests => 46;
use File::Copy;
use Config;

$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };
$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };

use_ok('Win32::Exe');
use_ok('Win32::Exe::Manifest');
use Win32::Exe;

my $perl = $^X;
my $exeupdate = qq($FindBin::Bin/../blib/script/exe_update.pl);

for ( qw( 32  64 ) ) {
    my $PEtype = $_;
    my $cansafelyexecute = ($^O !~ /^mswin/i)
        ? 0
        : ($PEtype == 32)
            ? 1
            : ( exists($ENV{PROCESSOR_ARCHITECTURE}) && $ENV{PROCESSOR_ARCHITECTURE} =~ /64/ )
                ? 1 : 0;
    
    my $bindir = $FindBin::Bin;
    
    my $parexe = "$bindir/winexe$_.exe";
    my $testexe = "$bindir/updatetestexe$_.exe";
        
    File::Copy::copy($parexe, $testexe);
    
    my $testinfo = { Comments => 'Some Test Comments',
                     CompanyName => 'Test Company',
                     FileDescription => 'A file description',
                     FileVersion    => '7.8.9.10',
                     InternalName   => 'falsename.exe',
                     LegalCopyright => 'Copyright Me',
                     LegalTrademarks => 'Trademark Hopeful',
                     OriginalFilename => 'anotherfalsename.exe',
                     ProductName => 'Win32-Exe-Update',
                     ProductVersion => '21.22.23.24',
                     };
    
    my $manifestargs = { ExecName => 'My.Test.Application',
                         Description => 'My App Description',
                         ExecutionLevel => 'asInvoker',
                         CommonControls => 1,
                         Version => '5.4.3.2',
                        };
    
    my $iconfile = "$FindBin::Bin/hd.ico";
    
    my $pathquote = ($^O =~ /^mswin/i) ? '"' : '';
    
    my $iconparam = '--icon=' . $pathquote . $iconfile . $pathquote;
    my @args = ( $exeupdate, '--console',  $iconparam);
        
    foreach my $infoarg ( sort keys (%$testinfo)) {
        push(@args, '--info=' . $infoarg . '=' . $testinfo->{$infoarg});
    }
    
    foreach my $marg ( sort keys (%$manifestargs)) {
        push(@args, '--manifestargs=' . $marg . '=' . $manifestargs->{$marg});
    }
    
    push(@args, $testexe);
    
    my $result = system($perl, @args);
    
    is( $result, '0', qq(Check exec $PEtype bit));
    my $exe = Win32::Exe->new($testexe);
    isa_ok($exe, 'Win32::Exe');
    ok($exe->has_manifest, qq($PEtype has manifest));
    my $mnf = $exe->get_manifest;
    
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest $PEtype));

    my $inforef = $exe->get_version_info;
    
    foreach my $infoarg ( sort keys (%$testinfo)) {
        # 10 tests
        is($inforef->{$infoarg}, $testinfo->{$infoarg}, qq($PEtype bit info $infoarg));
    }
    
    is($exe->get_subsystem, 'console', qq($PEtype bit subsystem));
    
    is( $mnf->get_assembly_name, $manifestargs->{ExecName}, qq(manifest name $PEtype bit) );
    is( $mnf->get_assembly_version, $manifestargs->{Version}, qq(manifest version $PEtype bit) );
    is( $mnf->get_assembly_description, $manifestargs->{Description}, qq(manifest description $PEtype bit) );
    is( $mnf->get_execution_level, $manifestargs->{ExecutionLevel}, qq(manifest execution level $PEtype bit) );
    is( $mnf->get_uiaccess, 'false', qq(manifest ui access $PEtype bit) );
    
    my $dep = $mnf->get_dependency('Microsoft.Windows.Common-Controls');
    is_deeply(
        $dep,
         { type => 'win32', name => 'Microsoft.Windows.Common-Controls', version => '6.0.0.0',
            processorArchitecture => '*', publicKeyToken => '6595b64144ccf1df', language => '*' } ,
        qq($PEtype bit Common Controls)
    );
    
    SKIP: {
        skip qq(Cannot Execute $PEtype bit Windows application on this architecture), 1 if !$cansafelyexecute;
        like( qx($testexe 2>&1), qr/^Win32::Exe Test Executable$/, qq(Execute $PEtype bit executable) );
    }
    
    unlink $testexe;
    
}

1;
