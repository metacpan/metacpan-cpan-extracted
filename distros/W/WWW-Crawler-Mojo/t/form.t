use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Mojo::DOM;
use WWW::Crawler::Mojo;
use WWW::Crawler::Mojo::Job;
use WWW::Crawler::Mojo::ScraperUtil;
use Mojo::Message::Response;
use Test::More tests => 59;

my $html_handlers = WWW::Crawler::Mojo::ScraperUtil::html_handler_presets();

sub _weave_form_data {
  $html_handlers->{form}->(@_);
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
      <select name=""><option>a</option></select>
      <select name="" multiple><option>a</option></select>
      <input type="text" name="">
      <input type="submit" value="submit1">
      <input type="submit" name='buttonName' value="submit2">
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is_deeply $ret->[2]->to_hash, {};
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
        <input type="submit" name='buttonName'>
        <input type="submit" name='buttonName' value="submit2">
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is_deeply $ret->[2]->to_hash, {buttonName => ''};
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
        <input type="image">
        <input type="submit" name='buttonName' value="submit2">
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is_deeply $ret->[2]->to_hash, {};
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
        <input type="text" name="foo" value="default">
        <input type="submit" name='buttonName' value="submit1">
        <input type="submit" name='buttonName' value="submit2">
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is_deeply $ret->[2]->to_hash, {buttonName => 'submit1', foo => 'default'};
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
        <input type="text" name="foo" value="default">
        <button type="submit" name="buttonName" value="submit1">btn1</button>
        <button type="submit" name="buttonName" value="submit2">btn2</button>
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is_deeply $ret->[2]->to_hash, {buttonName => 'submit1', foo => 'default'};
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
        <input type="text" name="foo" value="default">
        <button type="submit" name="buttonName" value="">btn1</button>
        <button type="submit" name="buttonName" value="submit2">btn2</button>
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is_deeply $ret->[2]->to_hash, {buttonName => '', foo => 'default'};
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="get">
        <input type="text" name="foo" value="default">
        <input type="submit" value="submit">
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'GET';
  is $ret->[2], 'foo=default';
}

{
  my $dom = Mojo::DOM->new(<<EOF);
<div>
    <form action="/index1.html" method="post">
        <input type="text" name="foo" value="default">
        <input type="submit" name="bar" value="submit">
    </form>
</div>
EOF
  my $ret = _weave_form_data($dom->at('form'));
  is $ret->[0], '/index1.html';
  is $ret->[1], 'POST';
  is_deeply $ret->[2]->to_hash, {bar => 'submit', foo => 'default'};
}

{
  my $dom = Mojo::DOM->new(<<'EOF');
<html>
    <body>
        <form action="/receptor1" method="post">
            <input type="text" name="foo" value="fooValue">
            <input type="text" name="bar" value="barValue">
            <input type="hidden" name="baz" value="bazValue">
            <input type="hidden" name="yada" value="yadaValue" disabled="disabled">
            <input type="submit" name='btn' value="send">
            <input type="submit" name='btn' value="send2">
            <input type="submit" name='btn3' value="send3">
        </form>
        <form action="/receptor1" method="post">
            <input type="text" name="foo" value="fooValue">
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="radio" name="foo" value="fooValue2"> fooValue2
            <input type="radio" name="foo" value="fooValue3"> fooValue3
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="radio" name="foo" value="fooValue2"> fooValue2
            <input type="radio" name="foo" value="fooValue3" checked="checked"> fooValue3
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="hidden" name="foo" value="">
            <input type="radio" name="foo" value="fooValue1"> fooValue1
            <input type="radio" name="foo" value="fooValue2" checked="checked"> fooValue2
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="radio" name="foo" value="fooValue1"> fooValue1
            <input type="radio" name="foo" value="fooValue2" checked> fooValue2
            <input type="radio" name="foo" value="fooValue3"> fooValue3
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <select name="foo">
                <option value="">a</option>
                <option value="fooValue1">a</option>
                <option value="fooValue2">b</option>
                <option value="a&quot;b">b</option>
                <option value="a/b">b</option>
            </select>
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="text" name="foo" value="" pattern="\d\d\d">
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="number" name="foo" value="" min="5" max="10">
            <input type="submit" value="send">
        </form>
        <form action="/receptor3" method="post">
        </form>
        <form action="/receptor1" method="post">
            <input type="text" name="foo" value="">
            <input type="file" name="bar">
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="hidden" name="foo" value="value1">
            <select name="foo" multiple>
                <option value="value2" selected>a</option>
                <option value="value3" selected>a</option>
                <option value="value4">a</option>
            </select>
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="hidden" name="foo" value="やったー">
        </form>
        <form action="/receptor1" method="post">
            <textarea name="foo">foo default</textarea>
            <textarea name="bar" disabled>bar default</textarea>
            <textarea name="baz" required>baz default</textarea>
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="hidden" name="foo" value="value1">
            <select name="foo">
                <option value="value2" selected>a</option>
                <option value="value3" selected>a</option>
            </select>
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="hidden" name="foo" value="value1">
            <select name="foo">
                <option value="value2">a</option>
                <option value="value3" selected>a</option>
            </select>
            <input type="submit" value="send">
        </form>
        <form action="/receptor1" method="post">
            <input type="hidden" name="foo" value="value1">
            <select name="foo">
                <option value="value2">a</option>
                <option value="value3">a</option>
            </select>
            <input type="submit" value="send">
        </form>
    </body>
</html>
EOF
  {
    my $ret = _weave_form_data($dom->find('form')->[0]);
    is_deeply $ret->[2]->to_hash,
      {
      baz  => 'bazValue',
      bar  => 'barValue',
      btn  => 'send',
      foo  => 'fooValue',
      yada => 'yadaValue'
      };
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[1]);
    is_deeply $ret->[2]->to_hash, {foo => 'fooValue'};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[2]);
    is_deeply $ret->[2]->to_hash, {};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[3]);
    is_deeply $ret->[2]->to_hash, {foo => 'fooValue3'};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[4]);
    is_deeply $ret->[2]->to_hash, {foo => ['', 'fooValue2']};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[5]);
    is_deeply $ret->[2]->to_hash, {foo => 'fooValue2'};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[6]);
    is_deeply $ret->[2]->to_hash, {foo => ''};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[7]);
    is_deeply $ret->[2]->to_hash, {foo => ''};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[8]);
    is_deeply $ret->[2]->to_hash, {foo => ''};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[9]);
    is_deeply $ret->[2]->to_hash, {};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[10]);
    is_deeply $ret->[2]->to_hash, {foo => ''};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[11]);
    is_deeply $ret->[2]->to_hash, {foo => ['value1', 'value2', 'value3']};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[12]);
    is_deeply $ret->[2]->to_hash, {foo => 'やったー'};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[13]);
    is_deeply $ret->[2]->to_hash,
      {foo => 'foo default', bar => 'bar default', baz => 'baz default'};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[14]);
    is_deeply $ret->[2]->to_hash, {foo => ['value1', 'value2']};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[15]);
    is_deeply $ret->[2]->to_hash, {foo => ['value1', 'value3']};
  }
  {
    my $ret = _weave_form_data($dom->find('form')->[16]);
    is_deeply $ret->[2]->to_hash, {foo => ['value1', 'value2']};
  }
}

