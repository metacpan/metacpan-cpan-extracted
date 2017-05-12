package LEOCHARRE::FontFind;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA @FONTPATH $CACHE $_files_found_in_fontpaths);
use Exporter;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;
# setting manually, no longer access to cvs
@ISA = qw/Exporter/;
@EXPORT_OK = qw(find_ttf find_ttfs);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
@FONTPATH = ('/usr/share/fonts');
use Cache::File;
#use Smart::Comments;

sub find_ttfs { # return whole list..
   my $substring = shift;
  
   if( my @extra_FONTPATHS = @_ ){
      push @FONTPATH, @extra_FONTPATHS;
      _cache_reset();
   } 

   my @ttfs =  _abs_ttfs();
   my $ac = scalar @ttfs or warn("no ttf files at all") and return;
   
   ### ttf cached: $ac
   ## cached are: @ttfs

   my @found;
   if( $substring=~/\.ttf$/i){ 
      ### then assume whole filename
      @found = grep { /\Q$substring\E$/i } @ttfs;
   }
   else {
      ### regular substring: $substring
      @found = grep { /\Q$substring\E[^\/]*\.ttf$/i} @ttfs;
   }


   # sort by filename...
   my %filename;
   map { $_=~/([^\/]+)$/; $filename{$_} = $1 } @found;

   @found = sort { $filename{$a} cmp $filename{$b} } @found;

   ### grepped to: @found
   @found or return;
   @found; # return all
}

sub find_ttf {
   my $substring = shift;
   my @found = find_ttfs($substring,@_) or return;
   $found[0];
}



sub _cache {   
   $CACHE ||= Cache::File->new( cache_root => "$ENV{HOME}/.fontfind/cache" ) or die;  
}
sub _cache_reset { _cache()->clear('_files_found_in_fontpaths') }

sub _files_found_in_fontpaths { # can be all files. . later we worry about 
   # grepping ttf, or whatever extension/name
   
   # did we already figure it out?
   defined $_files_found_in_fontpaths and return $_files_found_in_fontpaths;
   
   # is it cached ?
   if( $_files_found_in_fontpaths = _cache()->thaw('_files_found_in_fontpaths') ){
      return    $_files_found_in_fontpaths;
   }
   
   ### finding fonts..
   
   # go ahead and find all files
   my @found;   # as is.. will not prevent dupes. . don't streamline early..
   for (@FONTPATH){
      push @found, (split(/\n/, `find '$_' -type f`));
   }
   _cache()->freeze('_files_found_in_fontpaths' => \@found, 'never' );

   $_files_found_in_fontpaths = [@found]; # or \@found ? .. may cause problems?


   my $files_found = scalar @found;
   ### $files_found

   return $_files_found_in_fontpaths;
}

sub _abs_ttfs { ( grep { /[^\/]+.ttf$/i } @{_files_found_in_fontpaths()} ) }



1;











1;

__END__

=pod

=head1 NAME

=head1 SYNOPSIS

   my $fontname = 'Arial';

   find_ttf( $fontname);

   my $fontdir  = '/home/myself/fonts';
   my $fontdir2 = '/home/myself/.fonts';
   
   push @LEOCHARRE::FontFind::PATH, $fontdir, $fontdir2;
   
   LEOCHARRE::FontFind::_cache_reset();   

   my $abs_font = find_ttf( $fontname, $fontdir, $fontdir2 );

   
=head1 DESCRIPTION

Why?

Because I was rendering text with imagemagick, and what was taking 3 seconds each time was 
looking up for fonts. This makes it immediate.

=head1 CAVEATS

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


