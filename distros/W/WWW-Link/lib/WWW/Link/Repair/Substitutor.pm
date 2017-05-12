package WWW::Link::Repair::Substitutor;
$REVISION=q$Revision: 1.12 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME

WWW::Link::Repair::Substitutor - repair links by text substitution

=head1 SYNOPSIS

    use WWW::Link::Repair::Substitutor;
    $dirsubs = WWW::Link::Repair::Substitutor::gen_substitutor
       ( "http://bounce.bounce.com/frodo/dogo" ,
         "http://thing.thong/ding/dong",
          1, 0,  ); #directory substitution don't replace subsidiary links
    &$dirsubs ($line_from_file)

=head1 DESCRIPTION

A module for substituting one link in a file for another.

This link repairer works by going through a file line by line and
doing a substitute on each line.  It will substitute absolute links
all of the time, including within the text of the HTML page.  This is
useful because it means that things like instructions to people about
what to do with URLs will be corrected.

=head1 SUBSTITUTORS

A substituter is a function which substitutes one url for another in a
string.  Typically it would be fed a file a line at a time and would
substitute it directly.  It works on it's argument directly.

The two urls should be provided in absolute form.

=head2 FILE HANDLERS

A file handler goes through files calling a substitutor as needed.

=head2 gen_directory_substitutor

B<Warning>: I think the logic around here is more than a little dubious

=cut

use Carp;
use File::Copy;
use strict;
use URI;

our ($verbose);
$verbose=0 unless defined $verbose;

=head2 gen_substitutor

This function was previously an exported interface and currently
remains visible.  I think it's interface is likely to change though.
Preferably use generate_file_substitutor as an entry point instead.

This function generates a function which can be called either on a
complete line of text from a file or on a URL and which will update
the URL based on the URLs it has been given

If the third argument is true then the function will return a
substitutor which works on all of the links below a given url and
substitutes them all together.  Thus if we change

  http://fred.jim/eating/

to

  http://roger.jemima/food/eating-out/

we also change


  http://fred.jim/eating/hotels.html

to

  http://roger.jemima/food/eating-out/hotels.html

This function should handle fragments correctly.  This means that we
should allow fragments to be substituted to and from normal links, but
also when we fix a url to a url all of the internal fragments should
follow.  Fragments are not relative links.  Cases

=over 4

=item 1

substitution of fragment for fragment

=item 2

substitution of link for link

=item 3

substitution of link to fragment

=item 4

substitution of fragment to link

=item 5

substitution of url base for url base with all relative links

=back

Note that right now it isn't possible to substitute a tree under a
fragment.  There is no such thing as a sub-fragment defined in the
standards.

If we stubstitute a link to a fragment then we should not substitute
fragments under that link.  that would loose information.  Rather we
should issue a warning. Maybe there should be an option that lets this
happen.

=cut

#substitution of link for link - including tree mode (never has fragments)
#match url without fragment - fragment remains

#substitution of fragment for fragment
#match whole link

#substitution of link to link with fragment
#substitute whole link
#SHOULD MATCH BUT WARN IF WE FIND AN EXISTING FRAGMENT
#will fail to match and leave

#substitution of link with fragment to link
#match the whole link


#substitution of url base for url base with all relative links



