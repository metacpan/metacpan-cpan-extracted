Webservice-Diffbot
==================

Diffbot Perl API - see http://www.diffbot.com for more info.

## Install

See the included `cpanfile` file for a list of dependencies.  If you have
App::cpanminus 1.6 or later installed, you can use `cpanm` to satisfy
dependencies like this:

    $ cpanm --installdeps .

Otherwise, you can install Module::CPANfile 1.0002 or later and then satisfy
dependencies with the regular `cpan` client and `cpanfile-dump`:

    $ cpan `cpanfile-dump`

## Use

```perl
use WebService::Diffbot;

my $diffbot = WebService::Diffbot->new(
    token => 'mytoken',
    url => 'http://www.diffbot.com'
);

# Article API
my $article = $diffbot->article;

print "url:   $article->{url}";
print "text:  $article->{text}";

# Frontpage API
my $frontpage = $diffbot->frontpage;

# another Article API - pass new url to method
$article = $diffbot->article( url => 'http://www.youtube.com' );

print "url:   $article->{url}";
print "text:  $article->{text}";
```
