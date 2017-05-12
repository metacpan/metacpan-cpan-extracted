use strict;
use warnings;

use Test::More tests => 6;                      # last test to print
use Test::LWP::Recorder; 
use lib qw(inc);
use LWPx::Record::DataSection;
mkdir 't/LWPtmp';
my $ua = Test::LWP::Recorder->new({
    record => 1,
    cache_dir => 't/LWPtmp', 
    filter_params => [qw(query)],
});

if ($ENV{LWPX_RECORD_APPEND_DATA}) {
    my $cacheonlyresult = $ua->get('http://search.cpan.org/search?query=LWALL&mode=author');
}
my $result = $ua->get('http://search.cpan.org/search?query=EALLENIII&mode=author');

ok(ref $result, "Result was an object");
ok($result->is_success, "Result is a success");
ok($result->content =~ m{<b>Edward[ ]J\.[ ]Allen[ ]III</b>}xms, 
    "Result containd my name");


my $ua2 = Test::LWP::Recorder->new({
    record => 0,
    cache_dir => 't/LWPtmp', 
    filter_params => [qw(query)],
});

$result = $ua2->get('http://search.cpan.org/search?query=LWALL&mode=author');

ok(ref $result, "Cache result was an object");
ok($result->is_success, "Cache result is a success");
ok($result->content =~ m{<b>Edward[ ]J\.[ ]Allen[ ]III</b>}xms, 
    "Cache result containd my name, not Larry's");





__DATA__

@@ GET http://search.cpan.org/search?query=LWALL&mode=author
HTTP/1.1 200 OK
Connection: close
Date: Tue, 07 Jun 2011 20:06:51 GMT
Server: Plack/Starman (Perl)
Content-Length: 3817
Content-Type: text/html

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
  <link rel="stylesheet" href="http://st.pimg.net/tucs/style.css" type="text/css" />
<style>
.styleswitch {
  text-align: right;
}
</style>


<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/jquery.cookie.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/sh_main.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/sh_perl.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/jquery.styleswitch.js"></script>

<link rel="stylesheet" href="http://st.pimg.net/tucs/print.css" type="text/css" media="print" />
  <link rel="alternate" type="application/rss+xml" title="RSS 1.0" href="http://search.cpan.org/uploads.rdf" />
  <link rel="search" href="http://st.pimg.net/tucs/opensearch.xml" type="application/opensearchdescription+xml" title="SearchCPAN" />
  <title>The CPAN Search Site - search.cpan.org</title>
 <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-3528438-1']);
    _gaq.push(['_trackPageview']);
  </script>
 </head>
 <body id="cpansearch">
<center><div class="logo"><a href="/"><img src="http://st.pimg.net/tucs/img/cpan_banner.png" alt="CPAN"></a></div></center>
<div class="menubar">
 <a href="/">Home</a>
&middot; <a href="/author/">Authors</a>
&middot; <a href="/recent">Recent</a>
&middot; <a href="http://log.perl.org/cpansearch/">News</a>
&middot; <a href="/mirror">Mirrors</a>
&middot; <a href="/faq.html">FAQ</a>
&middot; <a href="/feedback">Feedback</a>
</div>
<form method="get" action="/search" name="f" class="searchbox">
<input type="text" name="query" value="LWALL" size="35">
<br>in <select name="mode">
 <option value="all">All</option>
 <option value="module" >Modules</option>
 <option value="dist" >Distributions</option>
 <option value="author" selected>Authors</option>
</select>&nbsp;<input type="submit" value="CPAN Search">
</form>



<br><div class=t4>
<small>
Results <b>1</b> - <b>1</b> of
<b>1</b> Found</small></div>
<!--results-->
<!--item-->
  <p><h2 class=sr><a href="/~lwall/"><b>Larry Wall. Author of Perl. Busy man.</b></a></h2>
<small>LWALL</small><br/>
<!--end item-->
<!--end results-->
<br>

<div class="footer"><div class="cpanstats">68788 Uploads, 22717 Distributions
96067 Modules, 9014 Uploaders
</div>
hosted by <a href="http://www.yellowbot.com">YellowBot</a><br/>
<a href="http://www.yellowbot.com"><img alt="do. tag. write. share." src="http://st.pimg.net/tucs/img/yellowbot_logo.gif"></a>
</div>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript" src="http://ipv4.v6test.develooper.com/js/v1/v6test.js"></script>

<script type="text/javascript">
   // v6.target = '';
   if (!v6.target) { v6.only_once = true }
   v6.site = '7A0D89A6-2B82-11DF-B9DA-F61CBD13F020';
   v6.api_server = 'http://ipv4.v6test.develooper.com';
   try {
     v6.test();
   } catch(err) {}
