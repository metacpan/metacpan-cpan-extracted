# NAME

YATT::Lite::LRXML::Syntax - Loose but Recursive XML (LRXML) format.

# SYNOPSIS

    require YATT::Lite::LRXML;
    my $container = YATT::Lite::LRXML->load_from(string => <<'END');
    <!yatt:args x y>
    <h2>&yatt:x;</h2>
    &yatt:y;

    <!yatt:widget foo id x>
    <div id="&yatt:id;">
      &yatt:x;
    </div>
    END

# DESCRIPTION

Loose but Recursive XML (**LRXML**), which I'm defining here,
is an XML-like template format. LRXML is first used in
my template engine [YATT](https://metacpan.org/pod/YATT) and then extended in
my latest template engine [YATT::Lite](https://metacpan.org/pod/YATT%3A%3ALite).

LRXML format consists of **3 layers** of syntax definitions
which are ["LRXML multipart container"](#lrxml-multipart-container)
(or simply _container_),
["LRXML template"](#lrxml-template) (_template_)
and ["LRXML entity reference"](#lrxml-entity-reference) (_entref_).
A container can carry multiple parts.
Each part can have a boundary (header) and it can carry meta information
(usually used as a declaration) for the body of the part.
Each part can be a template or other type of text payload.
Entref can appear in templates and other text payload.

LRXML format only defines syntax and doesn't touch semantics,
like S-expression in Lisp.
Actually, the current implementation of [LRXML parser](https://metacpan.org/pod/YATT%3A%3ALite%3A%3ALRXML)
determines the types of each part by (predefined) _declaration keywords_
(such as _"widget"_, _"page"_, _"action"_...),
but the declaration keywords are **not** part of this LRXML format specification.
It is opened for each user of LRXML format.

## XXX: Brief introduction of LRXML

# FORMAT SPECIFICATION
 

## Syntax Notation (ABNF with negative-match)
 

In this document, I (roughly) use [ABNF](https://tools.ietf.org/html/rfc5234),
with some modifications/extensions.

- `[..]` means a character set, like regexp in perl5.

    In original ABNF, `[..]` means optional element.

- The operator "`?`" is equivalent of `*1` and indicates _optional element_.

    For optional element, I chose `?<elem>` instead of `[<elem>]`.

- The operator "` ¬ `" preceding an element indicates _negative-match_.

    If an element is written like:

        ¬ elem

    then this pattern matches _longest_ possible character sequence
    which do not match `elem`. This operator helps defining customizable namespace.

- Rule can take parameters.

    If left-hand-side of a rule definition consists of two or more words,
    it is a parametric rule. Parametric rule is used like `<rule Param>`.

        group C          =  *term C

        ...other rule... =   <group ")">

### Customizable namespace qualifier

In LRXML, every top-level constructs are marked by _namespace qualifier_
(or simply _namespace_).
Namespace can be customized to arbitrary set of words.
For simplicity, in this document, I put a "sample" definition of
customizable namespace rule `CNS` like:

    CNS             = ("yatt")

But every implementation of LRXML parser should allow overriding this rule like
following instead:

    CNS             = ("yatt" / "js" / "perl")

## BNF of LRXML multipart container


    lrxml-container = ?(lrxml-payload) *( lrxml-boundary lrxml-payload
                                        / lrxml-comment )

    lrxml-boundary  = "<!" CNS ":" NSNAME decl-attlist ">" EOL

    lrxml-comment   = "<!--#" CNS *comment-payload "-->"

    lrxml-payload   = ¬("<!" (CNS ":" / "#" CNS))

    decl-attlist    = *(1*WS / inline-comment / att-pair / decl-macro)

    inline-comment  = "--" comment-payload "--"

    comment-payload = *([^-] / "-" [^-])

    decl-macro      = "%" NAME *[0-9A-Za-z_:\.\-=\[\]\{\}\(,\)] ";"

    att-pair        = ?(NSNAME "=") att-value

    att-value       = squoted-att / dquoted-att / nested-att / bare-att

    squoted-att     = ['] *[^'] [']

    dquoted-att     = ["] *[^"] ["]

    nested-att      = '[' decl-attlist ']'

    bare-att        = 1*[^'"\[\]\ \t\n<>/=]

    NSNAME          = NAME *(":" NAME)

    NAME            = 1*[0-9A-Za-z_]

    WS              = [\ \t\n]

    EOL             = ?[\r] [\n]

Some notes on current spec and future changes:

- NAME may be allowed to contain unicode word.


    In current YATT::Lite, `NAME` can cotain `\w` in perl unicode semantics.

## BNF of LRXML template syntax
.

    lrxml-template   = ?(template-payload) *( (template-tag / lrxml-entref )
                                             ?(template-payload) )

    template-payload = ¬( tag-leader / ent-leader )

    tag-leader       = "<" ( CNS ":"
                           / "?" CNS
                           )

    ent-leader       = "&" ( CNS (":" / lcmsg )
                           / special-entity
                           )

    template-tag     = element / pi

    element          = "<" (single-elem / open-tag / close-tag) ">"

    pi               = "<?" CNS ?NSNAME pi-payload "?>"

    single-elem      = CNS NSNAME elem-attlist "/"

    open-tag         = CNS NSNAME elem-attlist

    close-tag        =  "/" CNS NSNAME *WS

    elem-attlist     = *(1*WS / inline-comment / att-pair)

    pi-payload       = *([^?] / "?" [^>])

## BNF of LRXML entity reference syntax
 

    lrxml-entref     = "&" ( CNS (pipeline / lcmsg)
                           / special-entity "(" <group ")">
                           )
                       ";"

    pipeline         = 1*( ":" NAME ?( "(" <group ")">)
                         / "[" <group "]">
                         / "{" <group "}">
                         )

    group CLO        = *ent-term CLO

    ent-term         = ( ","
                       / ( etext / pipeline ) ?[,:]
                       )

    etext            = etext-head *etext-body

    etext-head       = ( ETEXT *( ETEXT / ":" )
                       / paren-quote
                       )

    etext-body       = ( ETEXT *( ETEXT / ":" )
                       / paren-quote
                       / etext-any-group
                       )

    etext-any-group  = ( "(" <etext-group ")">
                       / "{" <etext-group "}">
                       / "[" <etext-group "]">
                       )

    etext-group CLO  = *( ETEXT / [:,] ) *etext-any-group CLO

    paren-quote      = "(" *( [^()] / paren-quote ) ")"

    lcmsg            = lcmsg-open / lcmsg-sep / lcmsg-close

    lcmsg-open       = ?("#" NAME) 2*"["

    lcmsg-sep        = 2*"|"

    lcmsg-close      = 2*"]"

    special-entity   = SPECIAL_ENTNAME

    ETEXT            = [^\ \t\n,;:(){}\[\]]

### Special entity name

_Special entity_ is another customizable syntax element.
For example, it is usually defined like:

    SPECIAL_ENTNAME  = ("HTML")

And then you can write `&HTML(:var);`.

But every implementation of LRXML parser should allow overriding this rule like
following instead:

    SPECIAL_ENTNAME  = ("HTML" / "JSON" / "DUMP")

# AUTHOR

"KOBAYASI, Hiroaki" <hkoba@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
