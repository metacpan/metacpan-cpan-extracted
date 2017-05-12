#!\perl

use Test::More 'no_plan';

use jQuery;

my $html = do { local $/; <DATA> };

jQuery->new($html);


my $parentEls = jQuery("b")->parents()->map( sub { 
    return this->tagName; 
})->get()->join(", ");

jQuery("b")->append("<strong>" . $parentEls . "</strong>");

my $val = jQuery('b')->find('strong')->text();

is ($val,'span, p, div, body, html');


__DATA__
<!DOCTYPE html>
<html>
<head>
  <style>
  b, span, p, html body {
    padding: .5em;
    border: 1px solid;
  }
  b { color:blue; }
  strong { color:red; }
  </style>
 
</head>
<body>
  <div>
    <p>
      <span>
        <b>My parents are: </b>
      </span>

    </p>
  </div>
<script>


</script>

</body>
</html>