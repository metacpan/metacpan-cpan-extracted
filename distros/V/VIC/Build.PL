use strict;
use warnings;
use Module::Build;

my %pl_files = ();
%pl_files = ( PL_files => { 'share/rebuild-grammar.PL' => [] } ) if $ENV{DEVELOPER};
my $build = Module::Build->new(
    module_name => 'VIC',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'VIC is a high level syntax to generate PIC microcontroller assembly',
    dist_version_from => 'lib/VIC.pm',
    create_readme => 0,
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Test::More' => 0,
        'File::Spec' => 0,
        'File::Which' => 0,
        'Pegex' => 0.75, # needed for PL_files to work
        'Test::Lib' => 0,
        'B::Hooks::EndOfScope' => 0,
    },
    requires => {
        'perl' => 'v5.10.0',
        'Getopt::Long' => 0,
        'Capture::Tiny' => 0,
        'File::Spec' => 0,
        'File::Which' => 0,
        'Pegex' => 0.75, # needed for PL_files to work
        'List::Util' => 0,
        'List::MoreUtils' => 0,
        'Moo' => '1.003',
        'namespace::clean' => 0,
    },
    recommends => {
        'XXX' => 0,
        'App::Prove' => 0,
        'Alien::gputils' => 0.08,
    },
    script_files => ['script/vic'],
    share_dir => 'share',
    dynamic_config => 1,
    add_to_cleanup => [ qw/*.bak/ ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/selectiveintellect/vic',
            bugtracker => 'https://github.com/selectiveintellect/vic/issues',
            x_IRC => 'irc://irc.freenode.net/#vic',
            x_Twitter => 'https://twitter.com/_vicash_',
        },
        keywords => [qw/VIC PIC assembly/],
        no_index => {
            directory => [qw{t share}],
        },
    },
    %pl_files,
);

$build->create_build_script;
$build->dispatch('clean');
$build->dispatch('distmeta');
$build->dispatch('manifest');

__END__
#### COPYRIGHT: 2014. Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 5th Feb 2014
#### LICENSE: Refer LICENSE file.
