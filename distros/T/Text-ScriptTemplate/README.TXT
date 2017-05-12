NAME
     Text::ScriptTemplate - Standalone ASP/JSP/PHP-style template processor

SYNOPSIS
     use Text::ScriptTemplate;

     $text = <<'EOF';            # PHP/JSP/ASP-style template
     <% for (1..3) { %>          # - any Perl expression is supported
     Message is: <%= $TEXT %>.   # - also supports variable expansion
     <% } %>
     EOF

     $tmpl = new Text::ScriptTemplate;    # create processor object
     $tmpl->setq(TEXT => "hello, world"); # export data to template

     # load, fill, and print expanded result in single action
     print $tmpl->pack($text)->fill;

DESCRIPTION
    This is a successor of Text::SimpleTemplate, a module for template-
    based text generation.

    Template-based text generation is a way to separate program code and
    data, so non-programmer can control final result (like HTML) as desired
    without tweaking the program code itself. By doing so, jobs like website
    maintenance is much easier because you can leave program code unchanged
    even if page redesign was needed.

    The idea of this module is simple. Whenever a block of text surrounded
    by '<%' and '%>' (or any pair of delimiters you specify) is found, it
    will be taken as Perl expression, and will be handled specially by
    template processing engine. With this module, Perl script and text can
    be intermixed closely.

    Major goal of this library is to provide support of powerful PHP-style
    template with smaller resource. This is useful when PHP, Java/JSP, or
    Apache::ASP is overkill, but their template style is still desired.

INSTALLATION / REQUIREMENTS
    No other module is needed to use this module. All you need is perl
    itself.

    For installation, standard procedure of

        perl Makefile.PL
        make
        make test
        make install

    should work just fine.

TEMPLATE SYNTAX AND USAGE
    Any block surrounded by '<%=' and '%>' will be replaced with its
    evaluated result. So,

      <%= $message %>

    will expand to "hello" if $message variable contains "hello" at the time
    of evaluation (when "fill" method is called).

    For block surrounded by '<%' and '%>, it will be taken as a part of
    control structure. After all parts are merged into one big script, it
    get evaluated and its result will become expanded result. This means,

      <% for my $i (1..3) { %>
      i = <%= %i %>
      <% } %>

    will generate

      i = 1
      i = 2
      i = 3

    as a resulting output.

    Now, let's continue with more practical example. Suppose you have a
    following template named "sample.tmpl":

        === Module Information ===
        <% if ($HAS->{Text::ScriptTemplate}) { %>
        Name: <%= $INFO->{Name}; %>
        Description: <%= $INFO->{Description}; %>
        Author: <%= $INFO->{Author}; %> <<%= $INFO->{Email}; %>>
        <% } else { %>
        Text::ScriptTemplate is not installed.
        <% } %>

    With the following script...

        #!/usr/bin/perl

        use Safe;
        use Text::ScriptTemplate;

        $tmpl = new Text::ScriptTemplate;
        $tmpl->setq(INFO => {
            Name        => "Text::ScriptTemplate",
            Description => "Lightweight processor for full-featured template",
            Author      => "Taisuke Yamada",
            Email       => "tyamadajp\@spam.rakugaki.org",
        });
        $tmpl->setq(HAS => { Text::ScriptTemplate => 1 }); # installed
        $tmpl->load("sample.tmpl");

        print $tmpl->fill(PACKAGE => new Safe);

    ...you will get following result:

        === Module Information ===

        Name: Text::ScriptTemplate
        Description: Lightweight processor for full-featured template
        Author: Taisuke Yamada <tyamadajp@spam.rakugaki.org>

    If you change

        $tmpl->setq(HAS => { Text::ScriptTemplate => 1 }); # installed

    to

        $tmpl->setq(HAS => { Text::ScriptTemplate => 0 }); # not installed

    , then you will get

        === Module Information ===

        Text::ScriptTemplate is not installed.

    You can embed any control structure as long as intermixed text block is
    surround by set of braces. This means

        hello world<% if ($firsttime); %>

    must be written as

        <% do { %>hello world<% } if ($firsttime); %>

    to ensure surrounding block. If you want to know more on this internal,
    please read TEMPLATE INTERNAL section for the detail.

    Also, as you might have noticed, any scalar data can be exported to
    template namespace, even hash reference or code reference.

    Finally, although I had used "Safe" module in example above, this is not
    a requirement. Either of

        print $tmpl->fill(PACKAGE => new Safe);
        print $tmpl->fill(PACKAGE => new MyPackage);
        print $tmpl->fill(PACKAGE => 'MyOtherPackage');
        print $tmpl->fill; # uses calling context as package namespace

    will work. However, if you want to limit priviledge of program logic
    embedded in template, using Safe module as sandbox is recommended.