{
  my $html = <<EOF;
<html>
<body>
<form action="/index1.html">
    <input type="text" name="foo" value="default">
    <input type="submit" value="submit">
</form>
<form action="/index2.html" method="post">
    <textarea name="foo">foo</textarea>
    <input type="submit" value="submit">
</form>
<form action="/index2.html" method="post">
    <textarea name="bar">bar</textarea>
    <input type="submit" value="submit">
</form>
</body>
</html>
EOF

  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_length(length($html));
  $res->body($html);
  $res->headers->content_type('text/html');

  my $bot = WWW::Crawler::Mojo->new;
  $bot->init;
  $bot->enqueue($_) for ($bot->scrape($res, new_job('http://example.com/')));

  my $job;
  $job = $bot->queue->dequeue;
  is $job->literal_uri, '/index1.html', 'right url';
  is $job->url, 'http://example.com/index1.html?foo=default', 'right url';
  is $job->method,           'GET', 'right method';
  is_deeply $job->tx_params, undef, 'right params';
  $job = $bot->queue->dequeue;
  is $job->literal_uri, '/index2.html',                   'right url';
  is $job->url,         'http://example.com/index2.html', 'right url';
  is $job->method,      'POST',                           'right method';
  is_deeply $job->tx_params->to_hash, {foo => 'foo'}, 'right params';
  $job = $bot->queue->dequeue;
  is $job->literal_uri, '/index2.html',                   'right url';
  is $job->url,         'http://example.com/index2.html', 'right url';
  is $job->method,      'POST',                           'right method';
  is_deeply $job->tx_params->to_hash, {bar => 'bar'}, 'right params';
  $job = $bot->queue->dequeue;
  is $job, undef, 'no more urls';
}


{
  my $html = <<EOF;
<html>
<body>
<form>
    <input type="text" name="foo" value="default">
    <input type="submit" value="submit">
</form>
</body>
</html>
EOF

  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_length(length($html));
  $res->body($html);
  $res->headers->content_type('text/html');

  my $bot = WWW::Crawler::Mojo->new;
  $bot->init;
  $bot->enqueue($_) for ($bot->scrape($res, new_job('http://example.com/')));

  my $job;
  $job = $bot->queue->dequeue;
  is $job->literal_uri,      '',                                'right url';
  is $job->url,              'http://example.com/?foo=default', 'right url';
  is $job->method,           'GET',                             'right method';
  is_deeply $job->tx_params, undef,                             'right params';
  $job = $bot->queue->dequeue;
  is $job, undef, 'no more urls';
}

sub new_job {
  return WWW::Crawler::Mojo::Job->new(url => shift);
}
