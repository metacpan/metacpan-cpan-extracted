# -*- mode: perl; coding: utf-8 -*-

package WWW::NicoVideo::Scraper;

use utf8;
use strict;
use warnings;
use Web::Scraper;
use WWW::NicoVideo::URL;
use base qw[Web::Scraper];

sub import
{
  my $class = shift;
  my $pkg   = caller;

  no strict "refs";
  *{"$pkg\::scraper_entries"} = \&scraper_entries;
  *{"$pkg\::scraper"} = \&scraper;
  *{"$pkg\::process"} = sub { goto &process };
  *{"$pkg\::process_first"} = sub { goto &process_first };
  *{"$pkg\::result"} = sub { goto &result  };
}

sub scraper_entries()
{
  scraper {
    process('//div[@class="thumb_frm"]',
	    'entries[]' => scraper {
	      process('/div/div/div/p/a/img',
		      imgUrl => '@src',
		      imgWidth => '@width',
		      imgHeight =>  '@height');
	      process('/div/div/p/strong',
		      lengthStr => 'TEXT',
		      length => sub { shift->as_text =~ /(?:(\d+)分)?(\d+)秒/;
				      $1*60 + $2 });
	      process('/div/div/p/strong[2]',
		      numViewsStr => 'TEXT',
		      numViews => sub { my $x = shift->as_text;
					$x =~ tr/,//d;
					$x });
	      process('/div/div/p/strong[3]',
		      numCommentsStr => 'TEXT',
		      numComments => sub { my $x = shift->as_text;
					   $x =~ tr/,//d;
					   $x });
	      process('/div/div[2]/p/a[@class="video"]',
		      title => 'TEXT',
		      id => sub { shift->attr("href") =~ /(\w+)$/; $1 },
		      url => '@href');
	      process('/div/div[2]/p',
		      desc => sub { shift->content_array_ref->[-1] =~ /\s*(.*)/;
				    $1 }),
	      process('/div/div[2]/div/p/strong',
		      comments => sub { my $x = shift->as_text;
					$x =~ s/\s+$//;
					$x; });
	    });
  };
}

"Ritsuko";
