use Module::Build;

my $build = Module::Build->new(
    module_name     => 'WWW::Restaurant::Menu',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    requires        => {
        # Core requirements:
        perl                => '5.8',
        Encode              => 0,
        LWP                 => 0
    },
    recommends      => {
        # Filter module requirements:
        #HTML::HeadParser    => 0,
        HTML::TableExtract  => 0,
        HTML::TableExtract::Raw
                            => 0
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();

# $Id: Build.PL,v 1.3 2005/01/15 16:06:47 julian Exp $
# vim:tw=79
