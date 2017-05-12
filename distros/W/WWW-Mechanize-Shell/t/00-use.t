use strict;
use Test::More tests => 22;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
$ENV{COLUMNS} = 80;
$ENV{LINES} = 24;

use_ok("WWW::Mechanize::Shell") or BAIL_OUT('Does not compile correctly');

diag "Running under $]";
for (qw(WWW::Mechanize LWP::UserAgent)) {
    diag "Using '$_' version " . $_->VERSION;
};

my $s = do {
  WWW::Mechanize::Shell->new("shell",rcfile => undef, warnings => undef);
};
isa_ok($s,"WWW::Mechanize::Shell");

# Now check our published API :
for my $meth (qw( source_file cmdloop agent option restart_shell option cmd )) {
  can_ok($s,$meth);
};

# Check that we can set known options
# See also t/05-options.t
my $oldvalue = $s->option('autosync');
$s->option('autosync',"foo");
is($s->option('autosync'),"foo","Setting an option works");
$s->option('autosync',$oldvalue);
is($s->option('autosync'),$oldvalue,"Setting an option still works");

# Check that trying to set an unknown option gives an error
{
  no warnings 'redefine';
  my $called;
  local *Carp::carp = sub {
    $called++;
  };
  $s->option('nonexistingoption',"foo");
  is($called,1,"Setting an nonexisting option calls Carp::carp");
}

{
  no warnings 'redefine';
  my $called;
  my $filename;
  local *WWW::Mechanize::Shell::source_file = sub {
    $filename = $_[1];
    $called++;
  };
  my $test_filename = '/does/not/need/to/exist';
  my $s = do {
    WWW::Mechanize::Shell->new("shell",rcfile => $test_filename, warnings => undef);
  };
  isa_ok($s,"WWW::Mechanize::Shell");
  ok($called,"Passing an .rc file tries to load it");
  is($filename,$test_filename,"Passing an .rc file tries to load the right file");
};

{
  no warnings 'redefine';
  my $called = 0;
  my $filename;
  local *WWW::Mechanize::Shell::source_file = sub {
    $filename = $_[1];
    $called++;
  };
  my $s = do {
    WWW::Mechanize::Shell->new("shell",rcfile => undef, warnings => undef);
  };
  isa_ok($s,"WWW::Mechanize::Shell");
  diag "Tried to load '$filename'" unless is($called,0,"Passing in no .rc file tries not to load it");
};

$s = WWW::Mechanize::Shell->new("shell",rcfile => undef, cookiefile => 'test.cookiefile', warnings => undef);
isa_ok($s,"WWW::Mechanize::Shell");
is($s->option('cookiefile'),'test.cookiefile',"Passing in a cookiefile filename works");

# Also check what gets exported:
ok(defined *main::shell{CODE},"'shell' gets exported");
{
  no warnings 'once';
  is(*main::shell{CODE},*WWW::Mechanize::Shell::shell{CODE},"'shell' is the right sub");
};

{
  no warnings 'redefine','once';
  my $called;
  local *WWW::Mechanize::Shell::cmdloop = sub { $called++ };
  # Need to suppress status warnings here
  shell(warnings => undef);
  is($called,1,"Shell function works");
};
