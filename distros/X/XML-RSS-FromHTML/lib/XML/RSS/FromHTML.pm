package XML::RSS::FromHTML;
use base Class::Accessor::Fast;
use strict;
use Carp;
use XML::RSS ();
use LWP::UserAgent ();
use HTTP::Cookies ();
use Data::Dumper ();
use bytes ();
use File::Basename ();
our $VERSION = '0.06';

__PACKAGE__->mk_accessors(qw(
	name
	url
	cacheDir
	feedDir
	rssObj
	minInterval
	passthru
	debug
	unicodeDowngrade
	maxItemCount
	outFileName
	updateStatus
	newItems
));

sub new {
	my $self = shift;
	my $p = bless({},$self);
	# set default values
	$p->name('myrss');
	$p->cacheDir('.');
	$p->feedDir('.');
	$p->minInterval(300); # in seconds
	$p->maxItemCount(30);
	$p->passthru({});
	$p->updateStatus('update not executed yet');
	# initialize properties (for sub-classes)
	$p->init(@_);
	return $p;
}

sub update {
	my $self = shift;
	### define output files for debug
	my $dbg = {
		interval => $self->cacheDir.'/'.$self->name.'.intv',
		html     => $self->cacheDir.'/'.$self->name.'.html',
		list     => $self->cacheDir.'/'.$self->name.'.list',
		update   => $self->cacheDir.'/'.$self->name.'.update',
		newcount => $self->cacheDir.'/'.$self->name.'.new.count',
	};
	if($self->debug){
		unlink $dbg->{$_} foreach(keys %{$dbg});
	}
	### check minimum interval
	my ($getOk,$okTime,$nowTime) = $self->checkInterval();
	unless($getOk){
		# debug
		if($self->debug){
			open(OUT,'>',$dbg->{interval}) or confess $!;
			print OUT "now : ${nowTime}\nok  : ${okTime}";
		}
		$self->updateStatus("still under check interval time period");
		return 0;
	}
	### retrieve html
	my $html = $self->getHTML( $self->url );
	# debug
	if($self->debug){
		open(OUT,'>',$dbg->{html}) or confess $!;
		print OUT $html."\n\n";
		print OUT $self->url."\n";
	}
	### html parsing
	my $list = $self->makeItemList($html);
	if(scalar @{$list} < 1){
		$self->updateStatus("makeItemList returned with 0 item - html parse failure");
		return 0;
	}
	# debug
	if($self->debug){
		open(OUT,'>',$dbg->{list}) or confess $!;
		require 'Dumpvalue.pm';
		select(OUT);
		print Dumpvalue->new->dumpValue($list);
		select(STDOUT);
	}
	### caching
	my ($update,$old_list,$size_new,$size_old) = $self->cache($list);
	# debug
	if($self->debug){
		if($update){
			open(OUT,'>',$dbg->{update}) or confess $!;
			print OUT "new: $size_new\nold: $size_old\n";
		}
	}
	### read & parse old rss file
	my $rss_old = $self->_loadOldRss();
	### remake RSS if update
	if($update){
		my ($rss_new,$new_count) = $self->remakeRSS($list,$old_list,$rss_old);
		$self->rssObj($rss_new);
		# debug
		if($self->debug){
			open(OUT,'>',$dbg->{newcount}) or confess $!;
			print OUT "$new_count\n";
		}
		$self->updateStatus("updated with $new_count new items");
		return 1;
	}else{
		$self->rssObj($rss_old);
		$self->updateStatus("there was no new item");
		return 0;
	}
}

sub checkInterval {
	my $self = shift;
	my $cache_file = $self->_getCacheFilePath();
	return 1 if(!-f $cache_file);
	return 1 if(!$self->minInterval);
	my $okTime = ( stat($cache_file) )[9] + $self->minInterval;
	my $nowTime = time();
	return (1,$okTime,$nowTime) if($nowTime > $okTime);
	return (0,$okTime,$nowTime);
}

