#!perl -T

use warnings;
use strict;
use Test::More tests => 19;

BEGIN {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};  # Placates taint-unsafe Cwd.pm in 5.6.1
    use_ok( 'WWW::Scripter' );
}

my $mech = WWW::Scripter->new( cookie_jar => undef );
isa_ok( $mech, 'WWW::Scripter' );


our($Module, $File);
sub Dummy::init{$Module = shift}

unshift @INC, sub {
    return undef unless caller eq 'WWW::Scripter';
    no strict 'refs';
    $File = $_[1];
    (my $pack = $_[1]) =~ s-/-::-g;
    chop, chop, chop for $pack;
    *{"$pack:\:init"} = *Dummy::init;
    open my $fh, '<', \1;
    return $fh;
};

# tests 3-8
$mech->use_plugin('SimplePluginName');
is $File, 'WWW/Scripter/Plugin/SimplePluginName.pm',
    'plugin --> file conversion with simple plugin name';
is $Module, 'WWW::Scripter::Plugin::SimplePluginName',
    'plugin --> module conversion with simple plugin name';
$mech->use_plugin('Compound-Plugin-Name');
is $File, 'WWW/Scripter/Plugin/Compound/Plugin/Name.pm',
    'plugin --> file conversion with compound plugin name';
is $Module, 'WWW::Scripter::Plugin::Compound::Plugin::Name',
    'plugin --> module conversion with compound plugin name';
$mech->use_plugin('Module::Name');
is $File, 'Module/Name.pm',
    'plugin --> file conversion with module name';
is $Module, 'Module::Name',
    'plugin --> module conversion with module name';

shift @INC;


++$INC{'_/ObjectPlugin.pm'};
{ package _::ObjectPlugin;
    sub init {
        my $self = bless {
            mech => $_[1],
            opts => [@{$_[2]}],
	}, $_[0];
        @{$_[2]} = ();
	return $self;
    }
    sub options {
        $_[0]->{opts2} = [@_[1..$#_]]
    }
}

# tests 9-15
my $obj = $mech->use_plugin('_::ObjectPlugin',1,2,3);
is ref $obj, '_::ObjectPlugin',
    'return value of ->use_plugin(_::Foo) is blessed into _::Foo';
is $obj->{mech}, $mech, '$mech is passed to Plugin->init';
is_deeply $obj->{opts}, [1..3], 'and so are the options';
is $mech->use_plugin('_::ObjectPlugin'), $obj,
    'use_plugin returns the same plugin thingy if already loaded';
ok !exists $obj->{opts2}, '$plugin->options is not called unnecessarily';
$mech->use_plugin('_::ObjectPlugin' => 7,8,9);
is_deeply $obj->{opts2}, [7..9], '$plugin->options after use_plugin';
is $mech->plugin("_::ObjectPlugin"), $obj, '$mech->plugin';

++$INC{'_/ObjectPlugin2.pm'};
{ package _::ObjectPlugin2;
    sub init {
        bless {}, shift;
    }
    sub options {
        $_[0]->{opts} = [@_[1..$#_]]
    }
}

# test 16
$obj = $mech->use_plugin('_::ObjectPlugin2' => 9,8,7);
is_deeply $obj->{opts}, [9,8,7], '$plugin->options called by use_plugin';

++$INC{'_/ScalarPlugin.pm'};
++$INC{'_/ScalarPlugin2.pm'};
++$INC{'_/FalsePlugin.pm'};
sub _::ScalarPlugin::init { 1 };
sub _::ScalarPlugin2::init { 1 };
sub _::FalsePlugin::init { 0 };

# tests 17-19
ok $mech->use_plugin('_::ScalarPlugin'),
    'use_plugin when init returns a scalar';
eval { $mech->use_plugin('_::ScalarPlugin2', qw/and some options/) };
ok $@, 'use_plugin dies when passed options and init returns a scalar';
ok !$mech->use_plugin('_::FalsePlugin'),
    'use_plugin returns false if init does';