RESERVED NAMES
    Since template can be evaluated in separate namespace, this module does
    not have much restriction on variable or function name you define in
    theory.

    Currently reserved names are $self, and any other names starting with
    "_" (underscore). $self refers to instance of this module, and can be
    used to include sub-template in current template (see "include" method).

METHODS
    Following methods are currently available.

    $tmpl = new Text::ScriptTemplate;
        Constructor. Returns newly created object.

        If this method was called through existing object, cloned object
        will be returned. This cloned instance inherits all properties
        except for internal buffer which holds template data. Cloning is
        useful for chained template processing.

    $tmpl->setq($name => $data, $name => $data, ...);
        Exports scalar data ($data) to template namespace, with $name as a
        scalar variable name to be used in template. You can repeat the pair
        to export multiple sets in one operation.

        Returns object reference to itself.

    $tmpl->load($file, %opts);
        Loads template file ($file) for later evaluation. File can be
        specified in either form of pathname or fileglob.

        This method accepts DELIM option, used to specify delimiter for
        parsing template. It is speficied by passing reference to array
        containing delimiter pair, just like below:

            $tmpl->load($file, DELIM => [qw(<? ?>)]);

        Returns object reference to itself.

    $tmpl->pack($data, %opts);
        Loads in-memory data ($data) for later evaluation. Except for this
        difference, works just like $tmpl->load.

    $text = $tmpl->fill(%opts);
        Returns evaluated result of template, which was preloaded by either
        $tmpl->pack or $tmpl->load method.

        This method accepts two options: PACKAGE and OHANDLE.

        PACKAGE option specifies the namespace where template evaluation
        takes place. You can either pass the name of the package, or the
        package object itself. So either of

            $tmpl->fill(PACKAGE => new Safe);
            $tmpl->fill(PACKAGE => new Some::Module);
            $tmpl->fill(PACKAGE => 'Some::Package');
            $tmpl->fill; # uses calling context as evaluating namespace

        works. In case Safe module (or its subclass) was passed, its "reval"
        method will be used instead of built-in eval.

        OHANDLE option is for output selection. By default, this method
        returns the result of evaluation, but with OHANDLE option set, you
        can instead make it print to given handle. Either style of

            $tmpl->fill(OHANDLE => \*STDOUT);
            $tmpl->fill(OHANDLE => new FileHandle(...));

        is supported.

    $text = $tmpl->include($file, \%vars, @args);
        This is a shortcut of doing

          $text = $tmpl->new->load($file)->setq(%vars)->fill(@args);

        Why a shortcut? Because this will allow you to write

          <%= $self->include("subtemplate.tmpl") %>

        which is much (visually) cleaner way to include other template
        fragment in current template.

TEMPLATE INTERNAL
    Internally, template processor converts template into one big perl
    script, and then simply executes it. Conversion rule is fairly simple -
    If you have following template,

        <% if ($bool) { %>
        hello, <%= $name; %>
        <% } %>

    it will be converted into

        if ($bool) {
            $_handle->(q{
        hello, });
            $_handle->(do{ $name; });
            $_handle->(q{
        });
        }

    Note line breaks are preserved. After all conversion is done, it will be
    executed. And depending on existance of OHANDLE option, $_handle (this
    is a code reference to predefined function) will either print or buffer
    its argument.

NOTES / BUGS
    Nested template delimiter will cause this module to fail. In another
    word, don't do something like

      <%= "<%=" %>

    as it'll fail template parsing engine.

SEE ALSO
    Safe and Text::SimpleTemplate

CONTACT ADDRESS
    Please send any bug reports/comments to <tyamadajp@spam.rakugaki.org>.

    NOTE: You need to replace "spam" to "list" in above email address before
    sending.

AUTHORS / CONTRIBUTORS
     - Taisuke Yamada <tyamadajp@spam.rakugaki.org>

COPYRIGHT
    Copyright 2001-2004. All rights reserved.

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

