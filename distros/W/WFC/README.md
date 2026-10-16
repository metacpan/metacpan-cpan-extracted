# WFC

**WFC** is the Perl implementation of the **WebForms Core Commander**. It provides the `WebForms` class for generating WebForms Core commands from Perl server-side applications.

## WebForms Core Architecture

WebForms Core consists of two main parts:

- **Commander** — WebForms classes implemented for different programming languages. Commanders generate WebForms Core commands that describe changes to the HTML document.
- **Executor** — **WebFormsJS**, the client-side JavaScript library that receives and executes those commands in the browser.

The Perl `WFC` implementation provides the **Commander** for Perl, while WebFormsJS provides the common browser-side Executor.

The WebFormsJS Executor is loaded into the HTML document:

```xml
<script type="module" src="/script/web-forms.js"></script>
```

WebForms Core is a technology developed by [Elanat](https://elanat.net).

## Installation

### Installation via CPAN

The Perl package is available on CPAN:

https://metacpan.org/dist/WFC

**Install using CPAN:**

```bash
cpanm WFC
```

After installation, import the `WebForms` class:

```perl
use WebForms;
```

or

**Download / Copy the File:**

https://github.com/webforms-core/WebFormsClasses/tree/elanat_framework/perl

After the direct download, reference the path to the `WebForms.pm` file as follows:

```perl
BEGIN {
    require './WebForms.pm';
}
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

The following example demonstrates how to use the WebForms Core Perl implementation in a Mojolicious server-side application.

```perl
use Mojolicious::Lite;
use WebForms;

post '/' => sub {
    my $c = shift;

    my $name = $c->param('txt_Name');
    my $backgroundColor = $c->param('txt_BackgroundColor');
    my $fontSize = $c->param('txt_FontSize');

    my $form = WebForms->new;

    $form->set_font_size(
        InputPlace::tag('form'),
        $fontSize . 'px'
    );

    $form->set_background_color(
        InputPlace::tag('form'),
        $backgroundColor
    );

    $form->set_disabled(
        InputPlace::name('btn_SetBodyValue'),
        1
    );

    $form->add_tag(
        InputPlace::tag('form'),
        'h3'
    );

    $form->set_text(
        InputPlace::tag('h3'),
        "Welcome $name!"
    );

    $c->render(text => $form->response());
};

get '/' => sub {
    my $c = shift;

    $c->render(text => <<'HTML');
<!DOCTYPE html>
<html>
<head>
    <title>Using WebForms Core in Perl</title>
    <script type="module" src="/script/web-forms.js"></script>
</head>
<body>
    <form method="post" action="/">

        <label for="txt_Name">Your Name</label>
        <input name="txt_Name" id="txt_Name" type="text">
        <br>

        <label for="txt_FontSize">Set Font Size</label>
        <input
            name="txt_FontSize"
            id="txt_FontSize"
            type="number"
            value="16"
            min="10"
            max="36"
        >
        <br>

        <label for="txt_BackgroundColor">
            Set Background Color
        </label>

        <input
            name="txt_BackgroundColor"
            id="txt_BackgroundColor"
            type="text"
        >
        <br>

        <input
            name="btn_SetBodyValue"
            type="submit"
            value="Click to send data"
        >
    </form>
</body>
</html>
HTML
};

app->start;
```

### How the Mojolicious Example Works

When the page is requested for the first time, the `GET /` route returns the complete HTML page. The page includes the WebFormsJS Executor:

```html
<script type="module" src="/script/web-forms.js"></script>
```

When the form is submitted, the `POST /` route receives the submitted form data through Mojolicious parameters:

```perl
my $name = $c->param('txt_Name');
my $backgroundColor = $c->param('txt_BackgroundColor');
my $fontSize = $c->param('txt_FontSize');
```

A `WebForms` instance is then created:

```perl
my $form = WebForms->new;
```

The application generates WebForms Core commands:

```perl
$form->set_font_size(
    InputPlace::tag('form'),
    $fontSize . 'px'
);

$form->set_background_color(
    InputPlace::tag('form'),
    $backgroundColor
);

$form->set_disabled(
    InputPlace::name('btn_SetBodyValue'),
    1
);
```

Additional commands modify the HTML document:

```perl
$form->add_tag(
    InputPlace::tag('form'),
    'h3'
);

$form->set_text(
    InputPlace::tag('h3'),
    "Welcome $name!"
);
```

Finally, the generated WebForms Core response is returned:

```perl
$c->render(text => $form->response());
```

WebFormsJS receives the response and executes the generated commands on the HTML DOM.

This allows a Mojolicious server-side application to control the client-side HTML document through WebForms Core commands without requiring JavaScript code for each individual UI operation.

### Sending Commands with the Initial HTML

WebForms Core commands can also be sent together with the initial HTML document. For this purpose, use `export_to_html_comment()` instead of `response()`.

`export_to_html_comment()` embeds the generated WebForms Core commands in an HTML comment. WebFormsJS detects these commands when the HTML document is loaded and executes them in the browser.

For example:

```perl
use Mojolicious::Lite;
use WebForms;

get '/' => sub {
    my $c = shift;

    my $form = WebForms->new;

    $form->set_background_color(
        InputPlace::tag('body'),
        'lightblue'
    );

    my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <title>WebForms Core</title>
    <script type="module" src="/script/web-forms.js"></script>
</head>
<body>
    <h1>Hello World!</h1>
</body>
</html>
HTML

    $c->render(
        text => $html . $form->export_to_html_comment()
    );
};

app->start;
```

In this example, the WebForms Core commands are generated on the server and appended to the initial HTML response as an HTML comment.

When WebFormsJS loads, it detects the commands in the HTML comment and executes them on the DOM.

Use `response()` when returning WebForms Core commands as the response to a request, such as a form submission. Use `export_to_html_comment()` when commands need to be included directly in the initial HTML document.


## WebFormsJS

WebFormsJS is the client-side JavaScript **Executor** of WebForms Core.

The latest WebFormsJS Executor is available here:

- WebFormsJS on Elanat: https://elanat.net/webforms-js
- WebFormsJS on GitHub: https://github.com/webforms-core/WebFormsJS

The npm package is also available:

https://www.npmjs.com/package/webformsjs

## License

WFC is distributed under the MIT License.

Copyright © Elanat.