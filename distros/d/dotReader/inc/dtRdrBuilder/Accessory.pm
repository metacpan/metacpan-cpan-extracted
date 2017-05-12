package inc::dtRdrBuilder::Accessory;

# Copyright (C) 2006, 2007 by Eric Wilhelm and OSoft, Inc.
# License: GPL

# stuff that is maybe not really needed

use warnings;
use strict;
use Carp;

=head1 ACTIONS

=over

=item podserver

Start a server on 8088 (or so)

=cut

sub ACTION_podserver {
  my $self = shift;
  # TODO make this cooler
  fork or exec(qw(xterm -g 30x5 -e podserver inc lib util));
} # end subroutine ACTION_podserver definition
########################################################################

=item run

basically:

  perl -Ilib client/app.pl

=cut

sub ACTION_run {
  my $self = shift;
  my (@args) = @_;
  $self->depends_on('code');
  exec($self->perl, '-Iblib/lib', 'client/app.pl', @{$self->{args}{ARGV}});
} # end subroutine ACTION_run definition
########################################################################

=item books

Assemble the book packages per the BOOKMANIFEST file.

=cut

sub ACTION_books {
  my $self = shift;
  my (@args) = @_;

  my $pdir = 'test_packages/';
  (-d $pdir) or die "cannot see '$pdir' directory";

  # TODO special copy+unzip for thout_1_0 books with internal gzipped
  # content (those are really just an svn hack)

  my @books;
  if(@args) {
    @books = @args;
  }
  else {
    @books = do {
      my $manifest = $pdir . 'BOOKMANIFEST';
      open(my $fh, '<', $manifest) or die "cannot open '$manifest' $!";
      map({chomp;$_} <$fh>);
    };
  }
  @books or die "eek";

  my $d_dir = "$pdir/0_jars";
  require File::Path;
  unless(-d $d_dir) {
    File::Path::mkpath($d_dir) or die "need $d_dir $!";
  }

  foreach my $book (@books) {
    # TODO make all of this into ./bin/drbook_builder or something

    my $destfile = "$d_dir/$book.jar";

    use Archive::Zip ();
    use File::Find;
    my @book_bits;
    find(sub {
      if(-d $_ and m/\.svn/) {
        $File::Find::prune = 1;
        return;
      }
      (-f $_) or return;
      m/^\./ and return;
      #warn "found $File::Find::name\n";
      push(@book_bits, $File::Find::name);
    }, $pdir . $book);
    
    # skip it if we've got one, see
    if($self->up_to_date(\@book_bits, $destfile)) {
      warn "$destfile is up-to-date\n";
      next;
    }
    
    my $zip = Archive::Zip->new();
    foreach my $bit (@book_bits) {
      my $string = do {
        open(my $fh, '<', $bit) or die "ack '$bit' $!";
        binmode($fh);
        local $/;
        <$fh>;
      };
      my $bitname = $bit;
      $bitname =~ s#.*$book/+##;
      $zip->addString($string, $bitname);
    }
    warn "making $book.jar\n";
    $zip->writeToFileNamed( $destfile ) == Archive::Zip::AZ_OK
     or die 'write error';
  }
} # end subroutine ACTION_books definition
########################################################################

=item compile

=cut

sub ACTION_compile {
  my $self = shift;

  # This line of thought has basically been dropped.  Nice in theory,
  # but terribly messy in practice.

  die "nope";

  # XXX use find_pm_files instead?
  #my %map = $self->_module_map;
  my $files = $self->find_pm_files;
  #basically: $ perl -MO=Bytecode,-H,-oblib/lib/dtRdr.pmc -Ilib lib/dtRdr.pm

  while (my ($file, $dest) = each %$files) {
    my $to_path = File::Spec->catfile($self->blib, $dest);
    if($file =~ m/dtRdr\/HTML/) { # these are too touchy
      $self->copy_if_modified(from => $file, to => $to_path);
      next;
    }
    # nice to have somewhere to go
    File::Path::mkpath(File::Basename::dirname($to_path), 0, 0777);
    next if $self->up_to_date($file, $to_path); # Already fresh
    my @command = (
      "-MO=Bytecode,-b,-H,-o$to_path", '-Ilib', $file
    );
    $self->run_perl_command(\@command);
  }
} # end subroutine ACTION_compile definition
########################################################################

=back

=cut

1;
