=head1 NAME

WWW::Link::Selector - link selection functions.

=head1 SYNOPSIS

    use MLDBM qw(DB_File);
    use CDB_File::BiIndex;
    use WWW::Link::Selector;
    use WWW::Link::Reporter;

    #generate a function which uses lists of regexs to include or
    #exclude links
    $::include=WWW::Link::Selector::gen_include_exclude @::exclude, @::include;

    $::index = new CDB_File::BiIndex $::page_index, $::link_index
    $::linkdbm = tie %::links, "MLDBM", $::links, O_RDONLY, 0666, $::DB_HASH
      or die $!;
    $::reporter=new WWW::Link::Reporter::HTML \*STDOUT, $::index;

    #generate a function which will use all 
    $::selectfunc = WWW::Link::Selector::generate_select_func
      ( \%::links, $::reporter, $::include, $::index, );

    #report on all selectedlinks
    &$::selectfunc;

=head1 DESCRIPTION

This is a package (not a class though) which builds functions for
selecting links to give information about to a user.  So far there are
two ways of doing this, either scanning the entire database or using
an index to get the information.

=cut

package WWW::Link::Selector;
$REVISION=q$Revision: 1.10 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use strict;
use Carp qw(croak carp cluck);

$WWW::Link::Selector::ignore_missing = 0;

#$WWW::Link::Selector::verbose = 0xFF;
$WWW::Link::Selector::verbose = 0x00
  unless defined $WWW::Link::Selector::verbose;


sub _check_link ($$$) {
  my ($link,$url,$reporter)=@_;
  (defined $link) or do {
    $reporter->not_found( $url ) unless $WWW::Link::Selector::ignore_missing;
    return 0;
  };
  ref $link or do {
    cluck "Non reference $link found in database for url $url.\n";
    return 0;
  };
  return 1;
}

=head1 generate_url_func

This function creates a url function which will act on each of the
links for the urls given in its arguments.  If any of the arguments
have spaces it split them into different urls around that space.

=cut

sub generate_url_func ($$\@) {
  my $link_database=shift;
  my $reporter=shift;
  my $urls=shift;

  my @urllist=();
  foreach (@$urls) {
    push @urllist, split /\s+/, $_;
  }

  croak "empty urllist" unless @urllist;

  return sub {
    # a closure with the link database and urllist enclosed
    foreach ( @urllist ) {
      s/\s//g;
      my $url = $_;
      my $link=$link_database->{$url};
      next unless _check_link($link,$url,$reporter);
      $reporter->examine( $link );
    }
  }
}

=head2 generate_select_func(link_database, reporter, include_func, [index])

This function generates a selector function which works in one of two modes.

In the first, no index is given and it recurses through all of the
links in the database.

In the second it generates a selection function which recurses through
the B<index> working on each url.

For each url it finds, it calls the given link B<reporter> if the
B<include_func> returns true for that url.

=cut

sub generate_select_func ($$$;$) {
  my ($link_database, $reporter, $include_func, $index)=@_;
  if ($index) {
    return sub {

      print STDERR "Using index to generate list of urls to examine.\n"
	if $WWW::Link::Selector::verbose & 16;

      #check within an infostructure

      my $url;
      $index->second_reset();
    URL: while($url=$index->second_next()) {
	my $link=$link_database->{$url};
	print STDERR "WWW::Link::Selector::[generated selector] Looking"
	  . " at link $url.\n"
	    if $WWW::Link::Selector::verbose & 64;
	next unless _check_link($link,$url,$reporter);
	$reporter->examine ( $link ) if &$include_func($url);
      }

      print STDERR "Finished reporting index of urls.\n"
	if $WWW::Link::Selector::verbose & 16;

    }
  } else {
    return sub {

      print STDERR "Going through all urls in database\n"
	if $WWW::Link::Selector::verbose & 16;

	# check across the whole database of links

      my ($url,$link);
    LINK: while(($url,$link)=each %$link_database) {
	next if (!ref $url) and $url =~ m/^\%\+\+/;
	next unless _check_link($link,$url,$reporter);
	print STDERR "Looking at link $url.\n"
	  if $WWW::Link::Selector::verbose & 64;
	$reporter->examine ( $link ) if &$include_func($url);
      }
    }
  }
}


=head2 generate_index_select_func(link_database, reporter, include_func, index)

This function returns a function which iterates through all of the
links found in the index, calling $reporter->examine() for each link.

In this select function, the include_func is a function which is
called on each page url in our own pages to decide whether or not to
report the link.

=cut

sub generate_index_select_func ($$$$) {
  my ($link_database, $reporter, $include_func, $index)=@_;
  return sub {
    my $url;
    $index->second_reset();
  URL: while($url=$index->second_next()) {
      my $pagelist=$index->lookup_second($url);

      my $include=0;
      foreach my $page (@$pagelist) {
	&$include_func($page) || next;
	$include=1;
      }
      next URL unless $include;
      my $link=$link_database->{$url};
      ref $link or do {
	warn "Non reference $link found in database for url $url.\n";
	next;
      };
      print STDERR "WWW::Link::Selector::[generated index selector] " 
	. "Looking at link $url.\n" if $WWW::Link::Selector::verbose & 64;
      unless ($link) {
	$reporter->not_found( $url ) unless $WWW::Link::Selector::ignore_missing;
	next URL;
      }
      $reporter->examine ( $link ) ;
    }
    print STDERR "Finished reporting index of urls.\n"
      if $WWW::Link::Selector::verbose & 16;
  }
}

=head2 gen_include_exclude (@exclude, @include)

This function generates a function which will return false if any of
the regexps in the exclude_listre match and even then will return
false unless one of the regexps in the include listref matches.

If the first list is empty then all links matching the include list
will be accepted.

If the second list is empty, then all links not matching the exlcude
list will be accepted.

The fuction generated can be used by  generate_select_func (see above).

=cut


# this following fuction could be much more efficient with a compile
# once single regex.  See Manifest.pm for what seems to be an example.

# after Tom Christiansen in his FMTYEWTK on regexps.

sub gen_include_exclude (\@\@){
  my ($excludes, $includes) = @_;

  my @excludearray=();
  foreach my $exclude (@$excludes) {
    $exclude =~ s,(?<=[^\\])((:\\\\)*)/,$1\\/,g;
    push @excludearray, $exclude;
  }
  my @includearray=();
  foreach my $include (@$includes) {
    $include =~ s,(?<=[^\\])((:\\\\)*)/,$1\\/,g;
    push @includearray, $include;
  }

  my $code = <<"EOCODE";
  sub {
EOCODE
  $code .= <<"EOCODE" if @excludearray + @includearray > 5;
    study;
EOCODE
  my $pat;
  for $pat (@excludearray) {
    $code .= <<"EOCODE";
        return 0 if \$_[0] =~ /$pat/;
EOCODE
  }
  unless (@includearray) {
    $code .= <<"EOCODE";
        return 1;
EOCODE
  } else {
    for $pat (@includearray) {
      $code .= <<"EOCODE";
        return 1 if \$_[0] =~ /$pat/;
EOCODE
    } 
      $code .= <<"EOCODE";
        return 0;
EOCODE
  } 
    $code .= "}\n";
    print "CODE: $code\n"
      if $WWW::Link::Selector::verbose & 128;
    my $func = eval $code;
    die "bad pattern: $@" if $@;
    return $func;
}

1;
