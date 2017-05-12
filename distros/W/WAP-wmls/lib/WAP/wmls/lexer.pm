#
#           WMLScript Language Specification Version 1.1
#
#   Lexer module
#

package WAP::wmls::lexer;

use strict;
use warnings;
use bigint;
use bignum;

sub _DoubleStringLexer {
    my ($parser) = @_;
    my $str = q{};
    my $type = 'STRING_LITERAL';

    while ($parser->YYData->{INPUT}) {

        for ($parser->YYData->{INPUT}) {

            s/^\"//
                and return ($type, $str);

            s/^([^"\\]+)//
                and $str .= $1,
                    last;

            s/^\\(['"\\\/])//
                and $str .= $1,     #  single quote, double quote, backslash, slash
                    last;
            s/^\\b//
                and $str .= "\b",   # backspace
                    last;
            s/^\\f//
                and $str .= "\f",   # form feed
                    last;
            s/^\\n//
                and $str .= "\n",   # new line
                    last;
            s/^\\r//
                and $str .= "\r",   # carriage return
                    last;
            s/^\\t//
                and $str .= "\t",   # horizontal tab
                    last;
            if ($type eq 'UTF8_STRING_LITERAL') {
                s/^\\([0-7]{1,2})//
                    and $str .= chr oct $1,
                        last;
                s/^\\([0-3][0-7]{2})//
                    and $str .= chr oct $1,
                        last;
                s/^\\x([0-9A-Fa-f]{2})//
                    and $str .= chr hex $1,
                        last;
            }
            else {
                if ($parser->YYData->{encoding} eq 'iso-8859-1') {
                    s/^\\([0-7]{1,2})//
                        and $str .= chr oct $1,
                            last;
                    s/^\\([0-3][0-7]{2})//
                        and $str .= chr oct $1,
                            last;
                    s/^\\x([0-9A-Fa-f]{2})//
                        and $str .= chr hex $1,
                            last;
                }
                else {
                    s/^\\([0-7]{1,2})//
                        and $type = 'UTF8_STRING_LITERAL',
                        and $str .= chr oct $1,
                            last;
                    s/^\\([0-3][0-7]{2})//
                        and $type = 'UTF8_STRING_LITERAL',
                        and $str .= chr oct $1,
                            last;
                    s/^\\x([0-9A-Fa-f]{2})//
                        and $type = 'UTF8_STRING_LITERAL',
                        and $str .= chr hex $1,
                            last;
                }
            }
            if ($type eq 'UTF8_STRING_LITERAL') {
                s/^\\u([0-9A-Fa-f]{4})//
                    and $str .= pack('U', hex $1),
                        last;
            }
            else {
                s/^\\u([0-9A-Fa-f]{4})//
                    and $type = 'UTF8_STRING_LITERAL',
                    and $str .= pack('U', hex $1),
                        last;
            }
            s/^\\//
                and $parser->Error("Invalid escape sequence $_ .\n"),
                    last;
        }
    }

    $parser->Error("Untermined string.\n");
    $parser->YYData->{lineno} ++;
    return ($type, $str);
}

sub _SingleStringLexer {
    my ($parser) = @_;
    my $str = q{};
    my $type = 'STRING_LITERAL';

    while ($parser->YYData->{INPUT}) {

        for ($parser->YYData->{INPUT}) {

            s/^'//
                and return ($type, $str);

            s/^([^'\\]+)//
                and $str .= $1,
                    last;

            s/^\\(['"\\\/])//
                and $str .= $1,     #  single quote, double quote, backslash, slash
                    last;
            s/^\\b//
                and $str .= "\b",   # backspace
                    last;
            s/^\\f//
                and $str .= "\f",   # form feed
                    last;
            s/^\\n//
                and $str .= "\n",   # new line
                    last;
            s/^\\r//
                and $str .= "\r",   # carriage return
                    last;
            s/^\\t//
                and $str .= "\t",   # horizontal tab
                    last;
            if ($type eq 'UTF8_STRING_LITERAL') {
                s/^\\([0-7]{1,2})//
                    and $str .= chr oct $1,
                        last;
                s/^\\([0-3][0-7]{2})//
                    and $str .= chr oct $1,
                        last;
                s/^\\x([0-9A-Fa-f]{2})//
                    and $str .= chr hex $1,
                        last;
            }
            else {
                if ($parser->YYData->{encoding} eq 'iso-8859-1') {
                    s/^\\([0-7]{1,2})//
                        and $str .= chr oct $1,
                            last;
                    s/^\\([0-3][0-7]{2})//
                        and $str .= chr oct $1,
                            last;
                    s/^\\x([0-9A-Fa-f]{2})//
                        and $str .= chr hex $1,
                            last;
                }
                else {
                    s/^\\([0-7]{1,2})//
                        and $type = 'UTF8_STRING_LITERAL',
                        and $str .= chr oct $1,
                            last;
                    s/^\\([0-3][0-7]{2})//
                        and $type = 'UTF8_STRING_LITERAL',
                        and $str .= chr oct $1,
                            last;
                    s/^\\x([0-9A-Fa-f]{2})//
                        and $type = 'UTF8_STRING_LITERAL',
                        and $str .= chr hex $1,
                            last;
                }
            }
            if ($type eq 'UTF8_STRING_LITERAL') {
                s/^\\u([0-9A-Fa-f]{4})//
                    and $str .= pack('U', hex $1),
                        last;
            }
            else {
                s/^\\u([0-9A-Fa-f]{4})//
                    and $type = 'UTF8_STRING_LITERAL',
                    and $str .= pack('U', hex $1),
                        last;
            }
            s/^\\//
                and $parser->Error("Invalid escape sequence $_ .\n"),
                    last;
        }
    }

    $parser->Error("Untermined string.\n");
    $parser->YYData->{lineno} ++;
    return ($type, $str);
}

sub _Identifier {
    my ($parser, $ident) = @_;

    if (exists $parser->YYData->{keyword}{$ident}) {
        return ($parser->YYData->{keyword}{$ident}, $ident);
    }
    elsif (exists $parser->YYData->{invalid_keyword}{$ident}) {
        $parser->Error("Invalid keyword '$ident'.\n");
    }
    return ('IDENTIFIER', $ident);
}

sub _OctInteger {
    my ($parser, $str) = @_;

    my $val = 0;
    foreach (split //, $str) {
        $val = $val * 8 + oct $_;
    }
    return ('INTEGER_LITERAL', $val);
}

sub _HexInteger {
    my ($parser, $str) = @_;

    my $val = 0;
    foreach (split //, $str) {
        $val = $val * 16 + hex $_;
    }
    return ('INTEGER_LITERAL', $val);
}

sub _CommentLexer {
    my ($parser) = @_;

    while (1) {
            $parser->YYData->{INPUT}
        or  $parser->YYData->{INPUT} = readline $parser->YYData->{fh}
        or  return;

        for ($parser->YYData->{INPUT}) {
            s/^\n//
                    and $parser->YYData->{lineno} ++,
                    last;
            s/^\*\///
                    and return;
            s/^.//
                    and last;
        }
    }
}

sub _DocLexer {
    my ($parser) = @_;

    $parser->YYData->{doc} = q{};
    my $flag = 1;
    while (1) {
            $parser->YYData->{INPUT}
        or  $parser->YYData->{INPUT} = readline $parser->YYData->{fh}
        or  return;

        for ($parser->YYData->{INPUT}) {
            s/^(\n)//
                    and $parser->YYData->{lineno} ++,
                        $parser->YYData->{doc} .= $1,
                        $flag = 0,
                        last;
            s/^\*\///
                    and return;
            unless ($flag) {
                s/^\*//
                        and $flag = 1,
                        last;
            }
            s/^([ \r\t\f\013]+)//
                    and $parser->YYData->{doc} .= $1,
                    last;
            s/^(.)//
                    and $parser->YYData->{doc} .= $1,
                    $flag = 1,
                    last;
        }
    }
}

sub Lexer {
    my ($parser) = @_;

    while (1) {
            $parser->YYData->{INPUT}
        or  $parser->YYData->{INPUT} = readline $parser->YYData->{fh}
        or  return ('', undef);

        for ($parser->YYData->{INPUT}) {

            s/^[ \r\t\f\013]+//;                            # Whitespace
            s/^\n//
                    and $parser->YYData->{lineno} ++,
                        last;

            s/^\/\*\*//                                     # documentation
                    and _DocLexer($parser),
                        last;

            s/^\/\*//                                       # MultiLineComment
                    and _CommentLexer($parser),
                        last;
            s/^\/\/(.*)\n//                                 # SingleLineComment
                    and $parser->YYData->{lineno} ++,
                        last;

            s/^([0-9]+\.[0-9]+[Ee][+\-]?[0-9]+)//
                    and return ('FLOAT_LITERAL', $1);
            s/^([0-9]+[Ee][+\-]?[0-9]+)//
                    and return ('FLOAT_LITERAL', $1);
            s/^(\.[0-9]+[Ee][+\-]?[0-9]+)//
                    and return ('FLOAT_LITERAL', $1);
            s/^([0-9]+\.[0-9]+)//
                    and return ('FLOAT_LITERAL', $1);
            s/^([0-9]+\.)//
                    and return ('FLOAT_LITERAL', $1);
            s/^(\.[0-9]+)//
                    and return ('FLOAT_LITERAL', $1);

            s/^0([0-7]+)//
                    and return _OctInteger($parser, $1);
            s/^0[Xx]([A-Fa-f0-9]+)//
                    and return _HexInteger($parser, $1);
            s/^(0)//
                    and return ('INTEGER_LITERAL', $1);
            s/^([1-9][0-9]*)//
                    and return ('INTEGER_LITERAL', $1);

            s/^\"//
                    and return _DoubleStringLexer($parser);

            s/^\'//
                    and return _SingleStringLexer($parser);

            s/^([A-Z_a-z][0-9A-Z_a-z]*)//
                    and return _Identifier($parser, $1);

            s/^(\+=)//
                    and return ($1, $1);
            s/^(\-=)//
                    and return ($1, $1);
            s/^(\*=)//
                    and return ($1, $1);
            s/^(\/=)//
                    and return ($1, $1);
            s/^(&=)//
                    and return ($1, $1);
            s/^(\|=)//
                    and return ($1, $1);
            s/^(\^=)//
                    and return ($1, $1);
            s/^(%=)//
                    and return ($1, $1);
            s/^(<<=)//
                    and return ($1, $1);
            s/^(>>=)//
                    and return ($1, $1);
            s/^(>>>=)//
                    and return ($1, $1);
            s/^(div=)//
                    and return ($1, $1);
            s/^(&&)//
                    and return ($1, $1);
            s/^(\|\|)//
                    and return ($1, $1);
            s/^(\+\+)//
                    and return ($1, $1);
            s/^(\-\-)//
                    and return ($1, $1);
            s/^(<<)//
                    and return ($1, $1);
            s/^(>>>)//
                    and return ($1, $1);
            s/^(>>)//
                    and return ($1, $1);
            s/^(<=)//
                    and return ($1, $1);
            s/^(>=)//
                    and return ($1, $1);
            s/^(==)//
                    and return ($1, $1);
            s/^(!=)//
                    and return ($1, $1);

            s/^([=><,!~\?:\.\+\-\*\/&\|\^%\(\)\{\};#])//
                    and return ($1, $1);                    # punctuator

            s/^([\S]+)//
                    and $parser->Error("lexer error $1.\n"),
                        last;
        }
    }
}

sub InitLexico {
    my ($parser) = @_;

    my %keywords = (
        # Literal
        'true'          =>  'TRUE_LITERAL',
        'false'         =>  'FALSE_LITERAL',
        'invalid'       =>  'INVALID_LITERAL',
        # Keyword
        'access'        =>  'ACCESS',
        'agent'         =>  'AGENT',
        'break'         =>  'BREAK',
        'continue'      =>  'CONTINUE',
        'div'           =>  'DIV',
        'domain'        =>  'DOMAIN',
        'else'          =>  'ELSE',
        'equiv'         =>  'EQUIV',
        'extern'        =>  'EXTERN',
        'for'           =>  'FOR',
        'function'      =>  'FUNCTION',
        'header'        =>  'HEADER',
        'http'          =>  'HTTP',
        'if'            =>  'IF',
        'isvalid'       =>  'ISVALID',
        'meta'          =>  'META',
        'name'          =>  'NAME',
        'path'          =>  'PATH',
        'return'        =>  'RETURN',
        'typeof'        =>  'TYPEOF',
        'use'           =>  'USE',
        'user'          =>  'USER',
        'var'           =>  'VAR',
        'while'         =>  'WHILE',
        'url'           =>  'URL',
    );
    my %invalid_keywords = (
        # Keyword not used
        'delete'        =>  'DELETE',
        'in'            =>  'IN',
        'lib'           =>  'LIB',
        'new'           =>  'NEW',
        'null'          =>  'NULL',
        'this'          =>  'THIS',
        'void'          =>  'VOID',
        'with'          =>  'WITH',
        # Future reserved word
        'case'          =>  'CASE',
        'catch'         =>  'CATCH',
        'class'         =>  'CLASS',
        'const'         =>  'CONST',
        'debugger'      =>  'DEBUGGER',
        'default'       =>  'DEFAULT',
        'do'            =>  'DO',
        'enum'          =>  'ENUM',
        'export'        =>  'EXPORT',
        'extends'       =>  'EXTENDS',
        'finally'       =>  'FINALLY',
        'import'        =>  'IMPORT',
        'private'       =>  'PRIVATE',
        'public'        =>  'PUBLIC',
        'sizeof'        =>  'SIZEOF',
        'struct'        =>  'STRUCT',
        'super'         =>  'SUPER',
        'switch'        =>  'SWITCH',
        'throw'         =>  'THROW',
        'try'           =>  'TRY',
    );

    $parser->YYData->{keyword} = \%keywords;
    $parser->YYData->{invalid_keyword} = \%invalid_keywords;
    return;
}

1;

