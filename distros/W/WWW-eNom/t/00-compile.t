use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.040

use Test::More  tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Net/eNom.pm',
    'WWW/eNom.pm',
    'WWW/eNom/Contact.pm',
    'WWW/eNom/Domain.pm',
    'WWW/eNom/DomainAvailability.pm',
    'WWW/eNom/DomainRequest/Registration.pm',
    'WWW/eNom/DomainRequest/Transfer.pm',
    'WWW/eNom/DomainTransfer.pm',
    'WWW/eNom/IRTPDetail.pm',
    'WWW/eNom/PhoneNumber.pm',
    'WWW/eNom/PrivateNameServer.pm',
    'WWW/eNom/Role/Command.pm',
    'WWW/eNom/Role/Command/Contact.pm',
    'WWW/eNom/Role/Command/Domain.pm',
    'WWW/eNom/Role/Command/Domain/Availability.pm',
    'WWW/eNom/Role/Command/Domain/PrivateNameServer.pm',
    'WWW/eNom/Role/Command/Domain/Registration.pm',
    'WWW/eNom/Role/Command/Domain/Transfer.pm',
    'WWW/eNom/Role/Command/Raw.pm',
    'WWW/eNom/Role/Command/Service.pm',
    'WWW/eNom/Role/ParseDomain.pm',
    'WWW/eNom/Types.pm'
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

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


