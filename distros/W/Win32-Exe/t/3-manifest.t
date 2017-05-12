#!/usr/bin/perl -w

use strict;
use FindBin;
#use lib "$FindBin::Bin/../inc";
#use lib "$FindBin::Bin/../lib";
#use lib "$FindBin::Bin/../../Parse-Binary/lib";
use Test::More tests => 136;
use File::Copy;
use Config;

$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };
$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };

use_ok('Win32::Exe');
use_ok('Win32::Exe::Manifest');

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
    my $testexe = "$bindir/testexe$_.exe";
    my $extendedexe = "$bindir/extendedexe$_.exe";
    
    File::Copy::copy($parexe, $testexe);

    my $exe = Win32::Exe->new($testexe);
    isa_ok($exe, 'Win32::Exe', qq(Win32::Exe $PEtype));

    my $manifest = $exe->manifest();
    isa_ok($manifest, 'Win32::Exe::Resource::Manifest', qq(Win32::Exe::Resource::Manifest $PEtype));

    my $xml = $manifest->default_manifest;
    ok($exe->update( 'manifest' => $xml ), qq(update $PEtype));
    unlink $testexe;
        
    File::Copy::copy($parexe, $extendedexe);
    my $testexecname = qq($bindir/manifesttest.exe);
    
    # get the xml file content
    open my $fh, '<', qq($bindir/application.xml);
    my $appxml = do { local $/; <$fh> };
    close($fh);
    open $fh, '<', qq($bindir/empty.xml);
    my $emptyxml = do { local $/; <$fh> };
    close($fh);
    
    $exe = Win32::Exe->new($extendedexe);
    
    isa_ok($exe, 'Win32::Exe');
    
    ok($exe->has_manifest, qq($PEtype has manifest));
    my $mnf = $exe->get_manifest;
    
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest $PEtype));
    
    is( $mnf->get_resource_id, 1, qq(First check resource id $PEtype) );
    is( $mnf->get_assembly_name, 'Win32.Exe.Test', qq(First check manifest name $PEtype) );
    is( $mnf->get_assembly_version, '1.0.0.0', qq(First check manifest version $PEtype) );
    is( $mnf->get_assembly_language, '*', qq(First check manifest language $PEtype) );
    is( $mnf->get_assembly_architecture, '*', qq(First check manifest architecture $PEtype) );
    is( $mnf->get_execution_level, 'asInvoker', qq(First check execution level $PEtype) );
    is( $mnf->get_uiaccess, 'false', qq(First check ui access $PEtype) );
    
    my @deps = $mnf->get_dependencies;
    is_deeply(
        \@deps,
        [ { type => 'win32', name => 'Microsoft.Windows.Common-Controls', version => '6.0.0.0',
            processorArchitecture => '*', publicKeyToken => '6595b64144ccf1df', language => '*' } ],
        qq($PEtype get dependencies)
    );
    
    my $newmnf = Win32::Exe::Manifest->new($emptyxml, 'application');
    $newmnf->set_resource_id(2);
    $exe->set_manifest($newmnf);
    $exe->write;
    
    undef $exe;
    
    $exe = Win32::Exe->new($extendedexe);
    isa_ok($exe, 'Win32::Exe', 'AFTER WRITE');
    
    ok($exe->has_manifest, qq($PEtype has manifest after write));
    $mnf = $exe->get_manifest;
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest after write $PEtype));
    
    is( $mnf->get_resource_id, 2, qq(Empty check resource id $PEtype) );
    is( $mnf->get_assembly_name, 'My.Empty.Application', qq(Empty check manifest name $PEtype) );
    is( $mnf->get_assembly_version, '2.0.0.0', qq(Empty check manifest version $PEtype) );
    is( $mnf->get_assembly_language, '*', qq(Empty check manifest language $PEtype) );
    is( $mnf->get_assembly_architecture, '*', qq(Empty check manifest architecture $PEtype) );
    is( $mnf->get_execution_level, 'none', qq(Empty check execution level $PEtype) );
    is( $mnf->get_uiaccess, undef, qq(Empty check ui access $PEtype) );
    
    @deps = $mnf->get_dependencies;
    is(scalar(@deps), 0, qq(Empty check dependencies $PEtype) );
    
    my $arch = ( $PEtype == 64 ) ? 'amd64' : 'x86';
    
    $mnf->set_execution_level('requireAdministrator');
    $mnf->add_common_controls;
    $mnf->set_assembly_name('Enhanced.App');
    $mnf->set_assembly_version('1.2.3.4');
    $mnf->set_assembly_architecture($arch);
    $mnf->set_resource_id(3);
    $mnf->set_compatibility('Windows Vista');
    $exe->set_manifest($mnf);
    $exe->write;
    undef $exe;
    
    $exe = Win32::Exe->new($extendedexe);
    isa_ok($exe, 'Win32::Exe', 'AFTER UPDATE');
    
    ok($exe->has_manifest, qq($PEtype has manifest after update));
    $mnf = $exe->get_manifest;
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest after update $PEtype));
    
    is( $mnf->get_resource_id, 3, qq(Write check resource id $PEtype) );
    is( $mnf->get_assembly_name, 'Enhanced.App', qq(Write check manifest name $PEtype) );
    is( $mnf->get_assembly_version, '1.2.3.4', qq(Write check manifest version $PEtype) );
    is( $mnf->get_assembly_language, '*', qq(Write check manifest language $PEtype) );
    is( $mnf->get_assembly_architecture, $arch, qq(Write check manifest architecture $PEtype) );
    is( $mnf->get_execution_level, 'requireAdministrator', qq(Write check execution level $PEtype) );
    is( $mnf->get_uiaccess, 'false', qq(Write check ui access $PEtype) );
    
    @deps = $mnf->get_dependencies;
    is_deeply(
        \@deps,
        [ { type => 'win32', name => 'Microsoft.Windows.Common-Controls', version => '6.0.0.0',
            processorArchitecture => '*', publicKeyToken => '6595b64144ccf1df', language => '*' } ],
        qq($PEtype get dependencies after update)
    );
    
    my @compat = $mnf->get_compatibility;
    is_deeply(
        \@compat,
        [ qw( {e2011457-1546-43c5-a5fe-008deee3d3f0} ) ],
        qq($PEtype get compatibility after update)
    );
    
    $mnf->remove_dependency('Microsoft.Windows.Common-Controls');
    $mnf->set_resource_id(1);
    $mnf->set_execution_level('asInvoker');
    $exe->set_manifest($mnf);
    $exe->write;
    undef $exe;
    
    $exe = Win32::Exe->new($extendedexe);
    isa_ok($exe, 'Win32::Exe', 'AFTER CHANGE');
    
    ok($exe->has_manifest, qq($PEtype has manifest after change));
    $mnf = $exe->get_manifest;
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest after change $PEtype));
    
    is( $mnf->get_resource_id, 1, qq(Changed check resource id $PEtype) );
    is( $mnf->get_execution_level, 'asInvoker', qq(Changed check execution level $PEtype) );
    is( $mnf->get_uiaccess, 'false', qq(Changed check ui access $PEtype) );
    
    @deps = $mnf->get_dependencies;
    is(scalar(@deps), 0, qq(Changed check dependencies $PEtype) );
    
    $mnf->set_execution_level('none');
    $mnf->set_dpiaware('false');
    $mnf->set_assembly_description('Some Descriptive String For Application');
    $exe->set_manifest($mnf);
    $exe->write;
    undef $exe;
    
    $exe = Win32::Exe->new($extendedexe);
    isa_ok($exe, 'Win32::Exe', 'AFTER DPIWARE');
    
    ok($exe->has_manifest, qq($PEtype has manifest after dpiaware));
    $mnf = $exe->get_manifest;
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest after dpiaware $PEtype));
    
    is( $mnf->get_resource_id, 1, qq(dpiaware check resource id $PEtype) );
    is( $mnf->get_execution_level, 'none', qq(dpiaware check execution level $PEtype) );
    is( $mnf->get_uiaccess, undef, qq(dpiaware check ui access $PEtype) );
    is( $mnf->get_dpiaware, 'false', qq(dpiaware check dpiaware $PEtype) );
    is( $mnf->get_assembly_description, 'Some Descriptive String For Application', qq(dpiaware check description $PEtype) );
    
    my $mrsrc = $exe->manifest;
    ok($mrsrc, qq($PEtype got manifest resource));
    my $mtext = $mrsrc->get_manifest;
    
    ok( ($mtext !~/trustInfo/), qq($PEtype no trustInfo));
    ok( ($mtext =~/asmv3:application/), qq($PEtype application namespace));
    ok( ($mtext =~/asmv3:windowsSettings/), qq($PEtype windowsSettings namespace));
    
    #---
    $exe->set_manifest_args(['ExecutionLevel=asInvoker;ExecName=A.New.Name;Description=A New Name;Version=100.200.300.400;CommonControls=1']);
    $exe->write;
    undef $exe;

    $exe = Win32::Exe->new($extendedexe);
    isa_ok($exe, 'Win32::Exe', 'Starting manifest args check');
    ok($exe->has_manifest, qq($PEtype has manifest after margs));
    $mrsrc = $exe->manifest;
    ok($mrsrc, qq($PEtype got manifest resource));
    $mtext = $mrsrc->get_manifest;
    $mnf = $exe->get_manifest;
    isa_ok($mnf, 'Win32::Exe::Manifest', qq(ISA Win32::Exe::Manifest after margs $PEtype));
    is( $mnf->get_execution_level, 'asInvoker', qq(margs check execution level $PEtype) );
    is( $mnf->get_uiaccess, 'false', qq(margs check ui access $PEtype) );
    is( $mnf->get_assembly_description, 'A New Name', qq(margs check description $PEtype) );
    is( $mnf->get_assembly_name, 'A.New.Name', qq(margs check description $PEtype) );
    is( $mnf->get_assembly_version, '100.200.300.400', qq(margs check description $PEtype) );
    
    ok( ($mtext =~ /6595b64144ccf1df/), qq($PEtype has common controls));
    
    SKIP: {
        skip qq(Cannot Execute $PEtype bit Windows application on this architecture), 1 if !$cansafelyexecute;
        like( qx($extendedexe 2>&1), qr/^Win32::Exe Test Executable$/, qq(Execute $PEtype bit executable) );
    }

    unlink($extendedexe);
}

1;
