#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $script_dir = dirname(abs_path(__FILE__));
my $proj_dir   = abs_path(File::Spec->catdir($script_dir, '..', '..'));

use lib do {
    my $d = abs_path(File::Spec->catdir(dirname(__FILE__), '..', '..'));
    (File::Spec->catdir($d, 'lib'),
     File::Spec->catdir($d, '..', 'Yote-SQLObjectStore', 'lib'))
};

use Test::More;
use Yote::YapiServer::YapiDef;
use Yote::YapiServer::Compiler;
use YAML;

#======================================================================
# Test 1: Parse corpse.ydef and verify structure
#======================================================================

my $ydef_file = File::Spec->catfile($proj_dir, 'yaml', 'corpse.ydef');
my $defs = Yote::YapiServer::YapiDef::parse_file($ydef_file);

is(scalar @$defs, 1, 'corpse.ydef produces 1 top-level definition');

my $app = $defs->[0];
is($app->{type},    'app',                             'type is app');
is($app->{package}, 'Madyote::App::ExquisiteCorpse',   'package name');

# Cols
is_deeply(
    $app->{cols},
    {
        stories_in_progress => '*ARRAY_*::Story',
        stories_completed   => '*ARRAY_*::Story',
    },
    'cols parsed correctly'
);

# Public vars (from values block)
is($app->{public_vars}{appName},    'Exquisite Corpse', 'appName value');
is($app->{public_vars}{appVersion}, '1.0.0',            'appVersion value');
like($app->{public_vars}{description}, qr/collaborative storytelling/, 'description multi-line value');
is($app->{public_vars}{sectionsToComplete}, '5', 'sectionsToComplete value');

# Vars
is($app->{vars}{SECTIONS_TO_COMPLETE}, '5',   'SECTIONS_TO_COMPLETE var');
is($app->{vars}{VISIBLE_CHARS},        '200', 'VISIBLE_CHARS var');

# Methods
my @expected_methods = qw(
    continueStory getAvailableStories getCompletedStories
    getMyStories getStory startStory
);
is_deeply(
    [sort keys %{$app->{methods}}],
    \@expected_methods,
    'all methods present'
);

# Method access levels
is($app->{methods}{getCompletedStories}{access}, 'public', 'getCompletedStories is public');
is($app->{methods}{getStory}{access},            'public', 'getStory is public');
is($app->{methods}{startStory}{access},          'auth',   'startStory is auth');
is($app->{methods}{continueStory}{access},       'auth',   'continueStory is auth');

# Method code is present and sane
like($app->{methods}{startStory}{code},  qr/\$self.*\$args.*\$session/, 'startStory code has standard args');
like($app->{methods}{continueStory}{code}, qr/story_id/, 'continueStory references story_id');

# Nested objects
ok($app->{objects},          'has nested objects');
ok($app->{objects}{Story},   'has Story object');
ok($app->{objects}{Section}, 'has Section object');

# Story object
my $story = $app->{objects}{Story};
is_deeply(
    [sort keys %{$story->{cols}}],
    [qw(completed created last_author owner sections sections_needed)],
    'Story cols'
);
is($story->{field_access}{owner}, 'public', 'Story owner field_access');
ok($story->{subs}{to_client_hash}, 'Story has to_client_hash sub');
like($story->{subs}{to_client_hash}, qr/sectionCount/, 'to_client_hash code is present');

# Section object
my $section = $app->{objects}{Section};
is_deeply(
    [sort keys %{$section->{cols}}],
    [qw(created owner text)],
    'Section cols'
);
is($section->{field_access}{text}, 'public', 'Section text field_access');

#======================================================================
# Test 2: Compound access levels
#======================================================================

my $compound_ydef = <<'YDEF';
app Test::Compound {
  method auth,owner_only doSomething {
    my ($self) = @_;
    return 1;
  }
}
YDEF

my $compound_defs = Yote::YapiServer::YapiDef::parse_string($compound_ydef);
my $compound_app = $compound_defs->[0];
is_deeply(
    $compound_app->{methods}{doSomething}{access},
    { auth => 1, owner_only => 1 },
    'compound access parsed into hash'
);

#======================================================================
# Test 3: Server block
#======================================================================

my $server_ydef = <<'YDEF';
server Madyote {
  base Yote::YapiServer::Site

  uses {
    Madyote::App::ExquisiteCorpse
  }

  apps {
    corpse Madyote::App::ExquisiteCorpse
  }
}
YDEF

my $server_defs = Yote::YapiServer::YapiDef::parse_string($server_ydef);
is(scalar @$server_defs, 1, 'server produces 1 def');
my $server = $server_defs->[0];
is($server->{type},    'server',                  'server type');
is($server->{package}, 'Madyote',                 'server package');
is($server->{base},    'Yote::YapiServer::Site',  'server base');
is_deeply($server->{uses}, ['Madyote::App::ExquisiteCorpse'], 'server uses');
is_deeply($server->{apps}, { corpse => 'Madyote::App::ExquisiteCorpse' }, 'server apps');

