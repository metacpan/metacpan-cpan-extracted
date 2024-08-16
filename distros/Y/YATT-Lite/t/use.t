#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

chdir $FindBin::Bin
  or die "chdir to test dir failed: $!";

my $dist_root = "$FindBin::Bin/..";

use File::Find;

my @CORO = qw/Coro Coro::AIO AnyEvent/;
my @M4I = qw/File::AddInc MOP4Import::Base::CLI_JSON/;

my %prereq
  = ('YATT::Lite::WebMVC0::DBSchema::DBIC' => [qw/DBIx::Class::Schema/]
     , 'YATT::Lite::Test::TestFCGI' => [qw/HTTP::Response/]
     , 'YATT::Lite::WebMVC0::Partial::Session3' => [qw/Session::ExpiryFriendly/]

     , 'YATT::Lite::Inspector' => [@M4I, qw/Text::Glob/]
     , 'YATT::Lite::LanguageServer' => [@M4I, @CORO]
     , 'YATT::Lite::LanguageServer::Generic' => [@M4I, @CORO]
     , 'YATT::Lite::LanguageServer::Protocol' => [@M4I]
     , 'YATT::Lite::LanguageServer::SpecParser' => [@M4I]
     , 'YATT::Lite::LanguageServer::Spec2Types' => [@M4I]
     , 'YATT::Lite::LRXML::AltTree' => [@M4I]
    );

my %ignore; map ++$ignore{$_}, ();


my @modules = ('YATT::Lite');
my (%modules) = ('YATT::Lite' => "$dist_root/Lite.pm");
find {
  no_chdir => 1,
  wanted => sub {
  my $name = $File::Find::name;
  return unless $name =~ m{(?:^|/)\w+\.pm$};
  $name =~ s{^\Q$dist_root\E/}{YATT/};
  $name =~ s{/}{::}g;
  $name =~ s{\.pm$}{}g;
  return if $ignore{$name};
  print "$File::Find::name => $name\n" if $ENV{VERBOSE};
  $modules{$name} = $File::Find::name;
  push @modules, untaint_any($name);
}}, untaint_any("$dist_root/Lite");

plan tests => 3 * @modules;

foreach my $mod (@modules) {
 SKIP: {
    if (my $req = $prereq{$mod}) {
      foreach my $m (@$req) {
	unless (eval "require $m") {
	  skip "testing $mod requires $m", 3;
	}
      }
    }
    require_ok($mod);
    ok scalar fgrep(qr/^use strict;$/, $modules{$mod})
      , "is strict: $mod";
    ok scalar fgrep(qr{^use warnings qw\(FATAL all NONFATAL misc}, $modules{$mod})
      , "is warnings $mod";
  }
}

sub fgrep {
  my ($pattern, $file) = @_;
  open my $fh, '<', $file or die "Can't open $file: $!";
  my @result;
  while (defined(my $line = <$fh>)) {
    next unless $line =~ $pattern;
    push @result, $line;
  }
  @result;
}

done_testing();
