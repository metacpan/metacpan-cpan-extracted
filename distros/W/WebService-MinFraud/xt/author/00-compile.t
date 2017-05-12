use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 38;

my @module_files = (
    'WebService/MinFraud.pm',
    'WebService/MinFraud/Client.pm',
    'WebService/MinFraud/Data/Rx/Type/CCToken.pm',
    'WebService/MinFraud/Data/Rx/Type/DateTime/RFC3339.pm',
    'WebService/MinFraud/Data/Rx/Type/Enum.pm',
    'WebService/MinFraud/Data/Rx/Type/Hex32.pm',
    'WebService/MinFraud/Data/Rx/Type/Hostname.pm',
    'WebService/MinFraud/Data/Rx/Type/IPAddress.pm',
    'WebService/MinFraud/Data/Rx/Type/WebURI.pm',
    'WebService/MinFraud/Error/Generic.pm',
    'WebService/MinFraud/Error/HTTP.pm',
    'WebService/MinFraud/Error/WebService.pm',
    'WebService/MinFraud/Model/Factors.pm',
    'WebService/MinFraud/Model/Insights.pm',
    'WebService/MinFraud/Model/Score.pm',
    'WebService/MinFraud/Record/BillingAddress.pm',
    'WebService/MinFraud/Record/Country.pm',
    'WebService/MinFraud/Record/CreditCard.pm',
    'WebService/MinFraud/Record/Device.pm',
    'WebService/MinFraud/Record/Disposition.pm',
    'WebService/MinFraud/Record/Email.pm',
    'WebService/MinFraud/Record/IPAddress.pm',
    'WebService/MinFraud/Record/Issuer.pm',
    'WebService/MinFraud/Record/Location.pm',
    'WebService/MinFraud/Record/ScoreIPAddress.pm',
    'WebService/MinFraud/Record/ShippingAddress.pm',
    'WebService/MinFraud/Record/Subscores.pm',
    'WebService/MinFraud/Record/Warning.pm',
    'WebService/MinFraud/Role/Data/Rx/Type.pm',
    'WebService/MinFraud/Role/Error/HTTP.pm',
    'WebService/MinFraud/Role/HasCommonAttributes.pm',
    'WebService/MinFraud/Role/HasLocales.pm',
    'WebService/MinFraud/Role/Model.pm',
    'WebService/MinFraud/Role/Record/Address.pm',
    'WebService/MinFraud/Role/Record/HasRisk.pm',
    'WebService/MinFraud/Types.pm',
    'WebService/MinFraud/Validator.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
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


