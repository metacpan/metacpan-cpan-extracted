
use Mojolicious::Lite;
get '/' => 'index';
app->start;

1;

__DATA__

@@index.html.ep

<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">

<div id="one">
    <span class="six">Mooo</span>
</div>
<div id="two">
    <div id="three">
        <div id="four">
            <span class="five">Hello!</span>
        </div>
    </div>
</div>