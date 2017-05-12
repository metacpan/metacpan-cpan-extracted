package WWW::BrokenLinks;

use 5.014;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use WWW::Mechanize;
use URI;

use Text::CSV;

use IO::Handle;

our $VERSION = '0.04';

has 'base_url' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'debug' => (
  is => 'ro',
  isa => 'Bool',
  required => 0,
  default => 0,
);

has 'request_gap' => (
  is => 'ro',
  isa => 'Int',
  required => 0,
  default => 1,
);

has 'output_file' => (
  is => 'ro',
  isa => 'Str',
  required => 0,
);

has 'excluded_urls' => (
  traits => ['Array'],
  is => 'ro',
  isa => 'ArrayRef[Str]',
  required => 0,
  default => sub { [] },
  handles => {
    all_excluded_urls => 'elements',
  },
);

sub crawl
{
  my $self = shift;
  my @crawl_queue = ();
  my %scanned_urls = ();
  my %broken_urls = ();
  my $output_fh;
  my @excluded_urls = $self->all_excluded_urls();
  
  # Open either the specified output file for writing.
  if ($self->output_file)
  {
    open $output_fh, '>', $self->output_file or die $self->output_file . ": $!";
  }
  else
  {
    die "No output file specified\n";
  }
  
  # Automatically flush STDOUT, otherwise we cannot monitor progress
  STDOUT->autoflush(1);
  
  my %csv_options = (
    'always_quote' => 1,
    'binary' => 1,
    'eol' => "\n",
  );
  
  my $csv = Text::CSV->new(\%csv_options) or die 'Cannot use CSV: ' . Text::CSV->error_diag();
  
  # CSV headers
  $csv->print($output_fh, ['Error', 'Type', 'Source URL', 'Destination URL']);
  
  # Don't take action when errors occur, otherwise encountering a broken
  # link will cause the script to exit
  my $mech = WWW::Mechanize->new(onerror => undef);
  
  my $current_url = $self->base_url;
  $scanned_urls{$current_url} = 1;
  
  while ($current_url)
  {
    if ($self->debug) { print "Checking URL: $current_url\n"; }
  
    my $response = $mech->get($current_url);
    sleep $self->request_gap;
    
    my @links = $mech->links();
    my @images = $mech->images();
    
    for my $link (@links)
    {
      my $abs_url = URI->new_abs($link->url, $current_url)->canonical;
      
      # Remove the fragment of the URL
      $abs_url->fragment(undef);
      
      # Only check http(s) links - ignore mailto, javascript etc.
      # Do not check URLs which we have previously scanned
      if (($abs_url->scheme eq 'http' || $abs_url->scheme eq 'https') && !exists($scanned_urls{$abs_url}) && (!exists($broken_urls{$abs_url}) || $broken_urls{$abs_url} < 10))
      {
        if ($self->debug) { print "\tChecking link URL: $abs_url\n"; }
        
        my $is_excluded = 0;
        
        foreach my $excluded_url (@excluded_urls)
        {
          if (index($abs_url, $excluded_url) == 0)
          {
            $is_excluded = 1;
            if ($self->debug) { print "\tMatched URL: $excluded_url\n"; }
            last;
          }
        }
        
        if (!$is_excluded)
        {
          # Issue a HEAD request initially, as we don't care about the body at this point
          $response = $mech->head($abs_url);
          sleep $self->request_gap;
        
          my $final_url = $response->request()->uri();
   
          if ($response->is_success)
          {
            if (index($final_url, $self->base_url) != -1 && $response->content_type eq 'text/html' && !exists($scanned_urls{$abs_url}) && !exists($scanned_urls{$final_url}))
            {
              # Local link which we haven't checked, so add to the crawl queue
              push(@crawl_queue, $final_url);
          
              if ($self->debug) { print "\tQueued link URL: $abs_url\n"; }
            }
            else
            {
              if ($self->debug) { print "\tSkipping link URL: $abs_url\n"; }
            }
        
            # Always mark a successful URL as scanned, even if it is not local
            $scanned_urls{$abs_url} = 1;
            $scanned_urls{$final_url} = 1;
          }
          else
          { 
            # Increment broken list entry for this URL, or set to 1 if this is the
            # first time we have seen it
            if (exists($broken_urls{$abs_url}))
            {
              $broken_urls{$abs_url} += 1;
            }
            else
            {
              $broken_urls{$abs_url} = 1;
            }
          
            if ($self->debug) { print "\tBroken link URL: $abs_url\n"; }
          
            $csv->print($output_fh, [$response->status_line, 'Broken Link', $current_url, $abs_url]);
          }
        }
        else
        {
          if ($self->debug) { print "\tExcluded URL: $abs_url\n"; }
        }
      }
      else
      {
        if ($self->debug) { print "\tSkipping link URL: $abs_url\n"; }
      }
    }
    
    for my $image (@images)
    {
      my $abs_url = URI->new_abs($image->url, $current_url)->canonical;
      
      # Only check http(s) images.
      # Do not check URLs which we have previously scanned
      if (($abs_url->scheme eq 'http' || $abs_url->scheme eq 'https') && !exists($scanned_urls{$abs_url}))
      {
        if ($self->debug) { print "\tChecking image URL: $abs_url\n"; }
      
        # Issue a HEAD request initially, as we don't care about the body at this point
        $response = $mech->head($abs_url);
        sleep $self->request_gap;
        
        $abs_url = $response->request()->uri();
        
        if ($response->is_success)
        {
          # We've checked this image, so no need to fetch it again
          $scanned_urls{$abs_url} = 1;
        }
        else
        {
          if ($self->debug) { print "\tBroken image URL: $abs_url\n"; }
        
          $csv->print($output_fh, [$response->status_line, 'Broken image', $current_url, $abs_url]);
        }
      }
    }
    
    $current_url = pop(@crawl_queue);
  }
  
  close $output_fh or die "Could not close output file: $!";
}

__PACKAGE__->meta->make_immutable;

1; # Magic true value required at end of module

=pod

=encoding UTF-8

=head1 NAME

WWW::BrokenLinks - Finds broken links (including images) on a website.

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This module crawls a given website for broken links, including
images, and outputs a report in CSV format.

The following functions are provided:

=over

=item new(\%options)

Provided automatically by Moose, thsi is the constructor for the class.

The following parameters can be provided as a hash reference.

=over

=item C<base_url> (required): The base URL to crawl. The module will not crawl above the depth specified.

=item C<debug> (optional): Set to 1 to enable debugging messages (off by default).

=item C<request_gap> (optional): Number of seconds to wait between requests. Defaults to 1 second.

=item C<output_file> (required): Path to file where report shoud be saved.

=item C<excluded_urls> (optional): Array reference of URLs to excluded. Defaults to an empty array.

=back

=item crawl()

Crawl the given website for broken links.

=back

=head1 DEPENDENCIES

Perl 5.14 or later is required. This module may work with earlier versions
of Perl, but this is neither tested nor supported.

=head1 AUTHOR

Paul Waring <paul.waring@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by University of Manchester.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

__END__

# ABSTRACT: Finds broken links (including images) on a website.

==head1 SYNOPSIS

  use WWW::BrokenLinks;
  
  my %options = (
    'base_url' => 'http://www.example.org',
    'debug' => 0,
    'request_gap' => 3,
    'output_file' => 'output.csv',
  );
  
  my $bl = WWW::BrokenLinks->new(\%options);
  $bl->crawl();