sub gen_substitutor ($$;$$) {
  my ($orig_url,$new_url,$tree_mode,$baseuri) = @_;
  my ($new_has_fragment) = my ($orig_has_fragment ) =0;
  $orig_url =~ m/#/ and $orig_has_fragment =1;
  $new_url =~ m/#/ and $new_has_fragment =1;

  ( $orig_has_fragment or $new_has_fragment ) and $tree_mode
    and die "can't do tree mode substitution with fragments";

  print STDERR
    "Generating substitutor from $orig_url to $new_url \n",
    (defined $baseuri ? "using base $baseuri\n" : "" ) if ($verbose & 32);

  defined $baseuri and ( not $baseuri =~ m/^[a-z][a-z0-9]*:/ )
    and croak "baseuri must be absolute URI, not $baseuri";

  my $orig_rel;
  my $new_rel;
  defined $baseuri and do {
    my $orig_uri=URI->new($orig_url);
    my $new_uri=URI->new($new_url);
    $orig_rel=$orig_uri->rel($baseuri);
    $new_rel=$new_uri->rel($baseuri);
  };

  my $perlcode = <<'EOF';
    sub {
      my $substitutions=0;
EOF

  $perlcode .= <<'EOF' if ($verbose & 16);
      print STDERR "Subs in : $_[0]\n";
EOF

  $perlcode .= <<'EOF' if ($baseuri);
EOF

  my $restart = <<'EOF';
      $substitutions += $_[0] =~ s,( (?:^) #the start of a line
                  |(?:[^A-Za-z0-9]) #or a boundary character..
	         )
EOF

# $remiddle terminates the url to be replaced...  three possibilities
#
# 1) we are replacing a tree of URLs where the base URL is terminated with a /
#    => what happens after doesn't matter..   '
# 2) we are replacing a tree of URLs where the base URL is unterminated..
#    => end of the string must be end of the URL or '/' must follow
# 3) we only replace the exact URL
#    => end of the string must be end of the URL

  my $remiddle = '';

  unless ($orig_url=~ m,/$, and $tree_mode) {
    $remiddle  .= <<'EOF';

                 (?=(
EOF

#end_of_uri - ends at a fragment unless the first url is a fragment

    my $end_of_uri;
  CASE: {
      $tree_mode && do {
	$end_of_uri  = <<'EOF' ;
                     ([#"'/>]) #" either end or end of section
EOF
	last CASE;
      };
      ( not $orig_has_fragment and not $new_has_fragment ) && do {
	$end_of_uri  = <<'EOF' ;
                     ([#"'>]) #" this checks for the end of the url..
EOF
	last CASE;
      };
      do {
	$end_of_uri  = <<'EOF' ;
                     (["'>]) #" this checks for the end of the url..
EOF
	last CASE;
      };
      die "not reached";
    }

    $remiddle  .= $end_of_uri;

    $remiddle  .= <<'EOF' unless $orig_url=~ m,/$,;
		     |(\s)
		     |($)
EOF
    $remiddle  .= <<'EOF';
                    )
                 )
EOF

  }


  $remiddle .= '	        ,$1' ;

  my $reend = ",gxo;\n";
  my $relreend = ",gx;\n";

  #FIXME: url quoting into regex??

  $perlcode .= $restart . $orig_url . $remiddle . $new_url . $reend;
  if ($baseuri) {
    $perlcode .= $restart . $orig_rel . $remiddle . $new_rel . $relreend;
  }

  $perlcode .= <<'EOF' if ($verbose & 16);
      print STDERR "Gives   : $_[0]\n";
EOF

  $perlcode .= <<'EOF';
      return $substitutions;
    }
EOF
  print STDERR "creating substitutor function as follows\n",$perlcode, "\n"
    if ($verbose & 32);
  my $returnme=(eval $perlcode);
  if ($@) {
    chomp $@; # to get line no in message
    die "sub creation failed: $@";
  }
  return $returnme;
}

=head2 gen_file_substitutor(<original url>, <new url>, [args...])

This function returns a function which will act on a text file or
other file which can be treated as a text file and will carry out URL
substitutions within it.

The returned code reference should be called with a filename as an
argument, it will then replace all occurrences of original url with
new url.

There are various options to this which can be set by putting various
key value pairs in the call.

  fakeit - set to create a function which actually does nothing

  tree_mode - set to true to substitute also URLs which are "beneath"
	      original url

  keep_orig - set to false to inhibit creation of backup files

  relative - substitute also relative relative URLs which are equivalent
		     to original url (requires file_to_url)

  file_to_url - provide a function which can translate a given filename
                to a URL, so we can work out relative URLs for the current
                file.


so a call like

  $subs=gen_file_substitutor
             ("http://www.example.com/friendstuff/old",
              "http://www.example.com/friendstuff/new",
              relative => 1, tree_mode => 1;
              file_to_url => 
              sub { my $ret=shift;
		$ret =~ return s,/var/www/me,http://www.example.com/mystuff,;
		return $ret});

  &$subs("/var/www/me/index.html");
  &$subs("/var/www/me/friends.html");

should allow you to fix your web pages if your friend renames a whole
directory.

=head1 BUGS

One problem with directory substitutors is treatment of the two different urls

  http://fred.jim/eating/

and

  http://fred.jim/eating

Most of the time, the latter of the pair is really just a mistaken
reference to the earlier.  This is B<not> always true.  What is more,
where it is true, a user of LinkController will usually have changed
to the correct version.  For this reason, if gen_directory_substitutor
is passed the first form of a url, it will not substitute the second.
If passed the second, it will substitute the first.

We have to be fed whole URLs at a time.  If a url is split between two
different chunks then we may not handle it correctly.  Always feeding
in a complete line protects us from this because a URL cannot contain
an unencoded line break.

=cut


use vars qw($tmpdir $tmpref $tmpname $keeporig_default);
$tmpdir="/tmp/";
$tmpref="link_repair";
$tmpname="$tmpdir$tmpref" . "repair.$$";
$keeporig_default=1;

sub gen_file_substitutor ($$;%) {
  my $origurl=shift;
  my $finalurl=shift;
  my %settings=@_;

  my $tree_mode=$settings{tree_mode};
  my $relative=$settings{relative};
  my $file_to_url=$settings{file_to_url};
  my $keeporig=$settings{keeporig};
  my $fakeit=$settings{fakeit};

  $keeporig=$keeporig_default unless defined $keeporig;

  print STDERR "generating a file substitutor\n" if $verbose;
  $verbose & 32 and do {
    print STDERR <<EOF;
From: $origurl
To: $finalurl
Settings:-
EOF
print "keeporig: " . ( $keeporig ? $keeporig : "undef" )
  . " relative: " . ( $relative ? $relative : "undef" )
    . " file_to_url: " . ( $file_to_url ? $file_to_url : "undef" )
      . " fakeit: " . ( $fakeit ? $fakeit : "undef" ) . " \n";
  };

  my $subs;
  if ($relative) {
    $file_to_url
      or die "relative substitution needs a file_to_url translator"
  } else {
    $subs = gen_substitutor($origurl,$finalurl,$tree_mode);
  }

  return sub () {
    my $filename=shift;

    print STDERR "file handler called for $filename\n" if $verbose && 8;

    if ($relative) {
      my $baseuri=&$file_to_url($filename);
      print STDERR "URI for file $filename is $baseuri\n" if $verbose;
      $subs = gen_substitutor($origurl,$finalurl,$tree_mode, $baseuri);
    }

    my $fixed=0;

    die "file handler called with undefined values" unless defined $filename;
    -d $filename && return 0;
    -f $filename or do {warn "can't fix special file $filename"; return 0};

    if ($fakeit) {
      print STDERR "pretending to edit $filename\n";
      -W $filename or warn "file $filename can't be edited";
    } else {
      open (FIXFILE, "<$filename")
	or do { die "can't access $filename"; return 0};
      open (TMPFILE, ">$tmpname") or die "can't use tempfile $tmpname";
      while (<FIXFILE>) {
	$fixed += &$subs( $_);
	print TMPFILE $_;
      }
      close TMPFILE;
      close FIXFILE;
      #FIXME edit failure??    LOGME
      print STDERR "Changed links in file $filename\n"
	if $WWW::Link::Repair::verbose & 16;
      #I think this is the key bit of the program which needs to be SUID
      #and could even be separated out for more security.. <<EOSU
      rename($filename, $filename . ".orig") if $keeporig;
      copy($tmpname, $filename);
      #EOSU
      unlink $tmpname;		#assuming we used it..
    }
    return $fixed;
  }
}



1;


