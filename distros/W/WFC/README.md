# WFC

**WFC (WebForms Core)** is a web development technology owned and developed by [Elanat](https://elanat.net). It provides a server-orchestrated approach for building interactive web interfaces, consisting of a server-side **WebForms** class and the client-side **WebFormsJS** browser runtime.

This Perl implementation package provides the **WebForms** class for the server side of WebForms Core. It generates WebForms Core commands that are returned to the browser and executed by WebFormsJS.

## Installation

Install WFC from CPAN using `cpanm`:

```bash
cpanm WFC
```

After installation, import the `WebForms` class:

```perl
use WebForms;
```

## Requirements

* Perl 5.36.0 or later
* WebFormsJS 2.1 or later

WFC consists of two cooperating parts:

```text
Server → WebForms → Commands → WebFormsJS → HTML DOM
```

The Perl package provides the server-side `WebForms` class. **WebFormsJS** is the client-side runtime that receives and executes the generated commands in the browser.

## Usage with Mojolicious

The following example demonstrates using the WebForms Core Perl implementation with the Mojolicious framework:

```perl
use Mojolicious::Lite;
use WebForms;

post '/' => sub {
    my $c = shift;

    my $name = $c->param('txt_Name');
    my $backgroundColor = $c->param('txt_BackgroundColor');
    my $fontSize = $c->param('txt_FontSize');

    my $form = WebForms->new;

    $form->set_font_size(InputPlace::tag('form'), "${fontSize}px");
    $form->set_background_color(InputPlace::tag('form'), $backgroundColor);
    $form->set_disabled(InputPlace::name('btn_SetBodyValue'), 1);

    $form->add_tag(InputPlace::tag('form'), 'h3');
    $form->set_text(InputPlace::tag('h3'), "Welcome $name!");

    $c->render(text => $form->response());
};

get '/' => sub {
    my $c = shift;

    $c->render(text => <<'HTML');
<!DOCTYPE html>
<html>
<head>
  <title>Using WebForms Core in Perl</title>
  <script type="text/javascript" src="/script/web-forms.js"></script>
</head>
<body>
    <form method="post" action="/">
        <label for="txt_Name">Your Name</label>
        <input name="txt_Name" id="txt_Name" type="text" />
        <br>
        <label for="txt_FontSize">Set Font Size</label>
        <input name="txt_FontSize" id="txt_FontSize" type="number" value="16" min="10" max="36" />
        <br>
        <label for="txt_BackgroundColor">Set Background Color</label>
        <input name="txt_BackgroundColor" id="txt_BackgroundColor" type="text" />
        <br>
        <input name="btn_SetBodyValue" type="submit" value="Click to send data" />
    </form>
</body>
</html>
HTML
};

app->start;
```

The initial `GET` request renders the complete HTML page. When the submit button is clicked, the `POST` request is handled by the server.

The server reads the submitted values, creates a `WebForms` instance, generates WebForms Core commands, and returns the generated response:

```perl
$c->render(text => $form->response());
```

WebFormsJS receives and executes these commands in the browser.

## WebFormsJS

WebFormsJS is the client-side browser runtime of WebForms Core. Include it in your HTML page:

```html
<script type="text/javascript" src="/script/web-forms.js"></script>
```

The latest WebFormsJS file is available in the [WebForms Core repository](https://github.com/elanatframework/Web_forms/blob/elanat_framework/web-forms.js).

## WebForms Core Architecture

WebForms Core uses a server-orchestrated command architecture:

```text
Server → WebForms → Commands → WebFormsJS → HTML DOM
```

The `WebForms` class is responsible for generating commands on the server, while WebFormsJS receives and executes those commands in the browser.

The server and browser work together without requiring a separate front-end application.

## License

WFC is distributed under the MIT License.

Copyright © Elanat.