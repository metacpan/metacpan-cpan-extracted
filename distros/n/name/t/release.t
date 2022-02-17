use strict;
use warnings;
use Test::Fatal;
use Test::More;

BEGIN {
    plan skip_all => 'Author tests not required for installation' unless $ENV{RELEASE_TESTING};

    eval "use File::Basename 'dirname'";
    plan skip_all => 'File::Basename must be installed for release testing' if $@;

    eval "use File::Spec::Functions qw(catdir updir)";
    plan skip_all => 'File::Spec::Functions must be installed for release testing' if $@;

    eval "use version 0.77";
    plan skip_all => 'version 0.77 must be installed for release testing' if $@;
}

require name;

my $version;

subtest 'version format' => sub {
    ok !exception { $version = version->parse($name::VERSION) }, 'name has a VERSION';
    ok $version->is_strict, 'name VERSION is strict';
};

subtest 'POD version' => sub {
    my ($v) = file_content('lib/name.pm') =~ /=head1 \s+ VERSION .+? \b(v\d+\.\d+\.\d+)\b/sx;

    ok defined($v), 'POD documents VERSION';
    is $v, $version, 'right POD VERSION';
};

subtest 'Changes' => sub {
    my ($changes, $previous_version, $previous_date);

    ok !exception { $changes = file_content('Changes') }, 'Changes file exists';

    $changes =~ s/\A#?\s*Revision\s+history.+?$//ims;

    my @match = $changes =~ /^(\S+)\s+(\S+)$/gms;

    while (my ($v, $date) = splice @match, 0, 2) {
        my ($parsed_version, $parsed_date);

        ok !exception { $parsed_version = version->parse($v) }, 'right version format'
            or next;

        ok $parsed_version->is_strict, 'version is strict';

        if ($previous_version) {
            cmp_ok $parsed_version, '<', $previous_version, 'descending version number order';
        }
        else {
            is $v, $version, 'top most version equals package version';
        }

        like $date, qr/^\d{4}-\d{2}-\d{2}$/, 'right date format';

        if ($previous_date) {
            cmp_ok $date, 'le', $previous_date, 'descending release date order';
        }
        else {
            my $today = sub { sprintf '%04d-%02d-%02d', $_[5] + 1900, $_[4] + 1, $_[3] }->(gmtime);

            cmp_ok $date, 'le', $today, 'top most date not in future';
        }

        $previous_version = $parsed_version;
        $previous_date    = $date;
    }
};

done_testing;

sub file_content {
    my $filename = catdir(dirname(__FILE__), updir, shift);

    open my $f, $filename or die "failed to open $filename: $!\n";

    local $/;

    return <$f>;
}
