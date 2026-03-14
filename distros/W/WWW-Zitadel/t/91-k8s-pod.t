use strict;
use warnings;

use Test::More;
use JSON::MaybeXS qw(decode_json);

BEGIN {
    plan skip_all => 'Set ZITADEL_K8S_TEST=1 to run Kubernetes pod test'
        unless $ENV{ZITADEL_K8S_TEST};
}

my $issuer = $ENV{ZITADEL_ISSUER}
    or plan skip_all => 'Set ZITADEL_ISSUER for Kubernetes pod test';

my $kubeconfig = $ENV{ZITADEL_KUBECONFIG} // '/storage/raid/home/getty/avatar/.kube/config';
my $namespace  = $ENV{ZITADEL_K8S_NAMESPACE} // 'default';
my $context    = $ENV{ZITADEL_K8S_CONTEXT};

ok -f $kubeconfig, "kubeconfig exists at $kubeconfig";

my $pod = sprintf('zitadel-live-test-%d-%d', time, int(rand(1000000)));
my $deleted;

sub _sh_quote {
    my ($s) = @_;
    $s =~ s/'/'"'"'/g;
    return "'$s'";
}

sub _run_cmd {
    my (@args) = @_;
    my $cmd = join ' ', map { _sh_quote($_) } @args;
    my $out = qx{$cmd 2>&1};
    my $exit = $? >> 8;
    return ($exit, $out);
}

sub _kubectl_cmd {
    my (@args) = @_;
    my @base = ('kubectl', '--kubeconfig', $kubeconfig, '-n', $namespace);
    push @base, ('--context', $context) if defined $context && length $context;
    return _run_cmd(@base, @args);
}

END {
    return if $deleted;
    _kubectl_cmd('delete', 'pod', $pod, '--ignore-not-found=true', '--wait=false');
}

my ($rc1, $out1) = _kubectl_cmd(
    'run',
    $pod,
    '--image=curlimages/curl:8.6.0',
    '--restart=Never',
    '--command',
    '--',
    'sleep',
    '300',
);
is $rc1, 0, "kubectl run pod succeeded: $out1";

my ($rc2, $out2) = _kubectl_cmd(
    'wait',
    '--for=condition=Ready',
    "pod/$pod",
    '--timeout=120s',
);
is $rc2, 0, "pod became ready: $out2";

my ($rc3, $out3) = _kubectl_cmd(
    'exec',
    $pod,
    '--',
    'curl',
    '-fsS',
    "$issuer/.well-known/openid-configuration",
);
is $rc3, 0, "pod can fetch discovery endpoint: $out3";

my $discovery = eval { decode_json($out3) };
ok !$@, 'discovery response is valid JSON';
ok ref($discovery) eq 'HASH', 'discovery payload is a hashref';
ok $discovery->{jwks_uri}, 'discovery payload contains jwks_uri';

my ($rc4, $out4) = _kubectl_cmd('delete', 'pod', $pod, '--wait=true');
is $rc4, 0, "pod cleanup succeeded: $out4";
$deleted = 1;

done_testing;
