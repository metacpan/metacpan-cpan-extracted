#!/usr/bin/perl -w

# Copyright 2010, 2011, 2016, 2017 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;

use FindBin;
my $progfile = "$FindBin::Bin/$FindBin::Script";
print "progfile: $progfile\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  require App::PodLinkCheck;
  @ARGV = ('--verbose', '-I',$FindBin::Bin, '-Inosuchdir', $progfile);
  my $plc = App::PodLinkCheck->new;
  my $exit = $plc->command_line;
  ### $exit
  exit 0;
}
{
  require App::PodLinkCheck;
  my $plc = App::PodLinkCheck->new (verbose => 0);
  $plc->check_tree('/usr/share/perl5');
  exit 0;
}
{
  require App::PodLinkCheck;
  require File::Find::Iterator;
  my $order = \&App::PodLinkCheck::_find_order;

  print App::PodLinkCheck::_find_order('aa','bb'),"\n";
  print sort {App::PodLinkCheck::_find_order($a,$b)} 'a','b','c';
  print "\n";

  my $finder = File::Find::Iterator->create (dir => ['/usr/share/perl5/File'],
                                             order => $order);
  while (my $filename = $finder->next) {
    print "$filename\n";
  }
  exit 0;
}



{
  require App::PodLinkCheck;
  my $plc = App::PodLinkCheck->new;

  #   my $conf = $plc->_CPAN_config;
  #   print "conf $conf\n";

  print $plc->_module_known_CPAN('Pod::Find'),"\n";
  print $plc->_module_known_CPAN('Pod::Find'),"\n";
  print $plc->_module_known_CPAN_SQLite('Pod::Find'),"\n";
  print $plc->_module_known_cpanminus('Pod::Find'),"\n";
  exit 0;
}
{
  print "IPC::Open3\n";
  $^O = 'os2';
  require IPC::Open3;
  my $pid = IPC::Open3::open3 (\*STDIN, \*STDOUT, \*STDERR,
                               'echo hi; sleep 100');
  sleep 1;
  #  print "pid $pid\n";
  exit 0;
}
{
  require IPC::Run3;
  open my $tty, '>&', 'STDOUT' or die;
  print $tty "tty fileno ",fileno($tty),"\n";
  open STDOUT, '>/tmp/out' or die;
  open STDERR, '>/tmp/err' or die;
  print $tty "fileno ",fileno(STDOUT)," ",fileno(STDERR),"\n";
  # IPC::Run3::run3 (['echo','hi'], \undef, \*STDERR, \*STDOUT);
  IPC::Run3::run3 (['man'], \undef, \*STDERR, \*STDOUT);
  exit 0;
}
{
  open FH, '>>&=', 4
    or die "$!";
  print "jdkfsl\n" or die;
  print STDERR "fileno ",fileno(FH),"\n";
  exit 0;
}
{
#  delete $ENV{PATH};
  require App::PodLinkCheck;
  *App::PodLinkCheck::_man_has_location_option = sub(){0};
  my $plc = App::PodLinkCheck->new;
  my $name = 'fsdfjkdslcat(1)';
  print "manpage_is_known() $name\n";
  my $result = $plc->manpage_is_known($name);
  print "  is ", $result, "\n";
  print "done\n";
  exit 0;
}
{
  my $str = `sleep 20`;
  print "parent done\n";
  exit 0;
}
{
  if (fork() == 0) {
    print "exec\n";
    exec 'sleep', '20';
  }
  print "parent\n";
  sleep 100;
  print "parent done\n";
  exit 0;
  # system
}
{
  require IPC::Run3;
  my $fh = File::Temp->new;
  IPC::Run3::run3 (['sleep','100'], undef, undef, undef,
                   return_if_system_error => 1);

  IPC::Run3::run3 (['man','perltoc'],
                   \undef,  # stdin
                   $fh,     # stdout
                   \undef,  # stderr
                   return_if_system_error => 1);
  seek $fh, 0, 0;
  foreach (1 .. 5) {
    if (! defined (readline $fh)) {
      print "eof\n";
      exit 0;
    }
  }
  close $fh or die;
  print "ok\n";
  exit 0;
}

