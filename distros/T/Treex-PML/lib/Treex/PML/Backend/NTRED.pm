package Treex::PML::Backend::NTRED;
use Treex::PML;
use Storable qw(nfreeze thaw);
use MIME::Base64;
use Treex::PML::IO;
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.26'; # version template
}

use vars qw($ntred);


$ntred='ntred';

sub test {
  my ($filename,$encoding)=@_;
  return $filename=~m(^ntred://);
}

sub open_backend {
  my ($filename, $mode, $encoding)=@_;
  my $fh = undef;
  my $cmd = "";
  return unless $filename=~m(^ntred://(.*)$);
  $filename=$1;
  $filename=~s/@/##/;
  if ($filename) {
    if ($mode eq 'w') {
      open($fh,'|-',$ntred, '-Q', '--upload-file', $filename) || die "Failed to start NTrEd Client '$ntred': $!\n";
    } else {
      open($fh,'-|',$ntred, '-Q', '--dump-files', $filename) || die "Failed NTrEd Client '$ntred': $!\n";
    }
  }
  return Treex::PML::IO::set_encoding($fh,$encoding);
}

sub close_backend {
  my ($fh)=@_;
  return $fh && $fh->close();
}

sub read {
  my ($fd,$fs)=@_;
  my $data = do{{ local $/; <$fd>}};
  unless (defined $data and length $data) {
    die "NTrEd Client returned no data\n";
  }
  my $fs_files = Storable::thaw(decode_base64($data));
  undef $data;
  my $restore = $fs_files->[0];
  if (ref($restore)) {
    my $api_version = $restore->[6];
    if ($api_version ne $Treex::PML::API_VERSION) {
      warn "Warning: the binary content obtained via Treex::PML::Backend::NTRED from ".$fs->filename." is a dump of structures created by possibly incompatible Treex::PML API version $api_version (the current Treex::PML API version is $Treex::PML::API_VERSION)\n";
    }
    $fs->changeFS($restore->[0]);
    $fs->changeTrees(@{$restore->[1]});
    $fs->changeTail(@{$restore->[2]});
    $fs->[13]=$restore->[3]; # metaData
    $fs->changePatterns(@{$restore->[4]});
    $fs->changeHint($restore->[5]);
    $fs->FS->renew_specials();
  }
}



sub write {
  my ($fh,$fsfile)=@_;
  my $dump= [$fsfile->FS,
	     $fsfile->treeList,
	     [$fsfile->tail],
	     $fsfile->[13], # metaData
	     [$fsfile->patterns],
	     $fsfile->hint,
	     $Treex::PML::API_VERSION
	     # CAUTION: when adding to this list, don't forget to do the same
	     # in btred DUMP request handler
	    ];
  eval {
    print $fh (encode_base64(Storable::nfreeze([$dump])));
    print $fh ("\n");
  };
}

1;
__END__

=pod

=head1 NAME

Treex::PML::Backend::NTRED - Treex::PML I/O backend for exchanging data with remote ntred servers.

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(NTRED))

my $document = Treex::PML::Factory->createDocumentFromFile('ntred:///some/file');
...
$document->save();

my $doc_frag = Treex::PML::Factory->createDocumentFromFile('ntred:///some/file@10');
...
$doc_frag->save();

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend which
exchanges data with remote ntred servers. It uses the external
C<ntred> command-line client to communicate to the servers.

The backend accepts any document whose URL is of the form

  ntred:///some/file

or

  ntred:///some/file@N

where C<N> is an integer. In first form can be used to retrieve/save
back a document whose local name C</some/file> from the in memory of
an ntred server.  The later form can be used to retrieve a partial
document containing only the Nth tree (the index is 0-based) of the
specified document. When this partial document is saved back, the Nth
tree in the in-memory representation of the document on the server is
updated, leaving other trees intact.

=head2 SEE ALSO

TrEd toolkit (L<http://ufal.mff.cuni.cz/tred>)

=head2 REFERENCE

=over 4

=item $Treex::PML::Backend::NTRED::ntred

This variable may be used to set-up the path to 'ntred' client program.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
