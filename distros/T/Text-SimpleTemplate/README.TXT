NAME
     Text::SimpleTemplate - Yet another module for template processing

SYNOPSIS
     use Text::SimpleTemplate;

     $tmpl = new Text::SimpleTemplate;    # create processor object
     $tmpl->setq(TEXT => "hello, world"); # export data to template
     $tmpl->load($file);                  # loads template from named file
     $tmpl->pack(q{TEXT: <% $TEXT; %>});  # loads template from in-memory data

     print $tmpl->fill;                   # prints "TEXT: hello, world"

DESCRIPTION
    This is yet another library for template-based text generation.

    Template-based text generation is a way to separate program code and
    data, so non-programmer can control final result (like HTML) as desired
    without tweaking the program code itself. By doing so, jobs like website
    maintenance is much easier because you can leave program code unchanged
    even if page redesign was needed.

    The idea is simple. Whenever a block of text surrounded by '<%' and '%>'
    (or any pair of delimiters you specify) is found, it will be taken as
    Perl expression, and will be replaced by its evaluated result.

    Major goal of this library is simplicity and speed. While there're many
    modules for template processing, this module has near raw Perl-code
    (i.e., "s|xxx|xxx|ge") speed, while providing simple-to-use objective
    interface.

INSTALLATION / REQUIREMENTS
    This module requires Carp.pm and FileHandle.pm. Since these are standard
    modules, all you need is perl itself.

    For installation, standard procedure of

        perl Makefile.PL
        make
        make test
        make install

    should work just fine.

TEMPLATE SYNTAX AND USAGE
    Suppose you have a following template named "sample.tmpl":

        === Module Information ===
        Name: <% $INFO->{Name}; %>
        Description: <% $INFO->{Description}; %>
        Author: <% $INFO->{Author}; %> <<% $INFO->{Email}; %>>

    With the following code...

        use Safe;
        use Text::SimpleTemplate;

        $tmpl = new Text::SimpleTemplate;
        $tmpl->setq(INFO => {
            Name        => "Text::SimpleTemplate",
            Description => "Yet another module for template processing",
            Author      => "Taisuke Yamada",
            Email       => "tai\@imasy.or.jp",
        });
        $tmpl->load("sample.tmpl");

        print $tmpl->fill(PACKAGE => new Safe);

    ...you will get following result:

        === Module Information ===
        Name: Text::SimpleTemplate
        Description: Yet another module for template processing
        Author: Taisuke Yamada <tai@imasy.or.jp>

    As you might have noticed, any scalar data can be exported to template
    namespace, even hash reference or code reference.

    By the way, although I used "Safe" module in example above, this is not
    a requirement. However, if you want to control power of the template
    editor over program logic, its use is strongly recommended (see the Safe
    manpage for more).

DIRECT ACCESS TO TEMPLATE NAMESPACE
    In addition to its native interface, you can also access directly to
    template namespace.

        $FOO::text = 'hello, world';
        @FOO::list = qw(foo bar baz);

        $tmpl = new Text::SimpleTemplate;
        $tmpl->pack(q{TEXT: <% $text; %>, LIST: <% "@list"; %>});

        print $tmpl->fill(PACKAGE => 'FOO');

    While I don't recommend this style, this might be useful if you want to
    export list, hash, or subroutine directly without using reference.

METHODS
    Following methods are currently available.

    $tmpl = Text::SimpleTemplate->new;
        Constructor. Returns newly created object.

        If this method was called through existing object, cloned object
        will be returned. This cloned instance inherits all properties
        except for internal buffer which holds template data. Cloning is
        useful for chained template processing.

    $tmpl->setq($name => $data, $name => $data, ...);
        Exports scalar data ($data) to template namespace, with $name as a
        scalar variable name to be used in template.

        You can repeat the pair to export multiple sets in one operation.

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

        works. In case Safe module (or its subclass) was passed, its "reval"
        method will be used instead of built-in eval.

        OHANDLE option is for output selection. By default, this method
        returns the result of evaluation, but with OHANDLE option set, you
        can instead make it print to given handle. Either style of

            $tmpl->fill(OHANDLE => \*STDOUT);
            $tmpl->fill(OHANDLE => new FileHandle(...));

        is supported.

NOTES / BUGS
    Nested template delimiter will cause this module to fail.

CONTACT ADDRESS
    Please send any bug reports/comments to <tai@imasy.or.jp>.

AUTHORS / CONTRIBUTORS
     - Taisuke Yamada <tai@imasy.or.jp>
     - Lin Tianshan <lts@www.qz.fj.cn>

COPYRIGHT
    Copyright 1999-2001. All rights reserved.

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