{
  require App::PodLinkCheck;
  print App::PodLinkCheck::_man_has_location_option();
  exit 0;
}
{
  my $page = 'perltoc';
  open my $fh, '-|', 'man', $page;
  foreach (1 .. 5) {
    if (! defined (readline $fh)) {
      print "eof\n";
      exit 0;
    }
  }
  close $fh or die;
  print "ok\n";
  exit 0;
}
{
  require GDBM_File;
  require Fcntl;
  my %h;
  my $filename = '/tmp/x.gdbm';
  tie (%h, 'GDBM_File',
       $filename, Fcntl::O_RDWR()|Fcntl::O_CREAT(), 0666)
    or die "Cannot tie $filename: $!";

  $h{'foo'} = 'bar';
  exit 0;
}


{
  require IPC::Run;
  delete $ENV{PATH};
  IPC::Run::run (['man', '--location', 'cat']);
  print "done\n";
  exit 0;
}

{
  require Data::Dumper;
#   my @x;
#   $#x = 100e6 / 4;
#   print scalar(@x),"\n";

  #   my $pid = fork();
  #   print Data::Dumper->new([\$pid],['pid'])->Dump;

  my $out;
  require IPC::Run;
  IPC::Run::run (['ecfdjsklho', 'hello'],
                 \undef,  # stdin
                 \$out,  # stdout
                 sub{});  # stderr
  print "done\n";
  exit 0;
}



{
  my $parser = App::PodLinkCheck::SectionParser->new;
   $parser->parse_from_file ($progfile);
  # $parser->parse_from_file ('/usr/share/perl/5.10/pod/perlsyn.pod');

  my $sections = $parser->sections_hashref;
  require Data::Dumper;
  print Data::Dumper->new([$sections],['args'])->Sortkeys(1)->Dump;
  exit 0;
}

{
  my $plc = App::PodLinkCheck->new;
  $plc->check_file ($progfile);
  exit 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# =pod
# 
# Also see L<"General Regular Expression Traps using s///, etc.">
# 
# =cut

# L<some section>
# 
# L<"another section">

# =head2 Locale, Unicode and UTF-8
# 
# See L</Locale, Unicode and UTF-8>.
# =item *
# 
# some
# fdsjk
# fsd
# fsd
# fsd
# A new pragma, C<feature>, has been added; see above in L</"Core
# Enhancements">.
# text
# kfdsjk L<cat(6)/x
# y>
# blah
# blah
# 
# L<cat(1)>
# L<cat>

# =item C<code>
# 
# L</C<code>>

#  =item E<gt>
# 
#  =item co/de
#  X<foo>
# 
#  L</coE<sol>de>
# 
#  L<AutoLoader/foo>

# =item PERL_HASH_SEED
# X<PERL_HASH_SEED>
# 
# 
# =item blah Z<>
# 
# 
# 
# L</blah>
# 
# L</no such target>
# 
# L</PERL_HASH_SEED>
# 

# 
# L<AutoLoader/"foo bar">
# 
# =back
# 
# Pod::Man



__END__

#------------------------------------------------------------------------------
# using IPC::Run3 ... system() sigint trapped

# --location is not in posix,
# http://www.opengroup.org/onlinepubs/009695399/utilities/man.html
# Is it man-db specific, or does it have a chance of working elsewhere?
#
use constant::defer _man_has_location_option => sub {
  require IPC::Run3;
  my $str;
  IPC::Run3::run3 (['man','--help'],
                   \undef,  # stdin
                   \$str,   # stdout
                   \undef,  # stderr
                   return_if_system_error => 1);
  ### _man_has_location_option(): 0 + ($str =~ /--location\b/)
  $str =~ /--location\b/
};

sub _manpage_is_known_by_location {
  my ($self, @name) = @_;
  ### _manpage_is_known_by_location() run: \@name
  require IPC::Run3;
  my $str;
  IPC::Run3::run3 (['man', '--location', @name],
                   \undef,  # stdin
                   \$str,   # stdout
                   \undef,  # stderr
                   return_if_system_error => 1);
  ### _manpage_is_known_by_location() output: $str
  return ($str =~ /^.*\n$/ ? 1 : 0);
}

sub _manpage_is_known_by_output {
  my ($self, @name) = @_;
  require IPC::Run3;
  my $fh = File::Temp->new (TEMPLATE => 'PodLinkCheck-man-XXXXXX',
                            TMPDIR => 1);
  IPC::Run3::run3 (['man', @name],
                   \undef,  # stdin
                   $fh,     # stdout
                   \undef,  # stderr
                   return_if_system_error => 1);
  seek $fh, 0, 0;
  foreach (1 .. 5) {
    if (! defined (readline $fh)) {
      return 0;
    }
  }
  return 1;
}

__END__

=pod

L<SomeStrangeModule>
