#include "Regexp.h"
#include <limits.h>
#include <panda/from_chars.h>

namespace panda { namespace uri { namespace router {

%%{
    machine regexp_parser;
    
    action mark {
        mark = p;
    }
    
    action expression_start {
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
    
    action expression_end {
        data->expression = nullptr;
    }
    
    action element_start {
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
    
    action element_end {
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
    
    action literal_end {
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
    
    action symclass_end {
        data->element->token.type = Regexp::Token::Type::Symclass;
        parse_symclass(string_view(mark, p - mark), data->element->token.symclass);
    }
    
    action special {
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
    
    action escaped_special {
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
    
    action group_start {
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+2);
        fcall group_regexp;
    }
    
    action group_end {
        data_stack.pop_back();
        data = &data_stack.back();
        fret;
    }
    
    action quant_end {
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
    
    escaped = "\\" (any - 'x');
    number  = digit+;
    
    symclass_char = (any - "\\" - "]") | escaped;
    symclass      = ("[" (symclass_char+) >mark %symclass_end "]");
    
    qnt_maybe  = "?" %{ num[0] = 0; num[1] = 1; };
    qnt_any    = "*" %{ num[0] = 0; num[1] = -1; };
    qnt_anynn  = "+" %{ num[0] = 1; num[1] = -1; };
    qnt_num0   = number >mark %{ nsave(num[0]); };
    qnt_num1   = number >mark %{ nsave(num[1]); };
    qnt_exact  = ("{" qnt_num0 "}") %{ num[1] = num[0]; };
    qnt_upto   = ("{," qnt_num1 "}") %{ num[0] = 0; };
    qnt_from   = ("{" qnt_num0 ",}") %{ num[1] = -1; };
    qnt_minmax = ("{" qnt_num0 "," qnt_num1 "}");
    quant      = (qnt_maybe | qnt_any | qnt_anynn | qnt_exact | qnt_upto | qnt_from | qnt_minmax) %quant_end;
    
    escaped_special = "\\" [dDwWsStnr] %escaped_special;
    special         = [.] %special;
    lichar = (any - [{}()+*?|] - "\\" - "[" - "]" - special) | (escaped - escaped_special);
    literal = (lichar+) >mark %literal_end;
    group = '(' @group_start;
    token = literal | symclass | special | escaped_special | group;
    
    element    = (token quant?) >element_start %element_end;
    expression = (element+) >expression_start %expression_end;
    regexp     = (expression ('|' expression)*)?;

    group_regexp := regexp ')' @group_end;

    main := regexp;
    
    write data;
}%%

static void assign_literal (string& dst, const char* p, const char* pe) {
    while (p < pe) {
        if (*p == '\\') {
            ++p;
            assert(p < pe);
        }
        dst += *p++;
    }
}

static void maybe_join (std::vector<Regexp::Element>& v) {
    if (v.size() < 2) return;
    auto& e1 = v[v.size()-2];
    auto& e2 = v[v.size()-1];
    if (e1.token.type != Regexp::Token::Type::Literal || e1.token.type != e2.token.type) return;
    if (!e1.quant.is_default() || !e2.quant.is_default()) return;
    e1.token.literal += e2.token.literal;
    v.pop_back();
}

static bool symclass_from_escaped (char c, Regexp::Symclass& s) {
    switch (c) {
        case 'd':
            s.ranges.push_back({'0', '9'});
            return true;
        case 'D':
            s.ranges.push_back({CHAR_MIN, '0' - 1});
            s.ranges.push_back({'9' + 1, CHAR_MAX});
            return true;
        case 'w':
            s.ranges.push_back({'a', 'z'});
            s.ranges.push_back({'A', 'Z'});
            s.ranges.push_back({'0', '9'});
            s.chars += '_';
            return true;
        case 'W':
            s.ranges.push_back({CHAR_MIN, '0' - 1});
            s.ranges.push_back({'9' + 1, 'A' - 1});
            s.ranges.push_back({'Z' + 1, '_' - 1});
            s.ranges.push_back({'_' + 1, 'a' - 1});
            s.ranges.push_back({'z' + 1, CHAR_MAX});
            return true;
        case 't':
            s.chars += "\t\v";
            return true;
        case 'n':
            s.chars += "\n";
            return true;
        case 'r':
            s.chars += "\r";
            return true;
        case 's':
            s.chars += " \n\r\t\v";
            return true;
        case 'S':
            s.ranges.push_back({CHAR_MIN, '\t' - 1});
            s.ranges.push_back({'\n' + 1, '\r' - 1});
            s.ranges.push_back({'\r' + 1, ' ' - 1});
            s.ranges.push_back({' ' + 1, '\v' - 1});
            s.ranges.push_back({'\v' + 1, CHAR_MAX});
            return true;
    }
    return false;
}

static void parse_symclass (string_view str, Regexp::Symclass& s) {
    auto p = str.data();
    auto pe = p + str.length();
    
    if (p != pe && *p == '^') {
        s.inverse = true;
        ++p;
    }

    if (p == pe) throw std::logic_error("empty symclass");

    bool has_char_after_range = false;
    while (p < pe) {
        if (*p == '-' && has_char_after_range && (p+1) < pe) {
            s.ranges.push_back({s.chars.back(), *++p});
            s.chars.pop_back();
            has_char_after_range = false;
        } else if (*p == '\\') {
            ++p;
            assert(p < pe);
            if (!symclass_from_escaped(*p, s)) {
                s.chars.push_back(*p);
                has_char_after_range = true;
            }
        } else {
            s.chars.push_back(*p);
            has_char_after_range = true;
        }
        ++p;
    }
}

RegexpPtr Regexp::parse (string_view str) {
    const char* ps  = str.data();
    const char* p   = ps;
    const char* pe  = p + str.length();
    const char* eof = pe;
    int         cs  = regexp_parser_start;
    int         top = 0;
    std::vector<int> stack;
    stack.resize(8);

    const char* mark = nullptr;
    int num[2];

    auto ret = std::make_unique<Regexp>();

    struct Data {
        Regexp*             re;
        Regexp::Expression* expression = nullptr;
        Regexp::Element*    element    = nullptr;
    };

    std::vector<Data> data_stack = {{ret.get()}};
    auto data = &data_stack.back();
    
    auto nsave = [&](int& dest) {
        auto res = from_chars(mark, p, dest);
        assert(!res.ec);
    };
    
    %% write exec;
    
    if (cs < regexp_parser_first_final) {
        throw std::logic_error("bad regexp");
    }

    return ret;
}

}}}
