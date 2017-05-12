package WWW::Link::Repair;
$REVISION=q$Revision: 1.11 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

Repair.pm - repair links in files.

=head1 SYNOPSIS

    use Repair::Substitutor;
    use Repair;

    $linksubs1 = WWW::Link::Repair::Substitutor::gen_substitutor(
       "http://bounce.com/" ,
       "http://bing.bong/",
       0, 0,
      );
    $filehand = WWW::Link::Repair::Substitutor::gen_simple_file_handler ($linksubs);

    &$filehand("fix-this-file");

    use CDB_File::BiIndex;
    $::index = new CDB_File::BiIndex "page-index-file", "link-index-file";

    WWW::Link::Repair::infostructure($index, $filehand, "http://bounce.com/");


=head1 DESCRIPTION

This module provides functions that allow the repair of files.

=cut

our ($fakeit);
our ($verbose);
our ($no_warn);

$fakeit = 0 unless defined $fakeit;
$verbose = 0 unless defined $verbose;
$no_warn = 0 unless defined $no_warn;

use File::Copy;
use Carp;
use strict;

=head2 directory(file handler, directory ... )

This function recurses through each given directory argument.  For
each file found it calls the file handler function.

The B<file handler> should be a function which can be called on a
filename and will update that file with the new URL.

B<oldurl> is the base URL which should be iterated from.  It must
exist within the B<index>.

B<as_directory> controlls whether to attempt to replace all links
below that link.  In this case the index is iterated beyond the first
link for all links which begin with the first link.

=cut

sub directory {
  my $handler=shift;
  our ($fixed);
  local $fixed;
  $fixed=0;
  my $sub = sub {-d && return 0; $fixed += &$handler($File::Find::name)};
  File::Find::find($sub, @_);
  return $fixed;
}

=head2 infostructure(index object, file handler, oldurl, as_directory)

This function will use a previously build index to update all of the
files referenced from that index that need updating.

The B<index> object will be treated as a BiIndex.

The B<file handler> should be a function which can be called on a
filename and will update that file with the new URL.

B<oldurl> is the base URL which should be iterated from.  It must
exist within the B<index>.

B<as_directory> controlls whether to attempt to replace all links
below that link.  In this case the index is iterated beyond the first
link for all links which begin with the first link.

=cut

use vars qw($infostrucbase $filebase);

sub _link_fix($$$) {
  my $url_to_file=shift;
  my $file_handler=shift;
  my $editlist=shift;
  my $fixed=0;
 PAGE: foreach my $member (@$editlist) {
    print STDERR "going to convert $member to file\n"
      if $WWW::Link::Repair::verbose & 32;
    my $file = &$url_to_file($member);
    defined $file or do {
      print STDERR "No filename for $member.  Skipping\n";
      next PAGE;
    };
    print STDERR "file is $file\n" if $WWW::Link::Repair::verbose & 32;
    $fixed+=&$file_handler($file);
  }
  return $fixed;
}


sub infostructure ($$$$;$) {
  my ($oldurl, $index, $url_to_file, $file_handler, $recursive, $junk)=@_;

  defined $file_handler or 
    croak "missing argument to infostructure(\$\$\$\$;\$)";
  $oldurl =~ m/^[a-z][a-z0-9-]*:/ or
    croak "first argument to infostructure() must be a url not $oldurl";
  ref $index and $index->can("lookup_second") or
    croak "second argument to infostructure() must be a biindex not $index";
  (ref $url_to_file) =~ m/CODE/ or
    croak "third argument to infostructure() must be a CODE ref not $url_to_file";
  (ref $file_handler) =~ m/CODE/ or
    croak "fourth argument to infostructure() must be a CODE ref not $url_to_file";
  defined $junk and croak "extra argument to infostructure(\$\$\$\$;\$)";

  my $key=$index->second_set_iterate($oldurl);
  my $fixed=0;

  if (defined $key) {
    if ($recursive) {		#we should substitute all links below this
      while (defined $key and $key =~ m/^$oldurl/) {
	my $editlist=$index->lookup_second($key);
	$fixed += _link_fix($url_to_file,$file_handler,$editlist);
	$key = $index->second_next();
      }
    } else {			#just warn if there are any links below this.
      my $next;
      if ( $key =~ m/^$oldurl/ and not $key eq $oldurl ) {
	warn "There were no files with exactly that link to edit.\n";
	last;
      } else {
	my $editlist=$index->lookup_second($oldurl);
	$fixed += _link_fix($url_to_file,$file_handler,$editlist);
	$key=$index->second_next();
      }
      warn "Ignoring URLs starting with your URL such as $key.\n"
	if defined $key and $key =~ m/^$oldurl/;
    }
  } else {
    warn "There were no files with exactly that link to edit.\n";
    print STDERR "key was beyond all keys in index\n"
      if $WWW::Link::Repair::verbose & 16;
  }

  $fixed or carp "didn't make any substitutions for $oldurl" unless $no_warn;
  #FIXME repair the infostructure index..
  return $fixed;
}

