#!perl


#example source - http://api.jquery.com/parent/
#Example: Shows the parent of each element as (parent > child).
use strict;
use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);

jQuery("*", jQuery->document->body)->each(sub {
    my $parentTag = jQuery(this)->parent->get(0)->tagName;
    this->prepend(jQuery->document->createTextNode($parentTag . " > "));
});

print jQuery->as_HTML;

__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  div,p { margin:10px; }
  </style>
  
</head>
<body>
  <div>div, 
    <span>span, </span>
    <b>b </b>

  </div>
  <p>p, 
    <span>span, 
      <em>em </em>
    </span>
  </p>

  <div>div, 
    <strong>strong, 
      <span>span, </span>
      <em>em, 
        <b>b, </b>
      </em>

    </strong>
    <b>b </b>
  </div>
<script>

   
</script>

</body>
</html>
