package WWW::SFDC::Zip;
# ABSTRACT: Utilities for manipulating base64 encoded zip files.

use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use Data::Dumper;
use File::Path qw(mkpath);
use File::Spec::Functions qw(splitpath);
use IO::Compress::Zip qw{$ZipError zip :constants};
use IO::File;
use IO::Uncompress::Unzip qw($UnzipError);
use Log::Log4perl ':easy';
use MIME::Base64;


BEGIN {
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw(unzip makezip);
}


sub unzip {
  # you need to understand IO::Uncompress::unzip
  # for this function
  my ($dest, $data, $callback) = @_;
  INFO "Unzipping files to $dest";
  TRACE "Data to unzip" => $data;
  LOGDIE "No destination!" unless $dest;

  # Ensure $dest ends with a /
  $dest =~ s{(?<![/\\])$}{/};

  $data = decode_base64 $data;
  my $unzipper = IO::Uncompress::Unzip->new(\$data)
    or LOGDIE "Couldn't unzip data";

  my $status;

  for ($status = 1; $status > 0; $status = $unzipper->nextStream()) {
    my $header = $unzipper->getHeaderInfo();
    my (undef, $folder, $name) = splitpath($header->{Name});

    $folder =~ s{unpackaged/}{};
    $folder = $dest.$folder;

    # create folder on disk unless it exists already
    mkpath($folder) or LOGDIE "Couldn't mkdir $folder: $!" unless -d $folder;

    # skip if the file is a folder, exit on error
    $status < 0 ? last : next if $name =~ /\/$/;

    # read content into memory
    my $buffer;
    my $content;
    $content .= $buffer while ($status = $unzipper->read($buffer)) > 0;
    my $path = "$folder/$name";

    # use callback, if defined
    $content = $callback->($path, $content) if $callback;

    if ($content) {
      # open target for writing
      my $fh = IO::File->new($path, "w") or LOGDIE "Couldn't write to $path: $!";
      $fh->binmode();
      $fh->write($content);
      $fh->close();
      # update time on target
      my $stored_time = $header->{'Time'};
      utime ($stored_time, $stored_time, $path) or LOGDIE "Couldn't touch $path: $!";
    }
  };

  return "Success";
}


sub makezip {
  my ($baseDir, @files) = @_;

  TRACE "File list before grep: " . Dumper \@files;
  LOGDIE "It is invalid to call makezip with no files." unless scalar @files;

  $baseDir =~ s{(?<![/\\])$}{/};

  chomp @files;

  @files = grep {-e $_ && !-d $_}
    map {s/^(?!$baseDir)/$baseDir/r}
    @files;

  DEBUG "File list for zipping: " . Dumper \@files;
  INFO "Writing zip file with ". scalar(@files) ." files";

  my $result;

  zip
    \@files => \$result,
    FilterName => sub { s/$baseDir// if $baseDir; },
    Level => 9,
    Minimal => 1,
    BinModeIn => 1,
    or LOGDIE "zip failed: $ZipError";

  eval {
    open my $FH, '>', 'data_perl.zip' or die;
    binmode $FH;
    print $FH $result;
    close $FH;
  };

  return encode_base64 $result;
}

1;

__END__

=pod

=head1 NAME

WWW::SFDC::Zip - Utilities for manipulating base64 encoded zip files.

=head1 VERSION

version 0.37

=head1 SYNOPSIS

    use WWW::SFDC::Zip qw"unzip makezip";

    makezip $srcDirectory, @listOfFiles;

    unzip $destDirectory, $base64encodedzipfile, &unzipTimeChanges;

=head1 FUNCTIONS

=head2 unzip $destFolder, $dataString, $callback

Takes a some base64 $data and turns it into a file tree, starting at $dest. It
does this by turning unpackaged/ into $dest/ whilst unzipping, so the data
needs to come from an above-defined retrieve request.

Whilst each file is in memory, this function calls:

 $callback->($filename, $content)

In this way, you can use $calback to modify or remove files before
they get written to disk.

=head2 makezip \%options, @fileList

Creates and returns a zip stream from the file list
given. Replaces unpackaged/ with $options{basedir} if set.

=head1 EXPORT

Can export unzip and makezip.

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/sophos/WWW-SFDC/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::SFDC::Zip

You can also look for information at L<https://github.com/sophos/WWW-SFDC>

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
