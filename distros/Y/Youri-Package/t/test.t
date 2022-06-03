#!/usr/bin/perl
# $Id$

use strict;

use File::Basename;
use File::Copy;
use File::Temp qw/tempdir/;
use File::Which;
use Test::More;
use Test::Exception;
use UNIVERSAL::require;

use Youri::Package::RPM::Generator;

# expected results
my $requires = [
    [ 'perl-base', undef ], 
    [ 'perl(Cwd)', undef ],
    [ 'perl(File::Basename)', undef ],
    [ 'perl(Getopt::Std)', undef ],
    [ 'perl(Text::Tabs)', undef ],
    [ 'perl(Text::Wrap)', undef ]
];

my $provides = [
    [ 'cowsay', '== 3.03-11mdv2007.0' ]
];

my $obsoletes = [];
my $conflicts = [];

my $files = [
    [
        '/etc/bash_completion.d/cowsay',
        33188,
        '6048be1dd827011c15cab0c3db1f438d'
    ],
    [
        '/usr/bin/cowsay',
        33261,
        'b405026c6040eeb4781ca5c523129fe4'
    ],
    [
        '/usr/bin/cowthink',
        41471,
        ''
    ],
    [
        '/usr/share/cows',
        16877,
        ''
    ],
    [
        '/usr/share/cows/beavis.zen.cow',
        33188,
        '582b2ddb72122d3aa078730abd0456b3'
    ],
    [
        '/usr/share/cows/bong.cow',
        33188,
        '045f9bf39c027dded9a7145f619bac02'
    ],
    [
        '/usr/share/cows/bud-frogs.cow',
        33188,
        '5c61632eb06305d613061882e1955cd2'
    ],
    [
        '/usr/share/cows/bunny.cow',
        33188,
        '05eb914d3b96aea903542cb29f5c42c7'
    ],
    [
        '/usr/share/cows/cheese.cow',
        33188,
        'f3618110a22d8e9ecde888c1f5e38b61'
    ],
    [
        '/usr/share/cows/cower.cow',
        33188,
        'd73ea60eec692555a34a9f3eec981578'
    ],
    [
        '/usr/share/cows/daemon.cow',
        33188,
        'a7dd7588ee0386a0f29e88e4881885ee'
    ],
    [
        '/usr/share/cows/default.cow',
        33188,
        'f1206515a0f27e9d5cf09c188e46bc82'
    ],
    [
        '/usr/share/cows/dragon-and-cow.cow',
        33188,
        '0ca99b8edd1a9d14fd231a88d9746b39'
    ],
    [
        '/usr/share/cows/dragon.cow',
        33188,
        '448f736bf56dccafa2635e71e7485345'
    ],
    [
        '/usr/share/cows/duck.cow',
        33188,
        'd8ffcd64667d2e3697a3e8b65e8bea9d'
    ],
    [
        '/usr/share/cows/elephant-in-snake.cow',
        33188,
        'c5a9f406277e0e8a674bd3ffb503738f'
    ],
    [
        '/usr/share/cows/elephant.cow',
        33188,
        'e355c72e893787376c047805d4a1fe9d'
    ],
    [
        '/usr/share/cows/eyes.cow',
        33188,
        'b2eb5b612fae17877895aa6edafa0a5f'
    ],
    [
        '/usr/share/cows/flaming-sheep.cow',
        33188,
        '3213cfa04a069f42d71115ca623a2f95'
    ],
    [
        '/usr/share/cows/ghostbusters.cow',
        33188,
        'df294e6278bcb275aecb0fbd6b2546ba'
    ],
    [
        '/usr/share/cows/girafe.cow',
        33188,
        '6d2e142313109b6a5a0a45dba0f11351'
    ],
    [
        '/usr/share/cows/head-in.cow',
        33188,
        '365287a5d1f34a53f8716285e79c28df'
    ],
    [
        '/usr/share/cows/hellokitty.cow',
        33188,
        'e0bbea69c4cbcfb3d799740ccc8a0b0e'
    ],
    [
        '/usr/share/cows/kenny.cow',
        33188,
        '16ce8c334a7547197ac4c9e8a1d6ae90'
    ],
    [
        '/usr/share/cows/kiss.cow',
        33188,
        '2a7bdd4a20741b7769af463bf09e64e8'
    ],
    [
        '/usr/share/cows/kitty.cow',
        33188,
        '76d65a3ebfbacb16a654c1aa1af6ed27'
    ],
    [
        '/usr/share/cows/koala.cow',
        33188,
        'cc524706707f32253dd06fc548334f11'
    ],
    [
        '/usr/share/cows/kosh.cow',
        33188,
        'e4e28e0f472bd524fd1b44c67ae357c2'
    ],
    [
        '/usr/share/cows/luke-koala.cow',
        33188,
        '63bbc35da73cd22b8cf25f86dcf9f870'
    ],
    [
        '/usr/share/cows/mech-and-cow',
        33188,
        '12c0320b33704d8564dd97278d056204'
    ],
    [
        '/usr/share/cows/meow.cow',
        33188,
        'a6092008647ed37cfe1663d10e388cbb'
    ],
    [
        '/usr/share/cows/milk.cow',
        33188,
        'd26ac36e13e77dabb408e104fc8e0167'
    ],
    [
        '/usr/share/cows/moofasa.cow',
        33188,
        '5fcdd4a9f3bf521c337af0a066b14512'
    ],
    [
        '/usr/share/cows/moose.cow',
        33188,
        'dcfa09df7d2b9afa112dab374bf06e99'
    ],
    [
        '/usr/share/cows/mutilated.cow',
        33188,
        '24cdaef0a29fb44dc673abf19a8ba631'
    ],
    [
        '/usr/share/cows/phaco.cow',
        33188,
        'f277c1bf92ce2a3f6058955ba93758aa'
    ],
    [
        '/usr/share/cows/pumpkin.cow',
        33188,
        'c661ea78714c1ce31559f77d73694473'
    ],
    [
        '/usr/share/cows/ren.cow',
        33188,
        '3d7941d454779e000adc1c91e5f0b20b'
    ],
    [
        '/usr/share/cows/satanic.cow',
        33188,
        'a69ca42a31486757ddcb322a1e68f886'
    ],
    [
        '/usr/share/cows/shark.cow',
        33188,
        'd8950ec63abb00bbd9d96ec63637c1ac'
    ],
    [
        '/usr/share/cows/sheep.cow',
        33188,
        '543b75f295cbd51326f5a40f111469f1'
    ],
    [
        '/usr/share/cows/skeleton.cow',
        33188,
        '64f6ec1a0c170508e72269d533492e57'
    ],
    [
        '/usr/share/cows/small.cow',
        33188,
        '50cb1c55628c439fc81f96db9d855252'
    ],
    [
        '/usr/share/cows/sodomized.cow',
        33188,
        'b4888afcca51629cc3138b283608b837'
    ],
    [
        '/usr/share/cows/stegosaurus.cow',
        33188,
        'fb0e45d101a3ecba9cf6e112facbbc7e'
    ],
    [
        '/usr/share/cows/stimpy.cow',
        33188,
        '9b4ec6e0750ba0eeaaa432d8d3413559'
    ],
    [
        '/usr/share/cows/supermilker.cow',
        33188,
        '316573fb585e4a6b375373c85be025b1'
    ],
    [
        '/usr/share/cows/surgery.cow',
        33188,
        '7f25005083c1fde19d4e548c005ef000'
    ],
    [
        '/usr/share/cows/telebears.cow',
        33188,
        '15f00abb070d9018ce6ef3441e936ef4'
    ],
    [
        '/usr/share/cows/three-eyes.cow',
        33188,
        'c85faef9496f4a5b111bd92bfd7e7528'
    ],
    [
        '/usr/share/cows/turkey.cow',
        33188,
        '484b5bc69c09d420d7fd5586d8570f04'
    ],
    [
        '/usr/share/cows/turtle.cow',
        33188,
        '87eed5a00e88860b78dbec04efcdede3'
    ],
    [
        '/usr/share/cows/tux.cow',
        33188,
        'dc1db4eac66c99179ef6adb15dd75bda'
    ],
    [
        '/usr/share/cows/udder.cow',
        33188,
        'd97f78887c3b218a54876edc51f2963b'
    ],
    [
        '/usr/share/cows/vader-koala.cow',
        33188,
        '7b5dd51278f0fa217a70a9b499f97a07'
    ],
    [
        '/usr/share/cows/vader.cow',
        33188,
        '97b4ef9fc4c26082f253e9f0f35c4590'
    ],
    [
        '/usr/share/cows/www.cow',
        33188,
        'ef4c0bc8330f329666e1705f97f283cc'
    ],
    [
        '/usr/share/doc/cowsay-3.03',
        16877,
        ''
    ],
    [
        '/usr/share/doc/cowsay-3.03/INSTALL',
        33188,
        '3333fd2865107626d5dffc0dbfb7e244'
    ],
    [
        '/usr/share/doc/cowsay-3.03/LICENSE',
        33188,
        'f879dda90a5a9928253a63ecd76406e6'
    ],
    [
        '/usr/share/doc/cowsay-3.03/README',
        33188,
        'a5c1c61e4920c278a735cdaaca62453e'
    ],
    [
        '/usr/share/man/man1/cowsay.1.bz2',
        33188,
        '01fdd49d0b477f20099aae384fe8c1b2'
    ],
    [
        '/usr/share/man/man1/cowthink.1.bz2',
        41471,
        ''
    ]
];

