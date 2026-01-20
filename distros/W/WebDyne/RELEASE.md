## WebDyne — Perl embedded HTML engine and mod_perl/PSGI web framework

**WebDyne** is a Perl-centric dynamic HTML engine for building server-rendered web applications with embedded Perl. It's been around for a while but I have recently re-written to support more modern practices, work with PSGI etc. Version 2 release is now available.

It supports multiple Perl embedding styles inside `.psp` files, partial compilation and caching for performance, and runs under **mod_perl** or **PSGI/Plack**.

Introduction below, full documentation is at [webdyne.org](https://webdyne.org), with code available on [CPAN](https://metacpan.org/dist/WebDyne) and via [Github](https://github.com/aspeer/WebDyne). Docker images are also available. The latest version at writing is 2.071, metaCPAN seems to throw up older versions sometimes.

Quick selected feature summary below to pique interest/dis-interest:

---

### Perl

Perl code can be embedded or called from a HTML page. Hello world type example:

```html
<start_html>
The local server time is: <? localtime() ?>
```

[Run](https://demo.webdyne.org/introduction2.psp)

The <start_html> tag is an optional shortcut - standard HTML is generated as output, and you can still use standard HTML tags if desired. These are all working syntax variations for embedding perl code into a HTML page. Note the use of the \_\_PERL\_\_ token to designate the end of the HTML page and start of (optional) page code.

```html
<start_html>
Server time is:
<pre>
<!-- tagged inline -->
<perl> localtime() </perl>

<!-- processing instructions -->
<? localtime() ?>

<!-- substitution -->
!{! localtime() !}

<!-- server side script -->
<script type="application/perl"> localtime() </script>

<!-- subroutine, direct output -->
<perl handler="time1"/>

<!-- subroutine, templated output -->
<perl handler="time2">
${time}
</perl>

</pre>
__PERL__
sub time1 { return localtime }
sub time2 { return shift()->render( time=>scalar localtime() ) }
```

[Run](https://demo.webdyne.org/release1.psp)

---

### Blocks

Blocks of text or html are supported for conditional rendering of page components.

```html
<start_html>
<p>
<perl handler=greeting>
<block name="morning">
Good morning, it is <? localtime ?>
</block>
<block name="evening">
Good evening, it is  <? localtime ?>
</block>
</perl>

__PERL__
sub greeting {
    my $self=shift();
    if ((localtime)[2] < 12) {
        $self->render_block('morning')
    }
    else {
        $self->render_block('evening')
    }
    return $self->render()
}
```

[Run](https://demo.webdyne.org/release2.psp)

Blocks can be nested and used for creating tables etc. 

------

### HTMX

One of the more interesting features - it can work with [htmx](https://htmx.org) by returning HTML fragments. This example shows everything in one page but htmx calls can be separated into their own pages if desired.

```html
<start_html script="https://unpkg.com/htmx.org@1.9.10">
Click button for current server time:
<button hx-get="#" hx-target="#time">Refresh</button>
<p>
<div id="time"><em>Time Not Loaded Yet</div>
<htmx perl>
return localtime
</htmx>
```

[Run](https://demo.webdyne.org/htmx_time4.psp)

---

### JSON

WebDyne can embed server generated JSON into output pages (within a &lt;script&gt;&lt;/script&gt; container)  to be used by client side Javascript. In this case the &lt;json&gt; tag will render into a &lt;script&gt; block of JSON data that will be used to drive a chart.

```html 
<start_html>
Mini Chart:
<p>
<canvas id="c" width="120" height="60"></canvas>
<json id=data handler=chart/>
<script>
  let d = JSON.parse(data.textContent), x = c.getContext("2d");
  x.fillStyle = "green";
  d.forEach((v, i) => x.fillRect(i*30, 60 - v*5, 20, v*5));
</script>

__PERL__

sub chart {
    my @data=(5, 12, 9, 7);
    return \@data
}
```

[Run](https://demo.webdyne.org/release3.psp)

------

### API Mode

Supports a lightweight API mode where JSON is returned in response to `Router::Simple` path matches

```html 
<api handler="change_case" pattern="/release4/{user}"/>
__PERL__
sub change_case {
    my ($self, $api_hr)=@_;
    my %data=(
        uppercase => uc($api_hr->{'user'}),
        lowercase => lc($api_hr->{'user'})
    );
    return \%data;
}
```

[Run](https://demo.webdyne.org/release4/BoB) (user Bob)

[Run](https://demo.webdyne.org/release4/Alice) (user Alice)

------

### CGI Mode

The original WebDyne made use of Lincoln Stein's CGI.pm. That is long obsoleted and this version does not use it - but some of the CGI.pm tags have been preserved and re-implemented. Here's a quick and dirty "Choose your country" form:

```html
<start_html title="Choose Country">
<form>
Your Country ?
<popup_menu values="!{! &countries() !}"  default="Australia">
</form>

__PERL__
use Locale::Country;
sub countries {
    my @countries = sort { $a cmp $b } all_country_names();
    return \@countries;
}
```

[Run](https://demo.webdyne.org/release5.psp)

---

### Docker

Docker images are available and can be used for base containers for self-containe applications. See simple [Perl Fortune app](https://github.com/aspeer/psp-WebDyne-Fortune) as an example.

---

### Install

```bash
# Install from CPAN, bare module
#
cpanm WebDyne

# Install everything needed to get started with Plack/PSGI
#
cpanm Task::WebDyne::Plack
```

Docs: https://webdyne.org  
CPAN: https://metacpan.org/dist/WebDyne  

---

Feedback and technical discussion welcome.
