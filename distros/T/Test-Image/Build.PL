
use lib 'mbk';
use Module::Build::Kwalitee;

my $build = Module::Build::Kwalitee->new(

    # the name of the module we're dealing with
    module_name => 'Test::Image',

    # things we require
    requires => {
    'perl' => 5.008,
      "Test::Builder" => "0.32",  # Maybe earlier version works, who knows?
      "Image::Imlib2" => 0,
    },
    
    # things our build requires
    build_requires => {
       "Test::More" => 0.47,  # wot's installed on my laptop
       "Test::Builder::Tester" => "1.02",  # Maybe eariler version works, who knows?
    },

    # It'd be nice if this was installed too
    recommends => {
       "Number::Compare" => "0.01",
       "Graphics::ColorNames" => "1.06",
       "Module::Pluggable" => "3.01",
    },

    # scripts that we want the shebang line munged and installed
    script_files => [qw(
    )],

    # files that we should delete when we cleanup
    add_to_cleanup => [qw(
    )],

    ##### Probably Don't Want To Change Things Below Here #####

    # we're copyrighted how?
    license => "perl",
    
    # create the readme for me please
    create_readme => 1,

    # recursive test files on!
    recursive_test_files => 1,
    
    # I wrote this!
    dist_author => 'Mark Fowler <mark@twoshortplanks.com>',
    
    # build a compatible Makefile.PL
    create_makefile_pl => "traditional",

);

$build->create_build_script();