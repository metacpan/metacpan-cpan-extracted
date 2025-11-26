#!/usr/bin/env perl

use v5.30;
use warnings;

my $wgpun  = 'wgpu_native';
my $repo   = 'https://github.com/gfx-rs/wgpu-native';
my $dnld   = '/releases/download';
my %os_lut = (
  linux   => 'linux',
  MSWin32 => 'windows',
  darwin  => 'macos',
);
my $os = $os_lut{$^O};

if ($os)
{
  my $version = do { open my $fh, '<', 'webgpu-version'; <$fh> };
  chomp $version;

  require Config;
  my $archname = $Config::Config{archname};
  my $isx86    = $archname =~ m/(x86_64|amd64|i.86|-x64-)/ ? 1 : 0;
  my $isarm    = $archname =~ m/(aarch64|arm64)/ ? 1 : 0;
  my $bits64   = $Config::Config{ptrsize} == 8;

  if ( $isx86 || ( $isarm && $bits64 ) )
  {
    my $download;

    my $ans = prompt( "WebGPU library was not found, would you like to try and download $wgpun?", 'n' );
    if ( $ans =~ m/^([YNn])/ )
    {
      $download = ( $1 eq 'Y' );
    }
    else
    {
      die "Please answer with Y or n\n";
    }

    if ($download)
    {
      # Determine the release name
      my $arch
          = $isarm  ? 'aarch64'
          : $bits64 ? 'x86_64'
          :           'i686';

      if ( $os eq 'windows' )
      {
        $arch .= '-msvc';
      }

      my $url = "$repo/$dnld/$version/wgpu-$os-$arch-release.zip";

      require File::Fetch;
      require File::Spec;
      require File::Temp;
      require File::Path;
      require IO::Uncompress::Unzip;

      my $ff = File::Fetch->new( uri => $url );
      $ff->scheme('http')
          if $ff->scheme eq 'https';

      my $template = File::Spec->catdir( File::Spec->tmpdir, 'WebGPU-Direct-XXXXXXXX' );
      my $tmpdir   = File::Temp->newdir( TEMPLATE => $template );
      my $from = $ff->fetch( to => $tmpdir );

      die "Could not download $url\n"
        if !$from;

      my $to   = File::Temp->newdir( TEMPLATE => 'webgpu-XXXXXX', CLEANUP => 0 );

      unzip( $from => $to );
      my $addl_search = File::Spec->catdir( $to, 'include', 'webgpu' );
      return ( $wgpun, $addl_search );
      die $url;
    }
  }
}

sub unzip
{
  my $from = shift;
  my $to   = shift;

  use autodie qw/open read write/;

  my $z = IO::Uncompress::Unzip->new($from)
      or die "Cannot open $from: $IO::Uncompress::Unzip::UnzipError";

FILE:
  while ( my $status = $z->nextStream() )
  {
    die "Error processing $from: $!\n"
        if $status < 0;

    my $header = $z->getHeaderInfo;
    my $name   = $header->{Name};
    my $path   = "$to/$name";

    die "Unexpected file name, cannot include '..': $name"
        if $path =~ m/[.][.]/xms;

    next FILE
        if $path =~ m{[/\\]$}xms;

    warn "Processing member $name\n";
    my ( undef, $dir, $file ) = File::Spec->splitpath($path);

    if ( !-d $dir )
    {
      File::Path::make_path($dir);
    }

    my $catpath = File::Spec->catdir( $dir, $file );

    die "Existing file found during expansion: $path"
        if -e $catpath;

    open my $fh, '>', $catpath;
    $fh->binmode;

    my $buf;
    while ( read $z, $buf, 4096 )
    {
      print $fh $buf;
    }
  }
}
