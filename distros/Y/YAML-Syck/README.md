[![](https://github.com/toddr/YAML-Syck/workflows/linux/badge.svg)](https://github.com/toddr/YAML-Syck/actions) [![](https://github.com/toddr/YAML-Syck/workflows/macos/badge.svg)](https://github.com/toddr/YAML-Syck/actions) [![](https://github.com/toddr/YAML-Syck/workflows/windows/badge.svg)](https://github.com/toddr/YAML-Syck/actions)

# NAME 

YAML::Syck - Fast, lightweight YAML loader and dumper

# SYNOPSIS

    use YAML::Syck;

    # Set this for interoperability with other YAML/Syck bindings:
    # e.g. Load('Yes') becomes 1 and Load('No') becomes ''.
    $YAML::Syck::ImplicitTyping = 1;

    $data = Load($yaml);
    $yaml = Dump($data);

    # $file can be an IO object, or a filename
    $data = LoadFile($file);
    DumpFile($file, $data);

    # A string with multiple YAML streams in it
    $yaml = Dump(@data);
    @data = Load($yaml);

    # Dumping into a pre-existing output buffer
    my $yaml;
    DumpInto(\$yaml, @data);

# DESCRIPTION

This module provides a Perl interface to the **libsyck** data serialization
library.  It exports the `Dump` and `Load` functions for converting
Perl data structures to YAML strings, and the other way around.

**NOTE**: If you are working with other language's YAML/Syck bindings
(such as Ruby), please set `$YAML::Syck::ImplicitTyping` to `1` before
calling the `Load`/`Dump` functions.  The default setting is for
preserving backward-compatibility with `YAML.pm`.

# Differences Between YAML::Syck and YAML

## Error handling

Some calls are designed to die rather than returning YAML. You should wrap
your calls in eval to assure you do not get unexpected results.

# FLAGS

## $YAML::Syck::Headless

Defaults to false.  Setting this to a true value will make `Dump` omit the
leading `---\n` marker.

## $YAML::Syck::SortKeys

Defaults to false.  Setting this to a true value will make `Dump` sort
hash keys.

## $YAML::Syck::SingleQuote

Defaults to false.  Setting this to a true value will make `Dump` always emit
single quotes instead of bare strings.

## $YAML::Syck::ImplicitTyping

Defaults to false.  Setting this to a true value will make `Load` recognize
various implicit types in YAML, such as unquoted `true`, `false`, as well as
integers and floating-point numbers.  Otherwise, only `~` is recognized to
be `undef`.

## $YAML::Syck::ImplicitUnicode

Defaults to false.  For Perl 5.8.0 or later, setting this to a true value will
make `Load` set Unicode flag on for every string that contains valid UTF8
sequences, and make `Dump` return a unicode string.

Regardless of this flag, Unicode strings are dumped verbatim without escaping;
byte strings with high-bit set will be dumped with backslash escaping.

However, because YAML does not distinguish between these two kinds of strings,
so this flag will affect loading of both variants of strings.

If you want to use LoadFile or DumpFile with unicode, you are required to open
your own file in order to assure it's UTF8 encoded:

    open(my $fh, ">:encoding(UTF-8)", "out.yml");
    DumpFile($fh, $hashref);

## $YAML::Syck::ImplicitBinary

Defaults to false.  For Perl 5.8.0 or later, setting this to a true value will
make `Dump` generate Base64-encoded `!!binary` data for all non-Unicode
scalars containing high-bit bytes.

## $YAML::Syck::UseCode / $YAML::Syck::LoadCode / $YAML::Syck::DumpCode

These flags control whether or not to try and eval/deparse perl source code;
each of them defaults to false.

Setting `$YAML::Syck::UseCode` to a true value is equivalent to setting
both `$YAML::Syck::LoadCode` and `$YAML::Syck::DumpCode` to true.

## $YAML::Syck::LoadBlessed

Defaults to false. Setting to true will allow YAML::Syck to bless objects as it
imports objects. This default changed in 1.32.

You can create any kind of object with YAML. The creation itself is not the
critical part. If the class has a DESTROY method, it will be called once the
object is deleted. An example with File::Temp removing files can be found at
[https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=862373](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=862373)

# BUGS

Dumping Glob/IO values do not work yet.

Dumping of Tied variables is unsupported.

Dumping into tied (or other magic variables) with `DumpInto` might not work
properly in all cases.

# CAVEATS

This module implements the YAML 1.0 spec.  To deal with data in YAML 1.1, 
please use the `YAML::XS` module instead.

The current implementation bundles libsyck source code; if your system has a
site-wide shared libsyck, it will _not_ be used.

Tag names such as `!!perl/hash:Foo` is blessed into the package `Foo`, but
the `!hs/foo` and `!!hs/Foo` tags are blessed into `hs::Foo`.  Note that
this holds true even if the tag contains non-word characters; for example,
`!haskell.org/Foo` is blessed into `haskell.org::Foo`.  Please use
[Class::Rebless](https://metacpan.org/pod/Class::Rebless) to cast it into other user-defined packages. You can also
set the LoadBlessed flag false to disable all blessing.

This module has [a lot of known
issues](https://rt.cpan.org/Public/Dist/Display.html?Name=YAML-Syck)
and has only been semi-actively maintained since 2007. If you
encounter an issue with it probably won't be fixed unless you [offer
up a patch](http://github.com/toddr/YAML-Syck) in Git that's ready for
release.

There are still good reasons to use this module, such as better
interoperability with other syck wrappers (like Ruby's), or some edge
case of YAML's syntax that it handles better. It'll probably work
perfectly for you, but if it doesn't you may want to look at
[YAML::XS](https://metacpan.org/pod/YAML::XS), or perhaps at looking another serialization format like
[JSON](https://metacpan.org/pod/JSON).

# SEE ALSO

[YAML](https://metacpan.org/pod/YAML), [JSON::Syck](https://metacpan.org/pod/JSON::Syck)

[http://www.yaml.org/](http://www.yaml.org/)

# AUTHORS

Audrey Tang <cpan@audreyt.org>

# COPYRIGHT

Copyright 2005-2009 by Audrey Tang <cpan@audreyt.org>.

This software is released under the MIT license cited below.

The `libsyck` code bundled with this library is released by
"why the lucky stiff", under a BSD-style license.  See the `COPYING`
file for details.

## The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
