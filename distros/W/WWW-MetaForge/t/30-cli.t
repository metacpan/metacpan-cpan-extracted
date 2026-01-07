#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/lib";
use Capture::Tiny qw(capture_stdout);

# Skip if Capture::Tiny not available
BEGIN {
  eval { require Capture::Tiny };
  if ($@) {
    plan skip_all => 'Capture::Tiny required for CLI tests';
  }
}

use_ok('WWW::MetaForge::ArcRaiders::CLI');

my $cache_dir = tempdir(CLEANUP => 1);

# Helper to create CLI with MockUA
sub mock_cli {
  require MockUA;
  my $cli = WWW::MetaForge::ArcRaiders::CLI->new();
  # Inject mock API
  $cli->{api} = WWW::MetaForge::ArcRaiders->new(
    ua        => MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures"),
    cache_dir => $cache_dir,
    use_cache => 0,
  );
  return $cli;
}

subtest 'CLI help' => sub {
  my $cli = mock_cli();
  my $output = capture_stdout {
    $cli->execute([], [$cli]);
  };

  like($output, qr/metaforge-arcraiders/, 'shows app name');
  like($output, qr/items/, 'mentions items command');
  like($output, qr/quests/, 'mentions quests command');
  like($output, qr/--debug/, 'mentions debug option');
  like($output, qr/--json/, 'mentions json option');
};

subtest 'Items command' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Items;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Items->new();

  my $output = capture_stdout {
    local @ARGV = ();
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Ferro/, 'shows item names');
  like($output, qr/Weapon|Material/, 'shows categories');
  like($output, qr/item\(s\)/, 'shows item count');
};

subtest 'Items command with search' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Items;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Items->new(search => 'Ferro');

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  # MockUA doesn't actually filter, but command should run
  like($output, qr/Ferro/, 'shows results');
};

subtest 'Items command with category filter' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Items;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Items->new(category => 'Weapon');

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  # Category filter is local, should only show weapons
  like($output, qr/Weapon/, 'shows weapons');
  unlike($output, qr/Material\s+Common\s+\[metal-parts\]/, 'does not show materials');
};

subtest 'Items command with rarity filter' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Items;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Items->new(rarity => 'Rare');

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Rare/, 'shows rare items');
};

subtest 'Items command JSON output' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Items;

  my $cli = mock_cli();
  $cli->{json} = 1;  # Enable JSON mode
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Items->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/^\[/, 'starts with [');
  like($output, qr/"name"/, 'has name field');
  like($output, qr/"id"/, 'has id field');

  # Should be valid JSON
  require JSON::MaybeXS;
  my $data = eval { JSON::MaybeXS::decode_json($output) };
  ok(!$@, 'valid JSON') or diag("JSON error: $@");
  ok(ref $data eq 'ARRAY', 'is array');
};

subtest 'Arcs command' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Arcs;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Arcs->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Salvage|arc/i, 'shows arc data');
};

subtest 'Quests command' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Quests;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Quests->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/quest|Quest/i, 'shows quest data');
};

subtest 'Events command' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Events;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Events->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  # May show events or "no events" message
  ok(length($output) > 0, 'produces output');
};

subtest 'Traders command' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Traders;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Traders->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  ok(length($output) > 0, 'produces output');
};

# Single item/quest/arc/event commands
subtest 'Item command - single item lookup' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Item;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Item->new();

  my $output = capture_stdout {
    $cmd->execute(['ferro-i'], [$cli]);
  };

  like($output, qr/Ferro I/i, 'shows item name');
  like($output, qr/ID:/i, 'shows ID field');
};

subtest 'Item command - no argument shows usage' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Item;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Item->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Usage:/i, 'shows usage message');
};

subtest 'Quest command - single quest lookup' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Quest;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Quest->new();

  my $output = capture_stdout {
    $cmd->execute(['a-bad-feeling'], [$cli]);
  };

  like($output, qr/A Bad Feeling/i, 'shows quest name');
  like($output, qr/ID:/i, 'shows ID field');
};

subtest 'Quest command - no argument shows usage' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Quest;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Quest->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Usage:/i, 'shows usage message');
};

subtest 'Arc command - single arc lookup' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Arc;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Arc->new();

  my $output = capture_stdout {
    $cmd->execute(['salvage-run'], [$cli]);
  };

  like($output, qr/Salvage Run/i, 'shows arc name');
  like($output, qr/ID:/i, 'shows ID field');
};

subtest 'Arc command - no argument shows usage' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Arc;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Arc->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Usage:/i, 'shows usage message');
};

subtest 'Event command - single event lookup' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Event;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Event->new();

  my $output = capture_stdout {
    $cmd->execute(['Cold Snap'], [$cli]);
  };

  # Should find event or show not found
  ok(length($output) > 0, 'produces output');
  like($output, qr/Cold Snap|not found/i, 'shows event or not found');
};

subtest 'Event command - no argument shows usage' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Event;

  my $cli = mock_cli();
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Event->new();

  my $output = capture_stdout {
    $cmd->execute([], [$cli]);
  };

  like($output, qr/Usage:/i, 'shows usage message');
};

subtest 'Item command - JSON output' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Item;

  my $cli = mock_cli();
  $cli->{json} = 1;
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Item->new();

  my $output = capture_stdout {
    $cmd->execute(['ferro-i'], [$cli]);
  };

  like($output, qr/^\{/, 'starts with {');
  like($output, qr/"name"/, 'has name field');

  require JSON::MaybeXS;
  my $data = eval { JSON::MaybeXS::decode_json($output) };
  ok(!$@, 'valid JSON') or diag("JSON error: $@");
};

subtest 'Quest command - JSON output' => sub {
  require WWW::MetaForge::ArcRaiders::CLI::Cmd::Quest;

  my $cli = mock_cli();
  $cli->{json} = 1;
  my $cmd = WWW::MetaForge::ArcRaiders::CLI::Cmd::Quest->new();

  my $output = capture_stdout {
    $cmd->execute(['a-bad-feeling'], [$cli]);
  };

  like($output, qr/^\{/, 'starts with {');
  like($output, qr/"name"/, 'has name field');

  require JSON::MaybeXS;
  my $data = eval { JSON::MaybeXS::decode_json($output) };
  ok(!$@, 'valid JSON') or diag("JSON error: $@");
};

done_testing;