my $changes = [
    [
        'Guillaume Rousse <guillomovitch@mandriva.org> 3.03-11mdv2007.0',
        1149847200,
        "- %mkrel\n- rpmbuildupdate aware"
    ]
];

my $last_change_author     =
    'Guillaume Rousse <guillomovitch@mandriva.org> 3.03-11mdv2007.0';
my $last_change_time       = 1149847200;
my $last_change_raw_text   = "- %mkrel\n- rpmbuildupdate aware",
my $last_change_text_items = [
    '%mkrel',
    'rpmbuildupdate aware'
];

my @classes = qw/
    Youri::Package::RPM::URPM
    Youri::Package::RPM::Test
/;
push @classes, 'Youri::Package::RPM::RPM4' if RPM4->require();
push @classes, 'Youri::Package::RPM::RPM' if RPM->require();

my $dir      = dirname($0);
my $rpm      = 'cowsay-3.03-11mdv2007.0.noarch.rpm';
my ($old_rpm)  = Youri::Package::RPM::Generator->new(tags => {
    name      => 'cowsay',
    version   => '3.03',
    release   => '10mdv2007.0',
    buildarch => 'noarch'
})->get_binaries();
my ($new_rpm)  = Youri::Package::RPM::Generator->new(tags => {
    name      => 'cowsay',
    version   => '3.03',
    release   => '12mdv2007.0',
    buildarch => 'noarch'
})->get_binaries();
my $fake_rpm = 'foobar.rpm';
plan(tests => 49 * scalar @classes);