sub getHTML {
	my $self = shift;
	my $url = shift;
	my $ua = LWP::UserAgent->new;
	$ua->cookie_jar({ file => $self->cacheDir.'/'.$self->name.'.cookie' });
	my $res = $ua->get($url);
	confess q(couldn't retrieve html from ) . $url if(!$res->content);
	return $res->content;
}

sub cache {
	my $self = shift;
	my $list = shift;
	my $cache_file = $self->_getCacheFilePath();
	my $dump = Data::Dumper::Dumper($list);
	my $len_new  = bytes::length($dump);
	my $len_old  = -s $cache_file || 0;
	# if there's an update
	if($len_new != $len_old){
		my $fh;
		# read old cache file
		my $old_data;
		if(-f $cache_file){
			open($fh,'<',$cache_file)
			or confess "failed to open $cache_file - $!";
			{
				local ($/) = undef;
				my $x = <$fh>;
				($x) = ($x =~ /(.+)/ms); # untaint
				my $VAR1;
				$old_data = eval($x);
			}
			close($fh);
		}
		# make new cache file
		if($self->outFileName){
			my $n = $self->outFileName;
			$cache_file =~ s|[^/]+(\..+?)$|$n$1|o;
		}
		open($fh,'>',$cache_file)
		or confess "failed to write-open $cache_file - $!";
		print $fh Data::Dumper::Dumper($list);
		return (1,$old_data,$len_new,$len_old);
	}
	# else then there's no update
	return undef;
}

sub remakeRSS {
	my $self = shift;
	my ($newlist,$oldlist,$oldrss) = @_;
	my $rss_new = new XML::RSS(%{ $self->passthru });
    # if old rss hold no items, which means the file was broken or removed,
    # then we should reset the old list too, to remake all items again
    if( scalar @{$oldrss->{items} || []} == 0 ){
        $oldlist = [];
    }
	# find which item's new
	my (@new,%chk,%chkInOldRss);
	# making check hash
	my $i=0;
	foreach (@{ $oldlist }){
		$chk{ $_->{link} } = $i;
		$i++;
	}
	# making check hash - for items only exist in rss file, and not in cache
	$i=0;
	foreach (@{ $oldrss->{items} }){
		next if($chk{ $_->{link} }); # ignore those in cache
		$chkInOldRss{ $_->{link} } = $i;
		$i++;
	}
	foreach my $p (@{ $newlist }){
		# check for any content updates, compared to cache list
		if(exists $chk{ $p->{link} }){
			my $o = $oldlist->[ $chk{ $p->{link} } ];
			my $oldlen = bytes::length(Data::Dumper::Dumper($o));
			my $newlen = bytes::length(Data::Dumper::Dumper($p));
			if($newlen != $oldlen){
				# delete that old item from rss
				my @tmp;
				my $qr = qr/\Q$p->{link}\E/;
				foreach my $old (@{ $oldrss->{items} }){
					push(@tmp,$old) unless($old->{link} =~ /$qr/);
				}
				$oldrss->{items} = \@tmp;
				push(@new,$p);
			}
		# else, check for duplicates
		}elsif(exists $chkInOldRss{ $p->{link} }){
			my @tmp;
			my $qr = qr/\Q$p->{link}\E/;
			foreach my $itm (@{ $oldrss->{items} }){
				push(@tmp,$itm) unless($itm->{link} =~ /$qr/);
			}
			$oldrss->{items} = \@tmp;
			push(@new,$p);
		# if it's a brand new item
		}else{
			push(@new,$p);
		}
	}
	# make rss for new items
	my $new_count = 0;
	for (my $i=0; $i < scalar @new; $i++){
		last if (defined($self->maxItemCount) && $i == $self->maxItemCount);
		$self->addNewItem($rss_new,$new[$i]);
		$new_count++;
	}
	# add old items
	my $now = scalar @new;
	foreach my $itr (@{ $oldrss->{items} }){
		last if (defined($self->maxItemCount) && $now >= $self->maxItemCount);
		$rss_new->add_item(%{$itr});
		$now++;
	}
	# set RSS definition
	$self->defineRSS($rss_new);
	# save to file
	$self->_saveToFile($rss_new);
	# set to $self->newItems property
	my @newItems;
	for (my $i=0; $i < scalar @new; $i++){
		push(@newItems,$rss_new->{items}[$i]);
	}
	$self->newItems(\@newItems);
	return ($rss_new,$new_count);
}

sub as_string {
	my $self = shift;
	$self->_loadOldRss if(!$self->rssObj);
	return $self->rssObj->as_string();
}

sub as_object {
	my $self = shift;
	$self->_loadOldRss if(!$self->rssObj);
	return $self->rssObj;
}

sub name {
	my $self = shift;
	if(@_){
		my $s = shift;
		$s =~ s/[^a-zA-z0-9\-]/_/g;
		$self->{name} = $s;
	}
	return $self->{name};
}

sub getDateTime {
	my $self = shift;
	my $str  = shift;
	my $t;
	require HTTP::Date;
	if($str){
		$t = HTTP::Date::str2time($str);
	}
	return HTTP::Date::time2str($t);
}

sub _loadOldRss {
	my $self = shift;
	my $file = $self->_getFeedFilePath();
	my $r = XML::RSS->new(%{ $self->{passthru} });
    eval {
        $r->parsefile($file) if(-f $file);
    };
    if( $@ || scalar( @{$r->{items} || []} ) < 1 ){
        $self->updateStatus("old rss file was broken, so ignoring - $@");
    }
	if($self->unicodeDowngrade){
        eval { require Unicode::RecursiveDowngrade };
        if( $@ ){
            warn 'you will need to install Unicode::RecursiveDowngrade module to use $self->unicodeDowngrade option';
        }else{
            $r = Unicode::RecursiveDowngrade->new->downgrade($r);
        }
	}
	$self->rssObj($r);
	return $r;
}

sub _getCacheFilePath {
	my $self = shift;
	return $self->cacheDir.'/'.$self->name.'.cache';
}

sub _getFeedFilePath {
	my $self = shift;
	return $self->feedDir.'/'.$self->name.'.xml';
}

sub _saveToFile {
	my $self = shift;
	my $rss_new = shift;
	my $saveFile = $self->_getFeedFilePath();
	if($self->outFileName){
		my $n = $self->outFileName;
        my ($name, $dir, $suffix) = File::Basename::fileparse( $saveFile, qr/\.[^.]*/ );
        $saveFile = "$dir$n$suffix";
	}
	$rss_new->save( $saveFile ) or confess $!;
	return 1;
}

# below are all must-override methods
sub init {
	confess q(
	must override this method with sub-class using the following interface:
	sub init {
	    my $self = shift;
	    # set feed url, name, and other constant stuff here #
	    $self->url('http://target.site/updates.html');
	    $self->name('sample feed');
	    $self->passthru({
	    	version => '1.0',
	    	encode_output => 1,
	    });
	    return 1;
	}
	);
}

sub makeItemList {
	confess q(
	must override this method with sub-class using the following interface:
	sub makeItemList {
	    my $self = shift;
	    my $html = shift;
	    my @list;
	    # parse html and make an item list here #
	    while ($html =~ /<a href="(.+?)">(.+?)</a>/){
	        push(@list,{
	            link  => $1,
	            title => $2,
	        });
	    }
	    return \@list;
	}
	);
}

sub addNewItem {
	confess q(
	must override this method with sub-class using the following interface:
	sub addNewItem {
	    my $self = shift;
	    my ($rssObject,$item) = @_;
	    # create & add new item to rssObject using data in #
	    # $item hashRef, which you made in makeItemList()  #
	    $rssObject->add_item(
			link  => $item->{link},
			title => $item->{title},
	    );
	    return 1;
	}
	);
}

sub defineRSS {
	confess q(
	must override this method with sub-class using the following interface:
	sub defineRSS {
	    my $self = shift;
	    my $rssObject = shift;
	    # define rss channel info, and other stuffs here #
	    $rssObject->channel(
			title => 'blabla rss feed',
			description => 'foo bar',
			link  => 'http://mysite/rss/',
	    );
		$rssObject->image(
			title  => "blabla rss feed",
			url    => "http://mysite/rss/feed.png",
		);
	    return 1;
	}
	);
}

1;
__END__

=head1 NAME

XML::RSS::FromHTML - simple framework for making RSS out of HTML

=head1 SYNOPSIS

  ### create your own sub-class, with these four methods
  package MyModule;
  use base XML::RSS::FromHTML;
  
  sub init {
      my $self = shift;
      # set your configurations here
      $self->name('MyRSS');
      $self->url('http://foo.com/headlines.html');
  }
  
  sub defineRSS {
      my $self = shift;
      my $xmlrss  = shift;
      # define your RSS using XML::RSS->channel method
      $xmlrss->channel(
          title => 'foo.com headlines feed',
          description => 'generated from http://foo.com headlines'
      );
  }
  
  sub makeItemList {
      my $self = shift;
      my $html = shift;
      # parse HTML and make an item list
      my @list;
      while ($html =~ m|<li><a href="(.+?)">(.+?)</a></li>|g){
          push(@list,{
              link  => $1,
              title => $2
          });
      }
      return \@list;
  }
  
  sub addNewItem {
      my $self = shift;
      my ($xmlrss,$eachItem) = @_;
      # make your item using XML::RSS->add_item method
      $xmlrss->add_item(
          title => $eachItem->{title},
          link  => $eachItem->{link},
          description => 'this is '. $eachItem->{title},
      );
  }
  
  #### and from your main routine...
  package main;
  use MyModule;
  my $rss = MyModule->new;
  $rss->update;
  # an updated RSS file './MyRSS.xml' will be created.
  # run this script every day, and your RSS will always 
  # be up-to-date.

=head1 DESCRIPTION

This module is a simple framework for creating RSS out of HTML periodically. There are still plenty of web sites that doesn't supply RSS feeds, which we think it would be nice if they did. This module helps you create RSS feeds for those sites by your-own-hand, and maintain the contents up to date. The core features are as follows:

=over

=item * retrieving HTML text from url

=item * restraining short interval access to url

=item * caching of update records (cause minimum access to url)

=item * framework that offers minimum coding to developers

=back

It's mostly focused on trying not to be an annoyance to the target url/web site (and of course, developer-friendliness). We don't want to be seen as spams, but would be nice if we could tell them the value of RSS feeds.

=head1 USAGE

=head2 BASIC

This module is not intended to work by itself. You will need to create a sub class of it, and define these four methods with customization for your target url/web site.

=head2 FOUR METHODS

=head3 init()

  sub init {
      my $self = shift;
      # set your configurations here
      $self->name('Test');
      $self->url('http://foo.com/headlines.html');
      $self->cacheDir('./cache');
      $self->feedDir('./feed');
      return 1;
  }

Called with-in the constructor, this method should initialize property values of your choice. See the PROPERTIES section for description of available properties.

=head3 defineRSS()

Define your RSS feed descriptions and informations here, using the XML::RSS->channel method.

  sub defineRSS {
      my $self = shift;
      my $xmlrss = shift;
      # define your RSS using XML::RSS->channel method
      $xmlrss->channel(
          title => 'foo.com headlines feed',
          description => 'generated from http://foo.com headlines'
      );
      # you can also define images with XML::RSS->image method
      $xmlrss->image(
          title  => 'foo.com headlines feed',
          url    => 'http://mysite/image/logo.gif',
          link   => 'http://foo.com/headlines.html'
      );
      return 1;
  }

=head3 makeItemList()

With the whole html string (supplied as argument), use whatever mean (i.e. regexp) to create a data structure of items. Later on, you'll be using these information to create feed items.

  sub makeItemList {
      my $self = shift;
      my $html = shift;
      # parse HTML and make an item list
      my @list;
      while ($html =~ m| .. some mumbling regexp here .. |g){
          push(@list,{
              link     => $1,
              title    => $2,
              category => $3,
              id       => $4,
              ...
          });
      }
      return \@list;
  }

=head3 addNewItem()

From the list created with above method (makeItemList), the framework will check for updates, and will call this method for each new items. Thus, the argument $eachItem represents the iterator (each element of @list created with $self->makeItemList) object. Use XML::RSS->add_item method to add a new item to the RSS feed.  You can also fetch any additional information about the item, like from the description page, and add them to the feed too.

  sub addNewItem {
      my $self = shift;
      my ($xmlrss,$eachItem) = @_;
      # fetch additional information if you want to
      require LWP::Simple;
      my $html = get("http://foo.com/archives/$eachItem->{id}.html");
      my ($desc) = ($html =~ m|<p class="desc">(.+?)</p>|);
      # make your rss item using XML::RSS->add_item method
      $xmlrss->add_item(
          title => $eachItem->{title},
          link  => $eachItem->{link},
          category => $eachItem->{cateogry},
          description => $desc,
      );
      return 1;
  }

=head2 HOW TO USE

Basically, all you need to do is load your sub-class module, create new instance, and call the update method. The return value of update method is a boolean value, representing:

=over

=item * 1 : RSS feed re-written. There were some updates.

=item * 0 : No update, for some reason.

=back

And with $self->updateStatus method, you'll be informed with a status message.

  use MyModule;
  my $rss = MyModule->new;
  my $hasNewItem = $rss->update;
  if($hasNewItem){
    print "RSS updated with some new items";
    return 1;
  }else{
    # i.e. "still under check interval time period"
    print $rss->updateStatus; 
    return undef;
  }

=head2 PROPERTIES

These are all the properties available for configuration within $self->init method.

=over

=item * name

Identification string, used for feed file name and cache file name. Default value is 'myrss'.

=item * url

The URL of the target web page.

=item * cacheDir

Directory path to where the cache files are stored. Default is '.' (current dir).

=item * feedDir

Directory path to where the RSS feed file will be saved. Default is '.' (current dir).

=item * minInterval

Minimum interval period in seconds. If $self->update is called more than once with-in this interval period, the call will silently be ignored, thus restricting un-necessary access to the target url. Default is 300 (=5minutes).

=item * maxItemCount

The maximum number of items the RSS feed contains. If exceeded, older items will be deleted from the feed. Default is 30.

=item * unicodeDowngrade

[depricated since v0.04] pre-requisity module XML::Parser v2.34 no longer creates utf-8 flagged strings, so this feature is not need by japanese and other multi-byte character languages.

Parsing of RSS files with XML::RSS (actually XML::Parser) results in utf-8 flagged strings. Setting this to a true value will take all these utf-8 flags off, which is sometimes helpfull for non-ascii language codes without using the 'encoding' pragma.

=item * passthru

Should supply a hashref data, containing optional values you would want to pass to XML::RSS->new() method. Default is {} (empty). For example, setting this:

  $self->passthru({ version => '2.0' });

will work as

  XML::RSS->new( version => '2.0' );

in every place XML::RSS->new is called internally.

=item * outFileName

If supplied, the name of the out file (feed xml file) will use this one instead of $self->name. (Intended for custom usage only).

=item * debug

If set to a true value, each time $self->update method is called, some useful debugging information (files) will be created in the $self->cacheDir directory.

=back

=head2 OTHER USEFUL PROPERTIES

=head3 updateStatus

As described above (section HOW TO USE), this property contains some helpful message about the update sequence. Currently there are:

=over

=item * 'update not executed yet'

default message before $self->update is called.

=item * 'still under check interval time period'

$self->minInterval seconds hasn't passed yet since the last update.

=item * 'makeItemList returned with 0 item - html parse failure'

parsing logic is not working right. Must be a change in the html structure.

=item * 'updated with $n new items'

successfully updated with $n new items.

=item * 'there was no new item'

the HTML hasn't changed a bit.

=back

=head3 newItems

An array reference to all the items that were counted as new item. Sometimes usefull after $self->update method call.

  $rss->update;
  print "there were " scalar @{ $rss->newItems } . " items new.\n";
  foreach (@{ $rss->newItems }){
      print "title: $_->{title}\n";
  }

=head2 OTHER USEFUL METHODS

=head3 as_string()

Will return RSS feed as XML string.

=head3 as_object()

Will return XML::RSS object of the current RSS feed.

=head3 getDateTime()

Will return the current date + time in a RFC 1123 styled GMT Ascii format, like this:

  Sun, 06 Nov 1994 08:49:37 GMT

Useful for date/time related elements within RSS feed (i.e. pubDate).
Also, if passed with some kind of a date-time string as an argument, it'll try it's best to parse the string and return as GMT Ascii format string as well.

  print $self->getDateTime('19940203T141529Z');
  # will print 'Thu, 03 Feb 1994 14:15:29 GMT'

It uses L<HTTP::Date> internally, so see HTTP::Date's parse_date() method documentation for available (parse-able) formats.

=head1 TIPS

=head2 RETRIEVING HTML FROM SESSION REQUIRED WEB SITE

With some web sites, they require a valid session-id in your browser cookie or query string in order to retrieve their contents. The session id is usually given to you the first time you visit their TOP PAGE, or of course, when you go through the LOGIN process.

If you want/need to retrieve some HTML from pages that require these session id's, you should override the $self->getHTML method with your own customization. For example, assuming a web site that gives you session-id's when you access their top.cgi page, the getHTML method will be like this:

  sub getHTML {
      my $self = shift;
      my $url = shift;
      my $ua = LWP::UserAgent->new;
      $ua->cookie_jar({ file => $self->cacheDir.'/'.$self->name.'.cookie' });
      $ua->get('http://foo.com/top.cgi'); # set session-id in cookie
      my $res = $ua->get($url); # send with session-id cookie
      return $res->content;
  }

=head1 BUGS

Nothing that I'm aware of, yet.

=head1 AUTHOR

  Toshimasa Ishibashi
  CPAN ID: BASHI
  bashi@cpan.org
  http://iandeth.dyndns.org/mt/ian/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1). L<XML::RSS>

=cut
