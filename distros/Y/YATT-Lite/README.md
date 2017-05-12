YATT::Lite - Template with "use strict" [![Build Status](https://travis-ci.org/hkoba/yatt_lite.png?branch=dev)](https://travis-ci.org/hkoba/yatt_lite)
==================

YATT is Yet Another Template Toolkit, strongly aimed at **static checking of
template errors**.  
[YATT::Lite] is the latest version of YATT, written in Pure Perl.

Note: Although I have been using YATT::Lite in some side-projects
for my client since 2011
(and previous version YATT.pm in all other main-projects
for them since late 2008),
I am not yet satisfied especially with its API.
Actually, I want to discuss *How web templates should be* with someone.
If you are interested in this topic, please contact me!


How YATT templates look like
--------------------

Biggest goal of YATT is to detect as many kinds of errors as possible
before it actually run. For example, YATT can detect
misspellings of template parameters and (so-called) widget names.
Following is an example of valid yatt template:

```xml
<!yatt:args who content>
<h2>Hello &yatt:who;!</h2>
<p>&yatt:content;</p>
<yatt:myfooter mycomp=who />

<!yatt:widget myfooter mycomp="?My Company">
&copy; 2013 &yatt:mycomp;, Inc.
```

If you misspell ``who``, ``content``, ``myfooter`` and/or ``mycomp`` above,
static check tool (``yatt lint``) detects them.  
You might think most good programmers don't do such mistakes.
If so, imagine who will write templates near future.
...Do you want to write templates by yourself, forever? I don't.
I want to employ designers and delegate all view related matters to them.
And, designers often do such mistakes.
Do you want to blame them everytime they misspelled? I don't.
Instead, I want to give them good safe-guard tools.
That's why I started to make YATT.

Minimum PSGI app example
--------------------

To have more chance to detect errors, YATT::Lite manages **set(s) of templates**
instead of single template. In other words,
YATT::Lite works like Virtual File System(VFS) of templates.  
Users of YATT::Lite will invoke ``$yatt->render($path,$args)``
with virtual template path + arguments
and get its output. Here is a minimum psgi app example of YATT::Lite:

```perl
use strict;
use FindBin;
use Plack::Request;
use Plack::Response;

use YATT::Lite::Factory;
my $yatt = YATT::Lite::Factory->new(doc_root => "$FindBin::Bin/html");

return $yatt if YATT::Lite::Factory->want_object; # To help yatt lint

return sub {
  my ($env) = @_;
  my $req  = Plack::Request->new($env);
  my $html = $yatt->render($env->{PATH_INFO}, $req->parameters);
  my $res  = Plack::Response->new(200);
  $res->content_type('text/html');
  $res->body($html);
  return $res->finalize;
};
```

Above code only serves ``*.yatt`` templates. To serve other static files
like ``*.css`` and ``*.gif``, your psgi app needs to analyze a request
and route it to other handler (ie. Plack::App::File) for static files.  
Since this is very common,
YATT::Lite comes with sample Web Framework([WebMVC0]) 
which directly behaves as [PSGI] application.
It also supports FastCGI and CGI too. With the WebMVC0,
minimum psgi app will look like following:

```perl
use strict;
use FindBin;

use YATT::Lite::WebMVC0::SiteApp -as_base;
my $yatt = MY->new(doc_root => "$FindBin::Bin/html");

return $yatt if MY->want_object; # To help yatt lint

return $yatt->to_app;
```


Followings are some comparison notes with other frameworks:

* Like PHP, (WebMVC0::SiteApp of) YATT::Lite integrates static contents
directory and (primary) template directory. It routes incoming requests
directly into ``*.yatt`` template files. Also, it can hide ``.yatt`` extension
by default (ie. if you have ``foo.yatt`` and
incoming request is ``foo``, ``foo/bar`` or ``foo/bar/baz``, the ``foo.yatt``
will be invoked).
Also, you can define url routing patterns and per-directory hooks.
You can use many abstraction techniques too.
Each templates are compiled on-the-fly and cached as perl scripts
so you can add/modify your templates while running your webapp.

* Unlike PHP and other template engines, YATT has quite HTML-like syntax. 
All YATT syntax items are *namespace-prefixed* equivalents
of HTML syntax items. i.e. ``<!yatt:...>`` for declarations,
``<yatt:...>`` for invocations, ``&yatt:...;`` for entity references
and ``<?perl...?>`` for (dirty ;-) processing instructions.
You can configure YATT to use project/team specific namespace prefix,
so designers can easily identify special tags.


One more example: Session
--------------------
You can wrap ``$yatt->to_app`` with other PSGI Middlewares, as usual.
To support session, here is how to wrap yatt by Plack::Middleware::Session.


```perl
use strict;
use FindBin;

use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity *CON/;
use YATT::Lite::PSGIEnv;

{
  my $yatt = MY->new(doc_root => "$FindBin::Bin/html");

  Entity session => sub {
    my ($this, $name, $default) = @_;
    my Env $env = $CON->env;
    $env->{'psgix.session'}{$name} // $default;
  };

  Entity set_session => sub {
    my ($this, $name, $value) = @_;
    my Env $env = $CON->env;
    $env->{'psgix.session'}{$name} = $value;
    '';
  };

  return $yatt if MY->want_object;

  use Plack::Builder;
  return builder {
    enable 'Session';
    $yatt->to_app;
  };
}
```


Now you can use two entity functions: 
``&yatt:session(name,default);`` and ``&yatt:set_session(name,value);``.

```xml
<!yatt:args user>
<yatt:if "&yatt:user;">

 set user as &yatt:user; <br>
 &yatt:set_session(user,:user);
 <a href="./">back</a>

<:yatt:else/>

 <h2>Hello, &yatt:session(user,((Unknown user)));</h2>
 <form>
   User name: <input name="user"><input type="submit">
 </form>

</yatt:if>
```


You can define entity functions in ``app.psgi`` and/or
per-directory ``.htyattrc.pl`` script.
Entity functions are used like ``&yatt:myfunc(..);``
anywhere in .yatt templates
to embed variables, process user parameters and access backend databases.

* Unlike Ruby-on-Rails and other major Web Frameworks,
YATT::Lite itself is Model-Agnostic.
In other words, YATT::Lite do not depend on any specific ORM.
So you can use your favorite ORMs.
(Actually, WebMVC0 contains some support for ORM ([DBIx::Class]),
but you are not limited to them.)

YATT focuses empowering Web Designers
--------------------

As described above, YATT is designed primarily to give
more power (with safety) to **Template Writers (Web Designers)**,
who are rarely trained as programmers.
With YATT, you can safely delegate more tasks to them.
(This means programmers can concentrate on fundamental infrastructure tasks
rather than view-related, biz-issue-specific, ad-hoc tasks.
And eventually, you might find
you can keep your programming team slim, fit and dense than others;-)

To make YATT easily understandable by Web Designers,
YATT has declarative, compositional semantics.
YATT allows them to define **new tags** (called *yatt widgets*).
So, from their point of view, YATT is just a seemless extension to HTML.

To give safety to Web Designers, YATT provides ``yatt lint``, 
which is integrated to [Emacs] via ``yatt-mode.el``.
Everytime they save a YATT template, yatt lint verifies it.
Syntax errors, spelling misses of variables, entities and widget names...
all such errors will be detected instantly,
and emacs will jump to the line of the error.

Also, YATT has many safer default behaviors, ie. automatic output escaping
based on argument type declaration and config file naming convention
which helps access restriction.


INSTALLATION
--------------------

You have several options to install YATT::Lite.

### Minimum setup one-liner

    $ mkdir myapp1
    $ cd myapp1
    $ curl https://raw.githubusercontent.com/hkoba/yatt_lite/dev/scripts/skels/min/install.sh | bash
    $ ls
    app.psgi  html  lib
    $ git status -su
    A  .gitmodules
    A  lib/YATT
    ?? app.psgi
    ?? html/index.yatt
    $ plackup

Above script also works from locally installed repo, like following:

    $ mkdir ../myapp2
    $ cd  ../myapp2
    $ ../myapp1/lib/YATT/scripts/skels/min/install.sh -l
    $ ls
    app.psgi  html  lib
    $

(with -l, lib/YATT is symlinked. without -l, uses git submodule)

### cpanm

If you simply want to use YATT::Lite only as a Perl module,
You can install YATT::Lite like other CPAN modules.

    $ cpanm YATT::Lite

Also, if you want to use latest version of YATT::Lite,
you can install YATT::Lite just through git command.
(But see [NON-STANDARD DIRECTORY STRUCTURE](#non-standard-directory-structure))

    $ git clone git://github.com/hkoba/yatt_lite.git lib/YATT
    $ (cd lib/YATT && cpanm --installdeps .)

    # or If your project is managed in git, clone as submodule like this:

    $ git submodule add git://github.com/hkoba/yatt_lite.git lib/YATT
    $ git submodule update --init
    $ (cd lib/YATT && cpanm --installdeps .)

To create a yatt-enabled webapp, just copy sample app.psgi and run plackup:

    $ cp lib/YATT/samples/app.psgi .
    $ mkdir html
    $ plackup

Now you are ready to write your first yatt app.
Open your favorite editor and create a yatt template ``html/index.yatt``
like this:

```xml
<!yatt:args x y>
<h2>Hello &yatt:x; world!</h2>
&yatt:y;
```


Then try to access:
  
     http://0:5000/
     http://0:5000/?x=foo
     http://0:5000/?x=foo&y=bar


## Emacs integration (yatt-mode.el and yatt-lint-any-mode.el)

Currently, there is no installer for yatt-mode.el yet.
It depends on ``mmm-mode.el`` and ``cperl-mode.el``,
so please install them manually if you don't have them.

After that, to use yatt-mode,
you may need to add something like following to your ``.emacs``
(assuming you cloned yatt_lite git repository as ~/perl5/lib/YATT):

```elisp
(load "~/perl5/lib/YATT/elisp/yatt-autoload.el")
```

This adds autoload definition of ``yatt-mode``.
It also adds ``yatt-lint-any-mode.el``, which can do save-time check
for other perl-related files (*.pm, *.pl...) too.


SUPPORT AND DOCUMENTATION
--------------------

You can look for Source Code Repository at:

    https://github.com/hkoba/yatt_lite


### Document viewer (ylpodview)

In source distribution, 
basic documents are placed under ``YATT/Lite/docs``. You can read them via:
https://yl-podview.herokuapp.com/
(But for now, most pods are not yet finished and written only in Japanese.)

Also, you can run ylpodview (POD viewer) locally by:

    $ cd lib
    $ plackup YATT/samples/ylpodview/approot/app.psgi

and try to access http://0:5000/

NON-STANDARD DIRECTORY STRUCTURE
--------------------

YATT::Lite distribution doesn't conform normal CPAN style 
directory structure. It works best when it is cloned as ``YATT/``
in one of your ``@INC`` directories. This is experimental,
but intentional. Because: 

1. I want to use YATT::Lite as a git submodule.
   IMHO, to make/keep web-framework useful,
   it is vitally important to allow evolution of each installation
   of the web-framework. And to make sure such evolution manageable,
   staying under git is most practical way for github hosted project.

2. To make such evolution safe, I need to bundle all test suits.
   Also, support scripts should be kept consistent with them.
   So, tests and scripts for yatt is placed under
   ``lib/YATT/t`` and ``lib/YATT/scripts``.


COPYRIGHT AND LICENCE
--------------------

Copyright (C) 2007..2014 "KOBAYASI, Hiroaki"

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

[YATT::Lite]: https://yl-podview.herokuapp.com/mod/YATT::Lite
[PSGI]: http://plackperl.org/
[WebMVC0]: https://yl-podview.herokuapp.com/mod/YATT::Lite::WebMVC0::SiteApp
[DBIx::Class]: https://yl-podview.herokuapp.com/mod/DBIx::Class
[Emacs]: http://www.gnu.org/software/emacs/
[cpanminus]: http://search.cpan.org/perldoc?App::cpanminus#INSTALL
