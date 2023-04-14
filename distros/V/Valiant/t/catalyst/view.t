use Test::Most;
use Test::Lib;
use Catalyst::Test 'View::Example';

{
  ok my $res = request '/test';
  ok $res->content_type, 'text/html';
  is $res->content, '<blockquote><html lang="en"><head><title>Homepage</title><meta charset="utf-8"/><meta content="width=device-width, initial-scale=1, shrink-to-fit=no" name="viewport"/><link href="data:," rel="icon"/><link href="/static/core.css" rel="stylesheet"/><link crossorigin="anonymous" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css" integrity="sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N" rel="stylesheet"/>sssssss</head><body><div>stuff4</div><div id="1">Hello John</div><p><p><p></p></p></p><div>stuff2</div><blockquote>stuff3</blockquote><div>stuff333</div><div></div><div id="33"><div id="2">hello</div></div><div>hello2</div><button name="button">fff</button><button id="ggg" name="button">ggg</button><hr/><div id="morexxx"><div id="3">more</div><div>none</div><hr id="hr"/><div>Hey</div><p><div>there</div><div>you</div></p><div id="4">more</div></div><div id="3"><div id="loop"><div id="1">1</div><div id="2">2</div><div id="3">3</div></div></div><div><form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post"><input/>foo<input/>bar</form></div><form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post"><input/>name</form><a href="http://localhost/test"><a href="http://localhost/test?foo=bar"><a href="http://localhost/test?foo=bar#fragment"><div><form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post"><input/>name</form></div></a></a></a><a class="linky" href="test">Link to Test item.</a><a href="test">Link to Test item.</a><a class="linky" href="http://localhost/test?page=1">Link to Test item.</a><div><form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post"><input/>name</form></div><script crossorigin="anonymous" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js"></script><script crossorigin="anonymous" integrity="sha384-Fy6S3B9q64WdZWQUiU+q4/2Lc9npb8tCaSX9FK7E8HnRr0Jz8D6OP9dO5Vg3Q9ct" src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js"></script></body></html></blockquote>';
}

{
  ok my $res = request '/simple';
  is $res->content, '<div>Hey</div>';
}

{
  ok my $res = request '/bits';
  is $res->content, '<div>stuff4</div>';
}

{
  ok my $res = request '/bits2';
  is $res->content, '<div>stuff4</div>';
}

{
  ok my $res = request '/stuff_long';
  is $res->content, '<div>Hey</div><p><div>there</div></p>';
}

done_testing;