</script>
<script type="text/javascript">
  $(document).ready(function(){
    $("a[href^=http:]").click(function(){
      var href = $(this).attr('href');
      var m = href.match('\/\/([^\/:]+)');
      _gaq.push(['_trackEvent','External',m[1],'Other']);
    });
    $("a[href^=/CPAN/]").click(function(){
      var href = $(this).attr('href');
      _gaq.push(['_trackEvent','Download',href,'Other']);
    });
  });
</script>
<!-- Tue Jun  7 20:06:51 2011 GMT (0.00439000129699707) @cpansearch1 -->
 </body>
</html>

@@ GET http://search.cpan.org/search?query=EALLENIII&mode=author
HTTP/1.1 200 OK
Connection: close
Date: Tue, 07 Jun 2011 20:06:51 GMT
Server: Plack/Starman (Perl)
Content-Length: 3809
Content-Type: text/html

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
  <link rel="stylesheet" href="http://st.pimg.net/tucs/style.css" type="text/css" />
<style>
.styleswitch {
  text-align: right;
}
</style>


<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/jquery.cookie.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/sh_main.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/sh_perl.min.js"></script>
<script type="text/javascript" src="http://st.pimg.net/tucs/js/jquery.styleswitch.js"></script>

<link rel="stylesheet" href="http://st.pimg.net/tucs/print.css" type="text/css" media="print" />
  <link rel="alternate" type="application/rss+xml" title="RSS 1.0" href="http://search.cpan.org/uploads.rdf" />
  <link rel="search" href="http://st.pimg.net/tucs/opensearch.xml" type="application/opensearchdescription+xml" title="SearchCPAN" />
  <title>The CPAN Search Site - search.cpan.org</title>
 <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-3528438-1']);
    _gaq.push(['_trackPageview']);
  </script>
 </head>
 <body id="cpansearch">
<center><div class="logo"><a href="/"><img src="http://st.pimg.net/tucs/img/cpan_banner.png" alt="CPAN"></a></div></center>
<div class="menubar">
 <a href="/">Home</a>
&middot; <a href="/author/">Authors</a>
&middot; <a href="/recent">Recent</a>
&middot; <a href="http://log.perl.org/cpansearch/">News</a>
&middot; <a href="/mirror">Mirrors</a>
&middot; <a href="/faq.html">FAQ</a>
&middot; <a href="/feedback">Feedback</a>
</div>
<form method="get" action="/search" name="f" class="searchbox">
<input type="text" name="query" value="EALLENIII" size="35">
<br>in <select name="mode">
 <option value="all">All</option>
 <option value="module" >Modules</option>
 <option value="dist" >Distributions</option>
 <option value="author" selected>Authors</option>
</select>&nbsp;<input type="submit" value="CPAN Search">
</form>



<br><div class=t4>
<small>
Results <b>1</b> - <b>1</b> of
<b>1</b> Found</small></div>
<!--results-->
<!--item-->
  <p><h2 class=sr><a href="/~ealleniii/"><b>Edward J. Allen III</b></a></h2>
<small>EALLENIII</small><br/>
<!--end item-->
<!--end results-->
<br>

<div class="footer"><div class="cpanstats">68788 Uploads, 22717 Distributions
96067 Modules, 9014 Uploaders
</div>
hosted by <a href="http://www.yellowbot.com">YellowBot</a><br/>
<a href="http://www.yellowbot.com"><img alt="do. tag. write. share." src="http://st.pimg.net/tucs/img/yellowbot_logo.gif"></a>
</div>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript" src="http://ipv4.v6test.develooper.com/js/v1/v6test.js"></script>

<script type="text/javascript">
   // v6.target = '';
   if (!v6.target) { v6.only_once = true }
   v6.site = '7A0D89A6-2B82-11DF-B9DA-F61CBD13F020';
   v6.api_server = 'http://ipv4.v6test.develooper.com';
   try {
     v6.test();
   } catch(err) {}
</script>
<script type="text/javascript">
  $(document).ready(function(){
    $("a[href^=http:]").click(function(){
      var href = $(this).attr('href');
      var m = href.match('\/\/([^\/:]+)');
      _gaq.push(['_trackEvent','External',m[1],'Other']);
    });
    $("a[href^=/CPAN/]").click(function(){
      var href = $(this).attr('href');
      _gaq.push(['_trackEvent','Download',href,'Other']);
    });
  });
</script>
<!-- Tue Jun  7 20:06:51 2011 GMT (0.106673002243042) @cpansearch1 -->
 </body>
</html>

