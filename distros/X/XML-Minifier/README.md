[![Build Status](https://travis-ci.org/thibaultduponchelle/XML-Minifier.svg?branch=master)](https://travis-ci.org/thibaultduponchelle/XML-Minifier) [![Actions Status](https://github.com/thibaultduponchelle/XML-Minifier/workflows/linux/badge.svg)](https://github.com/thibaultduponchelle/XML-Minifier/actions) [![Actions Status](https://github.com/thibaultduponchelle/XML-Minifier/workflows/macos/badge.svg)](https://github.com/thibaultduponchelle/XML-Minifier/actions) [![Actions Status](https://github.com/thibaultduponchelle/XML-Minifier/workflows/windows/badge.svg)](https://github.com/thibaultduponchelle/XML-Minifier/actions) [![Kritika Status](https://kritika.io/users/thibaultduponchelle/repos/thibaultduponchelle+XML-Minifier/heads/master/status.svg)](https://kritika.io/users/thibaultduponchelle/repos/thibaultduponchelle+XML-Minifier)
# NAME

XML::Minifier - A configurable XML minifier.

# WARNING

The API (option names) is almost stabilized (but not fully) and can therefore still change a bit.

# SYNOPSIS

Here is the simplest way to use XML::Minifier :

```perl
use XML::Minifier;

my $maxi = "<person>   <name>tib   </name>   <level>  42  </level>  <city>   </city>  </person>";
my $mini = minify($maxi);
```

But a typical use would include some parameters like this :

```perl
use XML::Minifier qw(minify);

my $maxi = "<person>   <name>tib   </name>   <level>  42  </level>  <city>   </city>  </person>";
my $mini = minify($maxi, no_prolog => 1, aggressive => 1);
```

That will produce :

```
<person><name>tib</name><level>42</level><city/></person>
```

**aggressive**, **destructive** and **insane** are shortcuts that define a set of parameters. 

You can set indivually with :

```perl
use XML::Minifier qw(minify);

my $maxi = "<person>   <name>tib   </name>   <level>  42  </level>  <city>   </city>  </person>";
my $mini = minify($maxi, no_prolog => 1, aggressive => 1, keep_comments => 1, remove_indent => 1);
```

The code above means "minify this string with aggressive mode BUT keep comments and in addition remove indent".

Not every parameter has a **keep\_** neither a **remove\_**, please see below for detailed list.

## DEFAULT MINIFICATION

The minifier has a predefined set of options enabled by default. 

They were decided by the author as relevant but you can disable individually with **keep\_** options.

- Merge elements when empty
- Remove DTD (configurable).
- Remove processing instructions (configurable)
- Remove comments (configurable).
- Remove CDATA (configurable).

In addition, the minifier will drop every blanks between the first level children. 
What you can find between first level children is not supposed to be meaningful data then we we can safely remove formatting here. 
For instance we can remove a carriage return between prolog and a processing instruction (or even inside a DTD).

In addition again, the minifier will _smartly_ remove blanks between tags. By _smart_ I mean that it will not remove blanks if we are in a leaf (more chances to be meaningful blanks) or if the node contains something that will persist (a _not removed_ comment/cdata/PI, or a piece of text not empty). The meaningfulness of blanks can be given by a DTD. Then if a DTD is present and \*protects some nodes\*, we oviously respect this. But you can decide to change this behaviour with \*\*ignore\_dtd\*\* option.

If there is no DTD (very often), we are blind and simply use the approach I just described above (keep blanks in leafs, remove blanks in nodes if all siblings contains only blanks).

Everything listed above is the default and should be perceived as almost lossyless minification in term of semantic (for humans). 

It's not completely if you consider these things as data, but in this case you simply can't minify as you can't touch anything ;)

## EXTRA MINIFICATION

In addition, you could enable mode **aggressive**, **destructive** or **insane** to remove characters in the text nodes (sort of "cleaning") : 

### Aggressive

- Remove empty text nodes.
- Remove starting blanks (carriage return, line feed, spaces...).
- Remove ending blanks (carriage return, line feed, spaces...).

### Destructive

- Remove indentation.
- Remove invisible spaces and tabs at the end of line.

### Insane

- Remove carriage returns and line feed into text nodes everywhere.
- Remove spaces into text nodes everywhere.

## OPTIONS

You can give various options:

- **expand\_entities**

    Expand entities. An entity is like 

    ```
    &foo; 
    ```

- **process\_xincludes**

    Process the xincludes. An xinclude is like 

    ```
    <xi:include href="inc.xml"/>
    ```

- **remove\_blanks\_start**

    Remove blanks (spaces, carriage return, line feed...) in front of text nodes. 

    For instance 

    ```
    <tag>    foo bar</tag> 
    ```

    will become 

    ```
    <tag>foo bar</tag>
    ```

    It is aggressive and therefore lossy compression.

- **remove\_blanks\_end**

    Remove blanks (spaces, carriage return, line feed...) at the end of text nodes. 

    For instance 

    ```
    <tag>foo bar    
       </tag> 
    ```

    will become 

    ```
    <tag>foo bar</tag>
    ```

    It is aggressive and therefore lossy compression.

- **remove\_spaces\_line\_start** or **remove\_indent**

    Remove spaces and tabs at the start of each line in text nodes. 
    It's like removing indentation actually.

    For instance 

    ```
    <tag>
           foo 
           bar    
       </tag> 
    ```

    will become 

    ```
    <tag>
    foo 
    bar
    </tag>
    ```

- **remove\_spaces\_line\_end**

    Remove spaces and tabs at the end of each line in text nodes.
    It's like removing invisible things.

- **remove\_empty\_text**

    Remove (pseudo) empty text nodes (containing only spaces, carriage return, line feed...). 

    For instance 

    ```
    <tag>

    </tag>
    ```

    will become 

    ```
    <tag/>
    ```

- **remove\_cr\_lf\_everywhere**

    Remove carriage returns and line feed everywhere (inside text !). 

    For instance 

    ```
    <tag>foo
    bar
    </tag> 
    ```

    will become 

    ```
    <tag>foobar</tag>
    ```

    It is aggressive and therefore lossy compression.

- **keep\_comments**

    Keep comments, by default they are removed. 

    A comment is something like :

    ```
    <!-- comment -->
    ```

- **keep\_cdata**

    Keep cdata, by default they are removed. 

    A CDATA is something like : 

    ```perl
    <![CDATA[ my cdata ]]>
    ```

- **keep\_pi**

    Keep processing instructions. 

    A processing instruction is something like :

    ```
    <?xml-stylesheet href="style.css"/>
    ```

- **keep\_dtd**

    Keep DTD.

- **ignore\_dtd**

    When set, the minifier will ignore informations from the DTD (typically where blanks are meaningfull)

    This option can be used with **keep\_dtd**, you can decide to get informations from DTD then remove it (or the contrary).

    Then I must repeat that **ignore\_dtd** is NOT the contrary of **keep\_dtd**

- **no\_prolog**

    Do not put prolog (having no prolog is aggressive for XML readers).

    Prolog is at the start of the XML file and look like this :

    ```
    <?xml version="1.0" encoding="UTF-8"?>
    ```

- **version**

    Specify version.

- **encoding**

    Specify encoding.

- **aggressive**

    Enable **aggressive** mode. Enables options **remove\_blanks\_starts**, **remove\_blanks\_end** and **remove\_empty\_text** if they are not defined only.
    Other options still keep their value.

- **destructive**

    Enable **destructive** mode. Enable options **remove\_spaces\_line\_starts** and **remove\_spaces\_line\_end** if they are not defined only.
    Enable also **aggressive** mode.
    Other options still keep their value.

- **insane**

    Enable **insane** mode. Enables options **remove\_cr\_lf\_everywhere** and **remove\_spaces\_everywhere** if they are not defined only.
    Enable also **destructive** mode and **aggressive** mode.
    Other options still keep their value.

# LICENSE

Copyright (C) Thibault DUPONCHELLE.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Thibault DUPONCHELLE