foreach my $class (@classes) {
    $class->require();

    my $temp_dir  = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
    my $file      = "$dir/$rpm";
    my $old_file  = "$old_rpm";
    my $new_file  = "$new_rpm";
    my $fake_file = "$temp_dir/$fake_rpm";

    # instanciation errors
    dies_ok { $class->new(file => undef) } 'undefined file';
    dies_ok { $class->new(file => $fake_file) } 'non-existant file';
    system('touch', $fake_file);
    chmod 0000, $fake_file;
    dies_ok { $class->new(file => $fake_file) } 'non-readable file';
    chmod 0644, $fake_file;
    dies_ok { $class->new(file => $fake_file) } 'non-rpm file';

    my $package;
    if ($class eq 'Youri::Package::RPM::Test') {
        # this one need a little help
        $package = $class->new(
            file => $file,
            tags => {
                summary  => 'Configurable talking cow',
                url      => 'http://www.nog.net/~tony/warez/cowsay.shtml',
                packager => 'Guillaume Rousse <guillomovitch@mandriva.org>',
                gpg_key  => '26752624',
            },
            requires  => $requires,
            provides  => $provides,
            obsoletes => $obsoletes,
            conflicts => $conflicts,
            files     => $files,
            changes   => [[
                'Guillaume Rousse <guillomovitch@mandriva.org> 3.03-11mdv2007.0',
                1149847200,
                "- %mkrel\n- rpmbuildupdate aware"
            ]]
        );
    } else {
        $package = $class->new(file => $file);
    }
    isa_ok($package, $class);

    # tag value access
    is($package->get_name(), 'cowsay', 'get name directly');
    is($package->get_tag('name'), 'cowsay', 'get name indirectly');
    is($package->get_version(), '3.03', 'get version directly');
    is($package->get_tag('version'), '3.03', 'get version indirectly');
    is($package->get_release(), '11mdv2007.0', 'get release directly');
    is($package->get_tag('release'), '11mdv2007.0', 'get release indirectly');
    is($package->get_arch(), 'noarch', 'get arch directly');
    is($package->get_tag('arch'), 'noarch', 'get arch indirectly');
    is($package->get_summary(), 'Configurable talking cow', 'get summary directly');
    is($package->get_tag('summary'), 'Configurable talking cow', 'get summary indirectly');
    is($package->get_url(), 'http://www.nog.net/~tony/warez/cowsay.shtml', 'get url directly');
    is($package->get_tag('url'), 'http://www.nog.net/~tony/warez/cowsay.shtml', 'get url indirectly');
    is($package->get_packager(), 'Guillaume Rousse <guillomovitch@mandriva.org>', 'get packager directly');
    is($package->get_tag('packager'), 'Guillaume Rousse <guillomovitch@mandriva.org>', 'get packager indirectly');
    is($package->get_file_name(), 'cowsay-3.03-11mdv2007.0.noarch.rpm', 'file name');
    is($package->get_revision(), '3.03-11mdv2007.0', 'revision');

    # name formating
    is($package->as_formated_string('%{name}-%{version}-%{release}'), 'cowsay-3.03-11mdv2007.0', 'formated string name');
    is($package->as_string(), 'cowsay-3.03-11mdv2007.0.noarch', 'default string');
    is($package, 'cowsay-3.03-11mdv2007.0.noarch', 'stringification');

    # type
    ok(!$package->is_source(), 'not a source package');
    ok($package->is_binary(), 'a binary package');
    is($package->get_type(), 'binary', 'a binary package');

    # gpg key
    is($package->get_gpg_key(), '26752624', 'get gpg key');

    # dependencies
    is_deeply(
        [ $package->get_requires() ],
        $requires,
        'requires'
    );
    is_deeply(
        [ $package->get_provides() ],
        $provides,
        'provides'
    );
    is_deeply(
        [ $package->get_obsoletes() ],
        $obsoletes,
        'obsoletes'
    );
    is_deeply(
        [ $package->get_conflicts() ],
        $conflicts,
        'conflicts'
    );

    # files
    is_deeply(
        [ $package->get_files() ],
        $files,
        'files'
    );

    # changelog
    is(
        $package->get_last_change()->get_author(),
        $last_change_author,
        'last change has expected author'
    );
    is(
        $package->get_last_change()->get_time(),
        $last_change_time,
        'last change has expected date'
    );
    is(
        $package->get_last_change()->get_raw_text(),
        $last_change_raw_text,
        'last change has expected raw text'
    );
    is_deeply(
        [ $package->get_last_change()->get_text_items() ],
        $last_change_text_items,
        'last change has expected text items'
    );

    # comparison tests
    my $old_package = $class->new(file => $old_file);
    my $new_package = $class->new(file => $new_file);
    is($package->compare($package), 0, 'comparison with self');
    is($package->compare($old_package), 1, 'comparison with older');
    is($package->compare($new_package), -1, 'comparison with newer');

    dies_ok {
            $package->compare('foobar');
        } 'comparison with something else as a package';

    ok($package->satisfy_range('>= 3.03-11mdv2007.0'), 'range test');
    ok($package->satisfy_range('<= 3.03-11mdv2007.0'), 'range test');
    ok($package->satisfy_range('== 3.03-11mdv2007.0'), 'range test');
    ok($package->satisfy_range('> 3.03-10mdv2007.0'), 'range test');
    ok($package->satisfy_range('< 3.03-12mdv2007.0'), 'range test');

    SKIP: {
        skip "not implemented yet", 3
            if $class eq 'Youri::Package::RPM::Test';
        skip "rpm4 has no error control for signature", 3
            if $class eq 'Youri::Package::RPM::RPM4';
        skip "rpm has no error control for signature", 3
            if $class eq 'Youri::Package::RPM::RPM';
        skip "rpmsign not available", 3
            if ! which("rpmsign");

        # signature test
        copy($file, $temp_dir);
        $package = $class->new(file => "$temp_dir/$rpm");

        throws_ok {
            $package->sign('Youri', "$dir/gpghome", 'Youri sux')
        } qr/^Signature error:/, 'signing with wrong key';

        lives_ok {
            $package->sign('Youri', "$dir/gpghome", 'Youri rulez')
        } 'signing with correct key';

        $package = $class->new(file => "$temp_dir/$rpm");
        is($package->get_gpg_key(), '2333e817', 'get gpg key');
    }
}
