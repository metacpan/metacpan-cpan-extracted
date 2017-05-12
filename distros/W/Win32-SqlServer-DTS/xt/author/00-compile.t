use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 31;

my @module_files = (
    'Win32/SqlServer/DTS.pm',
    'Win32/SqlServer/DTS/Application.pm',
    'Win32/SqlServer/DTS/Assignment.pm',
    'Win32/SqlServer/DTS/Assignment/Constant.pm',
    'Win32/SqlServer/DTS/Assignment/DataFile.pm',
    'Win32/SqlServer/DTS/Assignment/Destination.pm',
    'Win32/SqlServer/DTS/Assignment/Destination/Connection.pm',
    'Win32/SqlServer/DTS/Assignment/Destination/GlobalVar.pm',
    'Win32/SqlServer/DTS/Assignment/Destination/Package.pm',
    'Win32/SqlServer/DTS/Assignment/Destination/Task.pm',
    'Win32/SqlServer/DTS/Assignment/DestinationFactory.pm',
    'Win32/SqlServer/DTS/Assignment/EnvVar.pm',
    'Win32/SqlServer/DTS/Assignment/GlobalVar.pm',
    'Win32/SqlServer/DTS/Assignment/INI.pm',
    'Win32/SqlServer/DTS/Assignment/Query.pm',
    'Win32/SqlServer/DTS/AssignmentFactory.pm',
    'Win32/SqlServer/DTS/AssignmentTypes.pm',
    'Win32/SqlServer/DTS/Connection.pm',
    'Win32/SqlServer/DTS/Credential.pm',
    'Win32/SqlServer/DTS/DateTime.pm',
    'Win32/SqlServer/DTS/Package.pm',
    'Win32/SqlServer/DTS/Package/Step.pm',
    'Win32/SqlServer/DTS/Package/Step/Result.pm',
    'Win32/SqlServer/DTS/Task.pm',
    'Win32/SqlServer/DTS/Task/DataPump.pm',
    'Win32/SqlServer/DTS/Task/DynamicProperty.pm',
    'Win32/SqlServer/DTS/Task/ExecutePackage.pm',
    'Win32/SqlServer/DTS/Task/SendEmail.pm',
    'Win32/SqlServer/DTS/TaskFactory.pm',
    'Win32/SqlServer/DTS/TaskTypes.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


