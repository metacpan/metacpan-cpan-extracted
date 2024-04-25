package Treex::PML::Backend::CSTS;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}

use Treex::PML;
use Treex::PML::IO qw(set_encoding);
use Treex::PML::Backend::CSTS::Csts2fs;
use Treex::PML::Backend::CSTS::Fs2csts;
use Fcntl qw(SEEK_SET);
use File::ShareDir;

use vars qw($sgmls $sgmlsopts $doctype $csts_encoding);

sub default_settings {
  $sgmls = "nsgmls" unless $sgmls;
  $sgmlsopts = "-i preserve.gen.entities" unless $sgmlsopts;
  unless ($doctype and -f $doctype) {
    $doctype = eval { File::ShareDir::module_file(__PACKAGE__,'csts.doctype') };
    unless (defined($doctype) and -f $doctype) {
      $doctype = Treex::PML::IO::CallerDir(File::Spec->catfile(qw(CSTS share csts.doctype)));
    }
    unless (-f $doctype) {
      $doctype = Treex::PML::FindInResources("csts.doctype");
    }
  }
  $sgmls_command='%s %o %d %f' unless $sgmls_command;
  $csts_encoding = 'iso-8859-2'; # this the encoding of CSTS by definition
}

my %stderr_pool;
sub open_backend {
  my ($filename, $mode, $encoding)=@_;
  if ($mode eq 'w') {
    return Treex::PML::IO::open_backend($filename,$mode,$csts_encoding);
  } elsif ($mode eq 'r') {
    my $fh = undef;
    my $cmd = $sgmls_command;
    $doctype = Treex::PML::FindInResources($doctype) unless -f $doctype;
    print STDERR "$cmd\n" if $Treex::PML::Debug;
    $cmd=~s/\%s/$sgmls/g;
    $cmd=~s/\%o/$sgmlsopts/g;
    $cmd=~s/\%d/$doctype/g;
    $cmd=~s/\%f/-/g;
    warn "[r $cmd]\n" if $Treex::PML::Debug;
    no integer;

    {
      my $err = File::Temp->new(UNLINK => 1);
      $err->autoflush(1);
      open my $olderr, ">&", \*STDERR or die "Can't dup STDERR: $!";
      open STDERR, ">&", $err or die "Can't dup temporary filehandle as STDERR: $!";
      eval {
	$fh = set_encoding(Treex::PML::IO::open_pipe($filename,'r',$cmd),$csts_encoding);
	binmode $fh,':crlf' if $fh and $^O eq 'MSWin32';
      };
      close(STDERR);
      open STDERR, ">&", $olderr or die "Can't dup old STDERR: $!";
      if ($@) {
	close $err;
	die $@;
      }
      $stderr_pool{$fh} = $err;
      return $fh;
    }
  } else {
    die "unknown mode $mode\n";
  }
}

sub close_backend {
  my ($fh)=@_;
  if (exists $stderr_pool{$fh}) {
    my $err = delete $stderr_pool{$fh};
    seek($err,0,SEEK_SET);
    local $/;
    my $warnings = <$err>;
    close($err);
    if (defined $warnings and length $warnings) {
      warn $warnings;
    }
  }
  unless (Treex::PML::IO::close_backend($fh)) {
    die "$sgmls ended with error code $?\n";
  }
  return 1;
}

sub read {
  Treex::PML::Backend::CSTS::Csts2fs::read(@_);
}

sub write {
  Treex::PML::Backend::CSTS::Fs2csts::write(@_);
}

sub test_nsgmls {
  return 1 if (-x $sgmls);
  foreach (split(($^O eq 'MSWin32' ? ';' : ':'),$ENV{PATH})) {
    if (-x "$_".($^O eq 'MSWin32' ? "\\" : "/")."$sgmls") {
      unless (-f $doctype) {
	warn("CSTS doctype not found: $doctype\n") if $Treex::PML::Debug;
	return 0;
      }
      return 1;
    }
  }
  warn("nsgmls not found at $sgmls\n") if $Treex::PML::Debug;
  return 0;
}

sub test {
  my ($f,$encoding)=@_;

  return 0 unless test_nsgmls();
  if (ref($f)) {
    my $line=$f->getline();
    return $line=~/^\s*<csts[ >]|^<!DOCTYPE csts/;
  } else {
    my $fh = Treex::PML::IO::open_backend($f,"r");
    my $test = $fh && test($fh);
    Treex::PML::IO::close_backend($fh);
    return $test;
  }
}

BEGIN {
  default_settings();
}

1;
__END__

=head1 NAME

Treex::PML::Backend::CSTS - I/O backend for PDT 1.0 CSTS documents

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend for a legacy
SGML-based format called CSTS used in the Prague Dependency Treebank
1.0.

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(CSTS))

my $document = Treex::PML::Factory->createDocumentFromFile('input.csts');
...
$document->save();

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
