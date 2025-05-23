#!perl
# This file was automatically generated by Dist::Zilla::Plugin::Test::Pod::Coverage::Configurable 0.07.

use Test::Pod::Coverage 1.08;
use Test::More 0.88;

BEGIN {
    if ( $] <= 5.008008 ) {
        plan skip_all => 'These tests require Pod::Coverage::TrustPod, which only works with Perl 5.8.9+';
    }
}
use Pod::Coverage::TrustPod;

my %skip = map { $_ => 1 } qw( URI::IRI URI::_foreign URI::_idna URI::_login URI::_ldap URI::file::QNX URI::ftpes URI::ftps URI::irc URI::nntp URI::urn::isbn URI::urn::oid URI::scp URI::sftp );

my @modules;
for my $module ( all_modules() ) {
    next if $skip{$module};

    push @modules, $module;
}

plan skip_all => 'All the modules we found were excluded from POD coverage test.'
    unless @modules;

plan tests => scalar @modules;

my %trustme = (
             'URI' => [
                        qr/^(?:STORABLE_freeze|STORABLE_thaw|TO_JSON|implementor)$/
                      ],
             'URI::Escape' => [
                                qr/^(?:escape_char)$/
                              ],
             'URI::Heuristic' => [
                                   qr/^(?:MY_COUNTRY|uf_url|uf_urlstr)$/
                                 ],
             'URI::URL' => [
                             qr/^(?:address|article|crack|dos_path|encoded822addr|eparams|epath|frag)$/,
                             qr/^(?:full_path|groupart|keywords|local_path|mac_path|netloc|newlocal|params|path|path_components|print_on|query|strict|unix_path|url|vms_path)$/
                           ],
             'URI::WithBase' => [
                                  qr/^(?:can|clone|eq|new_abs)$/
                                ],
             'URI::_query' => [
                                qr/^(?:equery|query|query_form|query_form_hash|query_keywords|query_param|query_param_append|query_param_delete)$/
                              ],
             'URI::_segment' => [
                                  qr/^(?:new)$/
                                ],
             'URI::_userpass' => [
                                   qr/^(?:password|user)$/
                                 ],
             'URI::file' => [
                              qr/^(?:os_class)$/
                            ],
             'URI::file::Base' => [
                                    qr/^(?:dir|file|new)$/
                                  ],
             'URI::file::FAT' => [
                                   qr/^(?:fix_path)$/
                                 ],
             'URI::file::Mac' => [
                                   qr/^(?:dir|file)$/
                                 ],
             'URI::file::OS2' => [
                                   qr/^(?:file)$/
                                 ],
             'URI::file::Unix' => [
                                    qr/^(?:file)$/
                                  ],
             'URI::file::Win32' => [
                                     qr/^(?:file|fix_path)$/
                                   ],
             'URI::ftp' => [
                             qr/^(?:password|user|encrypt_mode)$/
                           ],
             'URI::gopher' => [
                                qr/^(?:gopher_type|gtype|search|selector|string)$/
                              ],
             'URI::ldapi' => [
                               qr/^(?:un_path)$/
                             ],
             'URI::mailto' => [
                                qr/^(?:headers|to)$/
                              ],
             'URI::news' => [
                              qr/^(?:group|message)$/
                            ],
             'URI::pop' => [
                             qr/^(?:auth|user)$/
                           ],
             'URI::sip' => [
                             qr/^(?:params|params_form)$/
                           ],
             'URI::urn' => [
                             qr/^(?:nid|nss)$/
                           ]
           );

my @also_private;

for my $module ( sort @modules ) {
    pod_coverage_ok(
        $module,
        {
            coverage_class => 'Pod::Coverage::TrustPod',
            also_private   => \@also_private,
            trustme        => $trustme{$module} || [],
        },
        "pod coverage for $module"
    );
}

done_testing();
