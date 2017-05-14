use Test::More tests => 18;
use Test::Exception;
use warnings;

use X11::Wallpaper qw(set_wallpaper set_wallpaper_command);

# Fake which commands are available
no warnings 'redefine';
my @available;
*{'X11::Wallpaper::which'} = sub {
    for my $cmd (@available) {
        return "/usr/bin/$cmd" if $_[0] eq $cmd;
    }
    return;
};

# Fake system call
my @called;
*{'X11::Wallpaper::systemx'} = sub {
    @called = @_;
};

{
    @available = ('feh');

    is_deeply(
        [set_wallpaper_command('foo.jpg')],
        ['feh', '--bg-scale', 'foo.jpg'],
        'basic',
    );

    is_deeply(
        [set_wallpaper_command('foo.jpg', mode => 'tile')],
        ['feh', '--bg-tile', 'foo.jpg'],
        'tiled',
    );

    is_deeply(
        [set_wallpaper_command('foo.jpg', mode => 'center')],
        ['feh', '--bg-center', 'foo.jpg'],
        'center',
    );

    is_deeply(
        [set_wallpaper_command('foo.jpg', mode => 'aspect')],
        ['feh', '--bg-fill', 'foo.jpg'],
        'aspect',
    );

    is_deeply(
        [set_wallpaper_command('foo.png', display => ':0.0')],
        ['env', 'DISPLAY=:0.0', 'feh', '--bg-scale', 'foo.png'],
        'display arg',
    );

    is_deeply(
        [set_wallpaper_command('foo.png', setter => 'Esetroot')],
        ['Esetroot', '-scale', 'foo.png'],
        'custom setter',
    );

    throws_ok {
        set_wallpaper_command('foo.png', mode => 'blah');
    } qr/No setter program found/, 'invalid mode';
}

{
    @available = ();
    throws_ok {
        set_wallpaper_command('foo.jpg');
    } qr/No setter program found/, 'no setters available';
}

{
    # Prefer modules with better transparency handling
    @available = ('Esetroot', 'xv');
    is_deeply(
        [set_wallpaper_command('bar.jpg')],
        ['Esetroot', '-scale', 'bar.jpg'],
        'Esetroot preferred',
    );
}

{
    # icewmbg is better at transparency handling, but does not have a
    # real tiled implementation
    @available = ('icewmbg', 'qiv');
    is_deeply(
        [set_wallpaper_command('foo.jpg', mode => 'tile')],
        ['icewmbg', '-s', 'foo.jpg'],
        'icewmbg preferred',
    );

    is_deeply(
        [set_wallpaper_command('foo.jpg', mode => 'full')],
        ['qiv', '--root_s', 'foo.jpg'],
        'qiv preferred - not a fallback',
    );
}

{
    # Test real commands
    @called = ();
    @available = ('feh');
    lives_ok { $ENV{DISPLAY} = 1; set_wallpaper('bar.jpg') } 'set_wallpaper';
    is_deeply( \@called, ['feh', '--bg-scale', 'bar.jpg'] );

    @called = ();
    @available = ('chbg');
    lives_ok { set_wallpaper('bar.jpg', mode => 'center', display => ':0.1') } 'with display arg';
    is_deeply( \@called, ['env', 'DISPLAY=:0.1', 'chbg', '-once', '-mode', 'center', 'bar.jpg'] );

    local $ENV{'DISPLAY'} = '';

    throws_ok {
        set_wallpaper('foo.jpg');
    } qr/You are not connected to an X session/, 'no X session';

    @called = ();
    @available = ('chbg');
    lives_ok { set_wallpaper('bar.jpg', mode => 'center', display => ':0.1') } 'with display arg, no env X session';
    is_deeply( \@called, ['env', 'DISPLAY=:0.1', 'chbg', '-once', '-mode', 'center', 'bar.jpg'] );
}
