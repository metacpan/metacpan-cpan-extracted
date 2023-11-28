use strict;
use warnings;
use Test::More;
use CPAN::Meta ();
use ExtUtils::Manifest 'maniread';
use lib 'blib/lib';
require 'UUID.pm';

if ( -e '.git' ) {
    plan skip_all => 'in repo';
}
elsif ( $ENV{UUID_DISTTEST} ) {
    plan tests => 19;
}
else {
    plan skip_all => 'in release';
}

ok -e 'LICENSE',   'LICENSE exists';
ok -e 'META.json', 'META.json exists';
ok -e 'META.yml',  'META.yml exists';
ok -e 'README',    'README exists';

ok -s 'LICENSE',   'LICENSE not empty';
ok -s 'META.json', 'META.json not empty';
ok -s 'META.yml',  'META.yml not empty';
ok -s 'README',    'README not empty';

my $manifest = maniread;
ok exists($manifest->{'LICENSE'}),   'LICENSE in manifest';
ok exists($manifest->{'META.json'}), 'META.json in manifest';
ok exists($manifest->{'META.yml'}),  'META.yml in manifest';
ok exists($manifest->{'README'}),    'README in manifest';


ok test_dynamic('META.json'), 'META.json authoritative';
ok test_dynamic('META.yml'),  'META.yml authoritative';

sub test_dynamic {
    my $f = shift;
    open my $fh, '<', $f or die "open: $!";
    while (<$fh>) {
        return 1 if m/dynamic_config.*?0/;
    }
    return 0;
}


ok test_copyright('LICENSE'), 'LICENSE copyright date valid';
ok test_copyright('README'),  'README copyright date valid';
ok test_copyright('UUID.pm'), 'UUID.pm copyright date valid';

sub test_copyright {
    my $f = shift;
    my $n = 1900 + (localtime(time))[5];
    open my $fh, '<', $f or die 'open: ', $f, ': ', $!;
    while (<$fh>) {
        if (/2014-(\d+)/) {
            my $end = $1;
            return 1 if $end == $n;
        }
    }
    return 0;
}


is provided_version('META.json'), $UUID::VERSION, 'META.json version';
is provided_version('META.yml'),  $UUID::VERSION, 'META.yml version';

sub provided_version {
    my $f = shift;
    my $m = CPAN::Meta->load_file($f);
    return $m->{'provides'}{'UUID'}{'version'};
}

exit 0;

