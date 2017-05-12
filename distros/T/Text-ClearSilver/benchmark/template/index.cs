<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="">
<head>
<meta name="XXXXX" content="<?cs var:_["message180"] ?>" />
<meta name="XXXXX" content="<?cs var:_["message92"] ?>" />
<link rel="START" href="/" />
<title>XXXXXX: <?cs var:_["message212"] ?></title>
</head>
<body>
<div id="XXXXX">
<div id="XXXXX">
  <div class="XXXXX">
    <div class="XXXXX">
      <h1><a href="/"><span>EXAMPLE</span></a></h1>
      <h2><?cs var:_["message212"] ?></h2>
    </div>

    <ul class="XXXXX">
      <li><a href="/"><?cs var:_["message13"] ?></a></li>
      <li><a href="/"><?cs var:_["message193"] ?></a></li>
      <?cs if:!user_exists ?>
      <li><a href="/"><?cs var:_["message187"] ?></a></li>
      <li><a href="/"><?cs var:_["message20"] ?></a></li>
      <?cs else ?>
      <li><a href="/"><?cs var:_["message117"] ?></a></li>
      <li><a href="/"><?cs var:_["message8"] ?></a></li>
      <?cs /if ?>
    </ul>

    <form class="XXXXX" action="XXXXX" method="get">
      <input class="XXXXX" type="text" name="XXXXX" value="<?cs var:data.query ?>" /><input class="XXXXX" type="message82" value="<?cs var:_["message160"] ?>" />
    </form>
  </div>

  <div class="XXXXX">
    <ul id="XXXXX" class="XXXXX">
      <li><a href="/"><?cs var:_["message45"] ?></a></li>
      <li><a href="/"><?cs var:_["message33"] ?></a></li>
      <li><a href="/"><?cs var:_["message151"] ?></a></li>
    </ul>
  </div>
</div>
<div id="XXXXX">
    <div id="XXXXX">
        <div id="XXXXX">
<div class="XXXXX">

<?cs each:row = data.twww.rows ?>
<?cs set:mxid = row.twid - 1 ?>
<?cs set:mine = (row.uid == user.id) ?>
<?cs if:first(row) ?>
<ul class="XXXXX">
<?cs /if ?>
  <li class="XXXXX">
    <div class="XXXXX">
    <?cs if:row.aid ?>
      <div class="XXXXX">
        <a href="/<?cs var:row.aid ?>/"><img src="<?cs var:row.puri ?>" width="100" height="100" alt="<?cs var:row.aname ?>" /></a>
      </div>
      <p>
          <a class="XXXXX" href="/<?cs var:row.aid ?>/"><?cs var:row.aname ?></a>
          <a class="XXXXX" href="/<?cs var:row.aid ?>/"><?cs var:row.count_user ?> <?cs var:_["message131"] ?></a>
          <a class="XXXXX" href="/<?cs var:row.aid ?>/"><?cs var:row.ctt ?> <?cs var:_["message178"] ?></a>
      </p>
      <p class="XXXXX">
        <?cs each:tag = row.tags ?>
        <a class="XXXXX" href="/<?cs var:url_escape(tag) ?>"><?cs var:tag ?></a>
        <?cs if:!last(tag) ?>,<?cs /if ?>
        <?cs /each ?>
      </p>
      <?cs /if ?>
      <div>
        <p class="XXXXX">
          <a class="XXXXX" href="/<?cs var:row.uid ?>/"><?cs var:row.nne ?></a>
          <?cs if:row.rto ?><a class="XXXXX" href="/<?cs var:row.rto ?>">Re:</a><?cs /if ?>
          <?cs var:(row.text) ?>
        </p>
      </div>
    </div>
    <?cs if:user.id ?>
    <div class="XXXXX">
      <?cs if:mine ?>
      <a href="/r?twid=<?cs var:row.twid ?>"><?cs var:_["message56"] ?></a>
      <?cs else ?>
      <a href="/a?rto=<?cs var:row.twid ?><?cs if:row.aid ?>&amp;aid=<?cs var:row.aid ?><?cs /if ?>"><?cs var:_["message210"] ?></a>
      <?cs /if ?>
    </div>
    <?cs /if ?>
  </li>
<?cs if:last(row) ?>
</ul>
<?cs /if ?>
<?cs /each ?>


<?cs if:mxid ?>
<p class="XXXXX"><a href="/?mxid=<?cs var:mxid ?>"><?cs var:_["message21"] ?></a></p>
<?cs /if ?>
</div>
        </div>
<div class="XXXXX" id="XXXXX">
  <h2><?cs var:_["message2"] ?></h2>

  <ul>
  <?cs each:row = widget.data.psps.rows ?>
    <li class="XXXXX"><a href="/<?cs var:row.aid ?>/"><img src="<?cs var:row.puri ?>" width="38" height="38" alt="<?cs var:row.aname ?>" /></a></li>
  <?cs /each ?>
  </ul>
</div>
<div class="XXXXX" id="XXXXX">
  <h2><?cs var:_["message78"] ?></h2>

  <ul>
  <?cs each:row = widget.data.pusrs.rows ?>
    <li class="XXXXX"><a href="/<?cs var:row.uid ?>/"><img class="XXXXX" src="<?cs if:row.avr ?>/image/user/avr/<?cs var:string.slice(row.avr, 0, 4) ?>/<?cs var:row.avr ?>.jpg<?cs else ?>/image/icon/default_avr.png<?cs /if ?>" width="22" height="22" alt="<?cs var:row.nne ?>" /></a></li>
  <?cs /each ?>
  </ul>
</div>
<div class="XXXXX" id="XXXXX">
  <h2><?cs var:_["message65"] ?></h2>
  <p class="XXXXX">
  <?cs each:tag = widget.data.tags ?>
  <a class="XXXXX" href="/<?cs var:url_escape(tag.string) ?>"><?cs var:tag.string ?></a>
  <?cs /each ?>
  </p>
</div>
    </div>
</div>
<div id="XXXXX">
<?cs if:string.find(ENV.REQUEST_URI, "/config/localize") == -1 ?>
  <form action="XXXXX" method="post">
    <p>
      <?cs var:_["message14"] ?>
      <select name="XXXXX">
      <?cs each:row = data.sstt.rows ?>
        <option value="<?cs var:row.stid ?>"><?cs var:row.native_name ?></option>
      <?cs /each ?>
      </select>
      <input type="hidden" name="XXXXX" value="<?cs var:ENV.REQUEST_URI ?>" />
      <input type="message82" value="<?cs var:_["message121"] ?>" />
    </p>
  </form>
<?cs /if ?>
<ul class="XXXXX">
  <li><a href="/">XXXXX</a></li>
  <li><a href="/"><?cs var:_["message202"] ?></a></li>
  <li><a href="/"><?cs var:_["message198"] ?></a></li>
  <li><a href="/"><?cs var:_["message216"] ?></a></li>
  <li><a href="/"><?cs var:_["message34"] ?></a></li>
</ul>
<p id="XXXXX">&copy; 2010 XXXXXX</p>
</div>
</div>
</body>
</html>
