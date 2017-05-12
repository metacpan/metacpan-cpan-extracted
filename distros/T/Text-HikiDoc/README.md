# NAME

Text::HikiDoc - Pure Perl implementation of 'HikiDoc' which is a text-to-HTML conversion tool.

# SYNOPSIS

    use Text::HikiDoc;

    # $text = '!Title';
    # $html = '<h1>Title</h1>';

    $obj = Text::HikiDoc->new();
    $html = $obj->to_html($text);

    or

    $obj = Text::HikiDoc->new($text);
    $html = $obj->to_html();



    # $text = "!Title\n----\n!!SubTitle";
    # $html = "<h2>Title</h2>\n<hr />\n<h3>SubTitle</h3>\n";

    $obj = Text::HikiDoc->new({
                               string => $text,
                               level => 2,
                               empty_element_suffix => ' />',
                               br_mode => 'true',
                               table_border => 'false',
                              });

    or

    $obj = Text::HikiDoc->new($text, 2, ' />', 'true', 'false');

    $html = $obj->to_html();

    # $text = "!Title\n----\n!!SubTitle\nhogehoge{{br}}fugafuga";
    # $html = "<h1>Title</h1>\n<hr />\n<h2>SubTitle</h2>\n<p>hogehoge<br />fugafuga</p>\n";

    $obj = Text::HikiDoc->new();
    $obj->enable_plugin('br');
    $html = $obj->to_html($text);

    $obj->enable_plugin('br','ins');
    @plugins = $obj->plugin_list; # br, ins
    $obj->is_enabled('br'); # 1
    $obj->is_enabled('pr'); # 0



# DESCRIPTION

'HikiDoc' is a text-to-HTML conversion tool for web writers. The original 'HikiDoc' is Ruby implementation.

This library is pure perl implementation of 'HikiDoc', and has interchangeability with the original.

# Methods

## new

    This method creates a new HikiDoc object. The following parameters are accepted.

    - string

        Set text data.

    - level

        Set headings level. Default setting is '1'. If you set '2', heading tags will start '<h2>'.

    - empty\_element\_suffix

        Set empty element suffix. Default setting is ' />'.

        ex. Default horizontal line is '<hr />'. You can change it '<hr>' If you set '>'.

    - br\_mode

        When br\_mode is 'true', changing line in paragraph is replaced 'br' tag. Default setting is 'false'.

        This is an original enhancing of this library that is not in the original 'HikiDoc'.

    - table\_border

        When table\_border is 'false', 'table' tag is '<table>'. When it is 'true', add 'border="1"' in table tag.
        Default setting is 'true'.

        This is an original enhancing of this library that is not in the original 'HikiDoc'.

## to\_html

    This method converts string to html

    - string

        Set text data. If 'string' is specified by both new() and to\_html(), to\_html is given to priority.

## enable\_plugin(@args)

    This method enables plugin module. '@args' is list of plugin names.

## plugin\_list

    This method returns array of enabled plugin lists.

## is\_enabled($str)

    This method returns 1 or 0. If enabled plugin "$str", return 1.

# Plugin

Text::HikiDoc can be enhanced by the plug-in. When you use the plug-in, enable\_plugin() is used.

## Text::HikiDoc::Plugin::aa

        {{aa "
                     (__)
                    (oo)
             /-------\/
            / |     ||
           *  ||----||
              ~~    ~~
        "}}

        is replaced with

        <pre class="ascii-art">
                     (__)
                    (oo)
             /-------\/
            / |     ||
           *  ||----||
              ~~    ~~
        </pre>

        If Text::HikiDoc::Plugin::texthighlight or Text::HikiDoc::Plugin::vimcolor is enabled, you can write

        <<< aa
                     (__)
                    (oo)
             /-------\/
            / |     ||
           *  ||----||
              ~~    ~~
        >>>

## Text::HikiDoc::Plugin::br

    {{br}}

    is replaced with 

    <br />

## Text::HikiDoc::Plugin::e

    {{e('hearts')}} {{e('9829')}}

    is replaced with

    &hearts; &\#9829;

## Text::HikiDoc::Plugin::ins

    {{ins 'insert part'}}

    is replaced with

    <ins>insert part</ins>

## Text::HikiDoc::Plugin::sub

    H{{sub('2')}}O

    is replaced with

    H<sub>2</sub>O

## Text::HikiDoc::Plugin::sup

    2{{sup(3)}}=8

    is replaced with

    2<sup>3</sup>=8

## Text::HikiDoc::Plugin::texthighlight

    Syntax color text is added to the pre mark. That uses Text::Highlight .

    The following, it is highlighted as the source code of Perl. When writing instead of"<<< Perl" as "<<<", it becomes a usual pre mark.

        <<< Perl
        sub dummy {
            $string = shift;
        

            $string =~ /$PLUGIN_RE/;
            print "s:$string\tm:$1\ta:$2\n";
            $a = $2;
            $a =~ s/^\s*(.*)\s*$/$1/;
        

            if ( $a =~ /($PLUGIN_RE)/ ) {
                &hoge($a);
            }
            return $string;
        }
        >>>

    NOTE: Method of mounting this plug-in will change in the future.

## Text::HikiDoc::Plugin::vimcolor

    Syntax color text is added to the pre mark. That uses Text::VimColor .

    NOTE: Method of mounting this plug-in will change in the future.

# SEE ALSO

- The original 'HikiDoc' site

    http://projects.netlab.jp/hikidoc/

- Text::HikiDoc::Plugin
- Text::HikiDoc::Plugin::aa
- Text::HikiDoc::Plugin::br
- Text::HikiDoc::Plugin::e
- Text::HikiDoc::Plugin::ins
- Text::HikiDoc::Plugin::sub
- Text::HikiDoc::Plugin::sup
- Text::HikiDoc::Plugin::texthighlight
- Text::HikiDoc::Plugin::vimcolor

# AUTHORS

The original 'HikiDoc' was written by Kazuhiko <kazuhiko@fdiary.net>

This release was made by Kawabata, Kazumichi (Higemaru) <kawabata@cpan.org> http://haro.jp/

# COPYRIGHT AND LICENSE

This library 'HikiDoc.pm' is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2006- Kawabata, Kazumichi (Higemaru) <kawabata@cpan.org>
