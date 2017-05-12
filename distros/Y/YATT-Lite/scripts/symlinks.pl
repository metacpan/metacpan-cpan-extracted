#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);

use autodie;
use Cwd;
use base qw(File::Spec);
use Getopt::Long;
use File::Find;
use File::Basename;

sub MY () {__PACKAGE__}
use fields qw(verbose recursive);

sub savefilename {'.symlinks'}

#
# main
#
{
  my MY $self = fields::new(MY);
  my @opt_spec = ("v|verbose" => \ $self->{verbose}
		  , "r|recursive" => \ $self->{recursive});
  GetOptions(@opt_spec)
    or exit 1;
  my $method = shift;
  if (@ARGV and $ARGV[0] =~ /^-/) {
    GetOptions(@opt_spec)
  }

  if (my $sub = $self->can("cmd_$method")) {
    $sub->($self, undef, @ARGV);
  } elsif ($sub = $self->can($method)) {
    $sub->($self, @ARGV);
  }
}

sub cmd_list {
  (my MY $self, my $cb) = splice @_, 0, 2;
  if ($self->{recursive}) {
    $self->cmd_rlist($cb, @_);
  } else {
    $self->cmd_list_foreach_dir($cb, @_);
  }
}

sub cmd_list_foreach_dir {
  (my MY $self, my $cb) = splice @_, 0, 2;
  my $oldcwd = MY->rel2abs(Cwd::cwd());
  foreach my $dir (@_ ? @_ : '.') {
    chdir($dir);
    opendir my $dh, '.';
    my @links = $self->list_links($dh)
      or next;
    if ($cb) {
      $cb->($dir, @links);
    } else {
      print join("\n", map {join("\t", @$_)} @links), "\n";
    }
  } continue {
    chdir($oldcwd);
  }
}

sub prune {
  $File::Find::prune = 1;
}

sub cmd_rlist {
  (my MY $self, my $cb) = splice @_, 0, 2;
  my (%found_dir, @dir);
  find({no_chdir => 1, wanted => sub {
	  return $self->prune if m{/\.git$};
	  return unless -l $_;
	  return if $found_dir{$File::Find::dir}++;
	  push @dir, $File::Find::dir;
	  print "# $File::Find::dir\n" if not $cb;
	  $self->cmd_list_foreach_dir($cb, $File::Find::dir);
	}}, @_ ? @_ : '.');
  @dir;
}

sub cmd_list_savefile {
  (my MY $self, my $cb) = splice @_, 0, 2;
  my $pat = quotemeta(savefilename());
  find({no_chdir => 1, wanted => sub {
	  return $self->prune if m{/\.git$};
	  return unless m{/$pat$};
	  if ($cb) {
	    $cb->($_);
	  } else {
	    print $_, "\n";
	  }
	}}, @_ ? @_ : '.');
}

sub cmd_save {
  (my MY $self, undef) = splice @_, 0, 2;
  local $self->{verbose} = 1;
  $self->cmd_list(sub {$self->save_links(@_)}, @_);
}

sub save_links {
  (my MY $self, my $dir) = splice @_, 0, 2;
  print STDERR "# saving $dir/".savefilename()."\n"
    if $self->{verbose};
  open my $out, '>', savefilename();
  foreach my $desc (@_) {
    print $out (my $str = join("\t", @$desc), "\n");
    print STDERR $str, "\n" if $self->{verbose};
  }
}

sub cmd_restore {
  (my MY $self, undef) = splice @_, 0, 2;
  $self->cmd_list_savefile(sub {$self->restore_links(dirname(shift))}, @_);
}

sub restore_links {
  (my MY $self, my $dir) = @_;
  my $savefile = "$dir/" . savefilename();
  print STDERR "# restoring from $savefile\n" if $self->{verbose};
  open my $fh, '<', $savefile;
  while (my $line = <$fh>) {
    chomp($line);
    next if $line =~ /^#/;
    my ($linkto, $placed_fn) = split "\t", $line;
    my $placed_path = "$dir/$placed_fn";
    unless (-l $placed_path) {
      symlink($linkto, $placed_path);
      print "[created] $linkto\t$placed_fn\n";
    } elsif (my $was = readlink $placed_path) {
      if ($was eq $linkto) {
	print "[kept] $linkto\t$placed_fn\n" if $self->{verbose};
      } else {
	unlink $placed_path;
	symlink($linkto, $placed_path);
	print "[updated] $linkto\t$placed_fn\n";
      }
    }
  }
}

sub list_links {
  my ($self, $dh) = @_;
  map {
    # Same order of ``ln -s to from''
    [readlink($_), $_]
  } sort grep {
    -l
      and !/^\.\#/  # To ignore Emacs lock file.
  } readdir($dh);
}
