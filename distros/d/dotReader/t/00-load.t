#! perl

use strict;
use warnings;

use Test::More qw(no_plan);
use File::Find qw(find);
use IPC::Run qw(run);

(-e 'lib') or die "cannot see lib";
my @files = @ARGV;

unless(@files) { # allow command-line check
  find( sub {
    /\.pm$/ or return;
    push(@files, $File::Find::name);
    }, 'lib/');
}

use Digest::MD5;
my %checksums = map({
  open(my $fh, '<', $_);
  my $d = Digest::MD5->new;
  $d->addfile($fh);
  $_ => $d->hexdigest;
  }
  @files
);

# change names to Lib::Path form
my %modmap = map({
  my $mod = $_;
  $mod =~ s#lib/##;
  $mod =~ s#\\|/#::#g;
  $mod =~ s/\.pm$// or die;
  $mod => $_;
  }
  @files
);
my @modlist = keys(%modmap);

my %known_ok;
use File::Basename;
my $cachefile = dirname($0) . '/.' . basename($0) . '.md5s';
if(-e $cachefile) {
  open(my $fh, '<', $cachefile) or die "cannot read $cachefile";
  %known_ok = map({chomp;($_ ? ($_ => 1) : ())} <$fh>);
};

# skip other-platform specific modules
my %skip = map({$_ => 1}
  # Just skip all of the platform-specific shims and let the chooser
  # module's BEGIN {} verify that they load.
  grep(/^dtRdr::HTMLShim::/, @modlist),
  );

# should be able to test this everywhere though
delete($skip{'dtRdr::HTMLShim::WxHTML'});


# skips
@modlist = grep({!$skip{$_}} @modlist);

ok(scalar(@modlist)) or BAIL_OUT("no modules found");

# try just loading them all and get out if it works
# (TODO 1.5s is still pretty slow compared to checking md5sums...)
if(0) {
  my ($in, $out, $err);
  # run perl, run
  my $v = run([$^X, map({"-M$_"} @modlist), '-e', ''], \$in, \$out, \$err); 
  if(ok(($v and !$err), 'all is well')) {
    diag("checked " . scalar(@modlist) . " modules -- looks good, we're outa here");
    exit;
  }
}

my %now_ok;
foreach my $mod (@modlist) {
  my $chk = $checksums{$modmap{$mod}};
  if($known_ok{$chk}) {
    ok(1, "$mod is unchanged");
    $now_ok{$chk} = 1;
    next;
  }
  #warn "now check $mod\n";

  my ($in, $out, $err);
  # if *anyone* says "use UNIVERSAL", use() behavior changes because
  # UNIVERSAL.pm is __broken__
  my $ucheck = '-MUNIVERSAL';
  # run perl, run
  my $v = run([$^X, $ucheck, '-Ilib', '-e', "use $mod;"], \$in, \$out, \$err); 
  if(ok((not $err), "silence")) {
    $now_ok{$chk} = 1;
  }
  else {
    warn "silence failure: in $mod\n", '#'x72, "\n$err\n", '#'x72, "\n";
  }
  ok($v, "use ok: $mod") or BAIL_OUT("$mod failed to load...STOP");
}

{
  open(my $fh, '>', $cachefile) or die "cannot write $cachefile";
  print $fh join("\n", grep({$now_ok{$_}} keys(%now_ok)));
}


# vim:ts=2:sw=2:sts=2:et:sta