#  =head2 map_url_to_editable

#  Given any url, get us something we can edit in order to change the
#  resource referenced by that url.  Or not, if we can't.  In the case
#  that we can't, return undef.

#  The aim of this function is to return something which is not tainted.

#  N.B.  This will accept any filename which is within the infostructure
#  whatsoever.. it is possible that that includes more than you wish to
#  let people edit.

#  For this function to work the two variables:

#    $WWW::Link::Repair::filebase
#    $WWW::Link::Repair::infostrucbase

#  must be defined appropriately

#  =cut

#  # sub{}

#  # @conversions = [
#  #   { regexp => 'http:://stuff..../'
#  #     changeurlfunc => sub {

#  #     }

#  # ]

#  sub map_url_to_editable ($) {
#    my $save=$_;
#    $_=shift;
#    print STDERR "trying to map $_ to editable object\n"
#      if $WWW::Link::Repair::verbose & 64;

#    unless (m/^$infostrucbase/) {
#      my $print=$_;
#      $_=$save;
#      croak "can't deal with url '$print' not in our infostructure"; #taint??
#    }
#    die 'config variable $WWW::Link::Repair::infostrucbase must be defined'
#      unless defined $infostrucbase;
#    s/^$infostrucbase//;

#    # Now we clean up the filename.  For This we assume unix semantics.
#    # These have been around for long enough that any sensible operating
#    # system could have simply copied them.

#    s,/./,,g;

#    #now chop away down references..

#    # substitute a downchange (dirname/) followed by an upchange ( /../ )
#    # for nothing.
#    1 while s,([^.]|(.[^.])|(..?))/+..($|/),,g ;

#    # clean up multiple slashes

#    s,//,/,g;

#    # delete leading slash

#    s,^/,,g;


#    if (m,(^|/)..($|/),) {
#      $_=$save;
#      croak "upreferences (/../) put that outside our infostructure";
#    }

#    #what are the properties of the filename we can return..
#    #any string which doesn't contain /.. (and refuse /.

#    #now we untaint and do a check..

#    $_ =~ m,( (?:             # directory name; xxx/ or filename; xxx
#  	         (?:                # some filename ....
#  	           (?:[^./][^/]+)              #a filename with no dot
#  	          |(?:.[^./][^/]+)             #a filename starting with .
#  	          |(?:..[^./][^/]+)            #a filename starting with .. why bother?
#  	         )
#  	         (?:/|$)           # seperator to next directory name or end of filename
#  	      ) +
#  	    ),x; #we set $1 to the whole qualified filename.

#    my $fixable = $1;
#    $_=$save;
#    return undef unless defined $fixable;
#    die 'config variable $WWW::Link::Repair::filebase must be defined'
#      unless defined $filebase;
#    #FIXME: filebase can contain a / so this can end up with //. do we care?
#    return $filebase . '/' . $fixable; #filebase should be an internal variable
#  }


=head1 check_url_is_full

The aim of this function is to check whether a given url is full

=cut


sub check_url ($) {
  my $fixable=shift;
 FIXABLE: foreach (@$fixable) {
    m,^[A-Za-z]+://^[A-Za-z]+/, or die "unqualified URL in database $_";
  }
}

1; #why are we all afraid of require?  Why do we give in??