#======================================================================
# Test 4: Standalone object
#======================================================================

my $standalone_ydef = <<'YDEF';
object My::Package::Widget {
  cols {
    name VARCHAR(255)
    count INT DEFAULT 0
  }

  field_access {
    name public
    count auth
  }

  sub calculate {
    my ($self) = @_;
    return $self->get_count * 2;
  }
}
YDEF

my $standalone_defs = Yote::YapiServer::YapiDef::parse_string($standalone_ydef);
my $widget = $standalone_defs->[0];
is($widget->{type},    'object',              'standalone object type');
is($widget->{package}, 'My::Package::Widget', 'standalone object package');
is($widget->{cols}{name}, 'VARCHAR(255)',      'standalone object col');
is($widget->{field_access}{count}, 'auth',    'standalone object field_access');
like($widget->{subs}{calculate}, qr/get_count/, 'standalone object sub');

#======================================================================
# Test 5: Comments are ignored
#======================================================================

my $comment_ydef = <<'YDEF';
# Top-level comment
app Test::Comments {
  # Block comment
  cols {
    # Inside cols
    name TEXT
  }

  method public hello {
    # This comment is inside code and preserved
    my ($self) = @_;
    return 1, "hi";
  }
}
YDEF

my $comment_defs = Yote::YapiServer::YapiDef::parse_string($comment_ydef);
is(scalar @$comment_defs, 1, 'comments do not create extra defs');
is($comment_defs->[0]->{cols}{name}, 'TEXT', 'cols parsed despite comments');
like($comment_defs->[0]->{methods}{hello}{code}, qr/# This comment/, 'comments inside code preserved');

#======================================================================
# Test 6: Multi-line quoted string in values
#======================================================================

my $multiline_ydef = <<'YDEF';
app Test::MultiLine {
  values {
    greeting "Hello,
this spans
multiple lines."
    simple one-liner
  }
}
YDEF

my $ml_defs = Yote::YapiServer::YapiDef::parse_string($multiline_ydef);
my $ml = $ml_defs->[0];
like($ml->{public_vars}{greeting}, qr/Hello,\nthis spans\nmultiple lines\./, 'multi-line quoted value');
is($ml->{public_vars}{simple}, 'one-liner', 'simple value alongside multi-line');

#======================================================================
# Test 7: Compiler produces identical output for .ydef and .yaml
#======================================================================

my $tmpdir_ydef = tempdir(CLEANUP => 1);
my $tmpdir_yaml = tempdir(CLEANUP => 1);

Yote::YapiServer::Compiler::compile($ydef_file, $tmpdir_ydef);
Yote::YapiServer::Compiler::compile(
    File::Spec->catfile($proj_dir, 'yaml', 'corpse.yaml'),
    $tmpdir_yaml
);

my $ydef_pm = File::Spec->catfile($tmpdir_ydef, 'Madyote', 'App', 'ExquisiteCorpse.pm');
my $yaml_pm = File::Spec->catfile($tmpdir_yaml, 'Madyote', 'App', 'ExquisiteCorpse.pm');

ok(-f $ydef_pm, 'ydef compilation produced .pm file');
ok(-f $yaml_pm, 'yaml compilation produced .pm file');

# Read both files and compare
open my $fh1, '<', $ydef_pm or die "Cannot read $ydef_pm: $!";
my $ydef_content = do { local $/; <$fh1> };
close $fh1;

open my $fh2, '<', $yaml_pm or die "Cannot read $yaml_pm: $!";
my $yaml_content = do { local $/; <$fh2> };
close $fh2;

is($ydef_content, $yaml_content, '.ydef and .yaml produce identical compiled output');

#======================================================================
# Test 8: Compile server from .ydef string
#======================================================================

my $server_tmpdir = tempdir(CLEANUP => 1);
my $server_file = File::Spec->catfile($server_tmpdir, 'test.ydef');
open my $sfh, '>', $server_file or die $!;
print $sfh $server_ydef;
close $sfh;

Yote::YapiServer::Compiler::compile($server_file, $server_tmpdir);
ok(-f File::Spec->catfile($server_tmpdir, 'Madyote.pm'), 'server .ydef compiled to .pm');

#======================================================================
# Test 9: Directory compilation includes .ydef files
#======================================================================

my $dir_tmpdir = tempdir(CLEANUP => 1);

# Capture output — should find both .yaml and .ydef files
my $yaml_dir = File::Spec->catdir($proj_dir, 'yaml');
Yote::YapiServer::Compiler::compile($yaml_dir, $dir_tmpdir);

ok(-f File::Spec->catfile($dir_tmpdir, 'Madyote', 'App', 'ExquisiteCorpse.pm'),
   'directory compile found .ydef file');
ok(-f File::Spec->catfile($dir_tmpdir, 'Madyote.pm'),
   'directory compile found .yaml server file');

done_testing;
