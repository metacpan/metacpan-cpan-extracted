#!/usr/bin/perl
# WWW::ImageSpool by Tyler MacDonald <tyler@yi.org> 2004-05-15

=pod

=head1 NAME imagespoold.pl - Periodically download images from the web



=head1 SYNOPSIS

	imagespoold.pl --dir=spool_directory
	 [--dictionary=dictionary_file]
	 [--verbose[=0-4]]
	 [--max=bytes]
	 [--minx=x] [--miny=y]
	 [--limit=limit] [--searchlimit=limit]
	 [--consume | --no-consume]
	 [--sleep=seconds] [--run=seconds]

=head1 EXAMPLE

	imagespoold.pl --dir=/var/cache/imagespool
	 --dictionary=/home/bob/favourite_things.txt
	 --verbose=1 --max=104857600
	 --minx=320 --miny=240 
	 --sleep=30 > /home/bob/imagespoold.log
	 2>&1 &

=head1 DESCRIPTION

imagespoold.pl will downloaded images from the internet into the directory specified by the
--dir argument, using random words as search keywords, picked from the dictionary file
specified by --dictionary (or /usr/share/dict/words if one is not specified).

=head1 OPTIONS

Most of the options directly correspond to options to the WWW::ImageSpool perl object.
Please see it's documentation for a description of those. There are also two additional options:
	
=over

=item --sleep=I<seconds>

How many seconds to wait between iterations.
	
=item --run=I<seconds>

Terminate after this many seconds. This is useful for, among other things, rotating dictionary files periodically.

=back

=head1 NOTE

This module may violate the terms of service of some search engines or content
providers. Use at your own risk.

=head1 LICENSE

Copyright 2004, Tyler "Crackerjack" MacDonald <tyler@yi.org>
This is free software; you may redistribute it under the same terms as perl itself.

=cut

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use WWW::ImageSpool;

my %opts = (sleep => 10, run => 0);

GetOptions(\%opts, "dir=s", "minx=i", "miny=i", "limit=i", "consume!", "verbose:i", "searchlimit=i", "dictionary=s", "max=i", "sleep=i", "run=i");

if(defined($opts{verbose}) && $opts{verbose} == 0)
{
 $opts{verbose} = 1;
}

if(my $spool = WWW::ImageSpool->new(%opts))
{
 my $run = 1;
 while($run)
 {
  $spool->run;
  sleep($opts{sleep});
  if($opts{run} > 0)
  {
   if($spool->uptime > $opts{run})
   {
    $run = 0;
   }
  }
 }
}
