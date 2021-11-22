#pragma once
#include <memory>
#include <vector>
#include <panda/string.h>
#include <panda/string_view.h>

namespace panda { namespace uri { namespace router {

struct Regexp;
using RegexpPtr = std::unique_ptr<Regexp>;

struct Regexp {
    struct Symclass {
        struct Range {
            char from;
            char to;
        };
        string chars;
        std::vector<Range> ranges;
        bool inverse = false;
    };

    struct Token {
        enum class Type {Literal, Symclass, Group, Capture};
        Type type;
        string literal;
        Symclass symclass;
        RegexpPtr regexp;
    };

    struct Quant {
        int min = 1;
        int max = 1;
        bool is_default () const { return min == 1 && max == 1; }
    };

    struct Element {
        Token token;
        Quant quant;
    };

    struct Expression {
        std::vector<Element> elements;
    };

    std::vector<Expression> expressions;

    static RegexpPtr parse (string_view);

    void print (string pre = {}) const;

    string to_string () const;
};

}}}
