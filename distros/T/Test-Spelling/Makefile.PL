use inc::Module::Install;
use Module::Install::GithubMeta;
use Module::Install::ManifestSkip;
use Module::Install::AutoManifest;

name       'Test-Spelling';
all_from   'lib/Test/Spelling.pm';
githubmeta;

requires 'Pod::Spell' => '1.01';
requires 'IPC::Run3'  => '0.044';
test_requires 'Test::More' => '0.88';
test_requires 'Test::Tester';

manifest_skip;
auto_manifest;
WriteAll;

