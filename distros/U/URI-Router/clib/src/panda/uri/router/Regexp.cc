#include "Regexp.h"
#include <limits.h>
#include <panda/from_chars.h>

namespace panda { namespace uri { namespace router {

static inline void add_non_printable (string& ret, char c) {
    ret += "\\x";
    ret += "  ";
    auto p = ret.buf() + ret.length() - 2;
    auto res = panda::to_chars(p, p+2, (unsigned char)c, 16);
    assert(!res.ec);
    if (res.ptr == p + 1) {
        p[1] = p[0];
        p[0] = '0';
    }
}

static inline void literal_stringify (string& ret, char c) {
    if (isprint(c)) {
        switch (c) {
            case '.':
            case '[':
            case ']':
            case '(':
            case ')':
            case '?':
            case '*':
            case '+':
            case '{':
            case '}':
            case '\\':
                ret += "\\";
            default : ret += c; break;
        }
    }
    else add_non_printable(ret, c);
}

static inline string literal_stringify (const string& literal) {
    string ret(literal.length());
    for (auto c : literal) {
        switch (c) {
            case '.': ret += "\\."; break;
            default : literal_stringify(ret, c); break;
        }
    }
    return ret;
}

static inline void symclass_stringify (string& ret, char c) {
    if (isprint(c)) {
        switch (c) {
            case ']':
            case '[':
            case '\\':
            case '-':
                ret += "\\";
            default : ret += c; break;
        }
    }
    else add_non_printable(ret, c);
}

static inline string symclass_stringify (const string& chars) {
    string ret(chars.length());
    for (auto c : chars) symclass_stringify(ret, c);
    return ret;
}

static void print_symclass (const Regexp::Symclass& s) {
    printf("CHARS(%s), RANGES(", symclass_stringify(s.chars).c_str());
    for (size_t i = 0; i < s.ranges.size(); ++i) {
        printf("%d-%d", s.ranges[i].from, s.ranges[i].to);
        if (i < s.ranges.size() - 1) printf(",");
    }
    printf(")%s", s.inverse ? " INVERSE" : "");
}

static void print_token (const Regexp::Token& t, string pre) {
    printf("%s", pre.c_str());
    switch (t.type) {
        case Regexp::Token::Type::Literal:
            printf("LITERAL: %s\n", literal_stringify(t.literal).c_str());
            break;
        case Regexp::Token::Type::Symclass:
            printf("SYMCLASS: ");
            print_symclass(t.symclass);
            printf("\n");
            break;
        case Regexp::Token::Type::Group:
            printf("GROUP\n");
            t.regexp->print(pre + "  ");
            break;
        case Regexp::Token::Type::Capture:
            printf("CAPGROUP\n");
            t.regexp->print(pre + "  ");
            break;
    }
}

static void print_quant (const Regexp::Quant& q, string pre) {
    printf("%sQUANT: {%d,%d}\n", pre.c_str(), q.min, q.max);
}

static void print_element (const Regexp::Element& e, string pre) {
    printf("%sELEMENT: \n", pre.c_str());
    print_token(e.token, pre + "  ");
    print_quant(e.quant, pre + "  ");
}

static void print_expression (const Regexp::Expression& expr, string pre) {
    printf("%sEXPR: \n", pre.c_str());
    for (auto& element : expr.elements) {
        print_element(element, pre + "  ");
    }
}

void Regexp::print (string pre) const {
    printf("%sRE: \n", pre.c_str());
    for (size_t i = 0; i < expressions.size(); ++i) {
        print_expression(expressions[i], pre + "  ");
        if (i < expressions.size() - 1) printf("%sOR\n", pre.c_str());
    }
}

static inline bool cmp_range (const Regexp::Symclass& sc, std::initializer_list<Regexp::Symclass::Range> list) {
    if (sc.ranges.size() != list.size()) return false;
    size_t i = 0;
    for (auto r : list) {
        auto& r2 = sc.ranges[i++];
        if (r2.from != r.from || r2.to != r.to) return false;
    }
    return true;
}

string Regexp::to_string() const {
    string ret;
    for (size_t i = 0; i < expressions.size(); ++i) {
        auto& expr = expressions[i];
        for (auto& element : expr.elements) {
            auto& t = element.token;
            auto& q = element.quant;
            switch (t.type) {
                case Regexp::Token::Type::Literal:
                    ret += literal_stringify(t.literal);
                    break;
                case Regexp::Token::Type::Symclass: {
                    auto& sc = t.symclass;
                    if (!sc.inverse) {
                        if (!sc.chars) {
                            if (cmp_range(sc, {{CHAR_MIN, CHAR_MAX}}))              { ret += '.'; break; }
                            if (cmp_range(sc, {{'0', '9'}}))                        { ret += "\\d"; break; }
                            if (cmp_range(sc, {{CHAR_MIN,'0'-1},{'9'+1,CHAR_MAX}})) { ret += "\\D"; break; }
                            if (cmp_range(sc, {{CHAR_MIN, '0'-1},{'9'+1,'A'-1},{'Z'+1,'_'-1},{'_'+1,'a'-1},{'z'+1,CHAR_MAX}})) { ret += "\\W"; break; }
                            if (cmp_range(sc, {{CHAR_MIN,'\t'-1},{'\n'+1,'\r'-1},{'\r'+1,' '-1},{' '+1,'\v'-1},{'\v'+1,CHAR_MAX}})) { ret += "\\S"; break; }
                        }
                        if (!sc.ranges.size()) {
                            if (sc.chars == "\n")        { ret += "\\n"; break; }
                            if (sc.chars == "\r")        { ret += "\\r"; break; }
                            if (sc.chars == "\t\v")      { ret += "\\t"; break; }
                            if (sc.chars == " \n\r\t\v") { ret += "\\s"; break; }
                        }
                        if (sc.chars == "_" && cmp_range(sc, {{'a', 'z'}, {'A', 'Z'}, {'0', '9'}})) { ret += "\\w"; break; }
                    }
                    ret += '[';
                    if (sc.inverse) ret += '^';
                    ret += symclass_stringify(sc.chars);
                    for (auto& r : sc.ranges) {
                        symclass_stringify(ret, r.from);
                        ret += '-';
                        symclass_stringify(ret, r.to);
                    }
                    ret += ']';

                    break;
                }
                case Regexp::Token::Type::Group:
                    ret += "(?:";
                    ret += t.regexp->to_string();
                    ret += ')';
                    break;
                case Regexp::Token::Type::Capture:
                    ret += '(';
                    ret += t.regexp->to_string();
                    ret += ')';
                    break;
            }
            if (!q.is_default()) {
                if      (q.min == 0 && q.max ==  1) ret += '?';
                else if (q.min == 0 && q.max == -1) ret += '*';
                else if (q.min == 1 && q.max == -1) ret += '+';
                else {
                    ret += '{';
                    if (q.min != 0) ret += panda::to_string(q.min);
                    ret += ',';
                    if (q.max != -1) ret += panda::to_string(q.max);
                    ret += '}';
                }
            }
        }
        if (i < expressions.size() - 1) ret += '|';
    }
    return ret;
}

}}}
