
use utf8;
use Mojolicious::Lite;
get '/' => 'index';
any '/test' => sub {
    my $c = shift;

    $c->render( json => $c->req->params->to_hash );
};

get '/samepage' => 'samepage';
post '/samepage' => sub {
    my $c = shift;

    $c->render( json => $c->req->params->to_hash );
};

app->start;

1;

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>42</title>

<form action="/test" method="POST" id="one">
  <p>Test</p>
  <!-- The usual stuff -->
  <input type="text" name="a" value="A">
  <input type="text" name="a_disabled" value="A" disabled>
  <input type="checkbox" checked name="b" value="B">
  <input type="checkbox" name="c" value="C">
  <input type="checkbox" checked name="meows" value="42">
  <input type="radio" name="d" value="D">
  <input type="radio" checked name="e" value="E">
  <input type="radio" name="e" value="Z">
  <input type="hidden" name="$&quot;bar" value="42">
  <input type="hidden" name="©☺♥" value="24">
  <input type="hidden" name="empty_val" value="">
  <select name="f" multiple>
    <option value="F">G</option>
    <optgroup label="Options">
      <option>H</option>
      <option selected>I</option>
    </optgroup>
    <option value="J" selected>K</option>
  </select>
  <select name="n"><option>N</option></select>
  <select name="l"><option selected>L</option></select>
  <select name="l_disabled" disabled><option selected>L</option></select>
  <textarea name="m">M</textarea>
  <textarea name="m_disabled" disabled>M</textarea>
  <button name="o" value="O">No!</button>
  <input type="button" name="s" value="S">
  <input type="submit" name="p" value="P">
  <input type="image" src="/" name="z" alt="z">

  <!-- Multiple controls with same name -->
  <input type="text" name="mult_a" value="A">
  <input type="text" name="mult_a" value="B">
  <input type="checkbox" checked name="mult_b" value="C">
  <input type="checkbox" checked name="mult_b" value="D">
  <input type="checkbox" checked name="mult_b" value="E">

  <select name="mult_f" multiple>
    <option value="F">G</option>
    <optgroup label="Options">
      <option>H</option>
      <option selected>I</option>
    </optgroup>
    <option value="J" selected>K</option>
  </select>
  <select name="mult_f"><option selected>N</option></select>
  <textarea name="mult_m">M</textarea>
  <textarea name="mult_m">Z</textarea>
</form>
<form action="/test" id="two"><input type="submit" name="q" value="Q"></form>
<form action="/test" id="three"><input type="button" name="r" value="R"></form>
<form action="/test" id="four">
    <input type="image" src="/" name="z" alt="Z">
</form>
<form action="/test" id="five"></form>

@@samepage.html.ep
<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>47</title>

<form method="POST" id="one">
  <input type="text" name="a" value="A">
</form>
<form method="POST" action="" id="two">
  <input type="text" name="a" value="A">
</form>
