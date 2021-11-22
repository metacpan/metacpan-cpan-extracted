
#line 1 "src/panda/uri/router/RegexpParse.rl"
#include "Regexp.h"
#include <limits.h>
#include <panda/from_chars.h>

namespace panda { namespace uri { namespace router {


#line 11 "src/panda/uri/router/RegexpParse.cc"
static const int regexp_parser_start = 35;
static const int regexp_parser_first_final = 35;
static const int regexp_parser_error = 0;

static const int regexp_parser_en_group_regexp = 12;
static const int regexp_parser_en_main = 35;


#line 117 "src/panda/uri/router/RegexpParse.rl"


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
    //printf("parse symclass: %s\n", string(str).c_str());
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
    
    
#line 151 "src/panda/uri/router/RegexpParse.cc"
	{
	if ( p == pe )
		goto _test_eof;
	goto _resume;

_again:
	switch ( cs ) {
		case 35: goto st35;
		case 36: goto st36;
		case 37: goto st37;
		case 0: goto st0;
		case 38: goto st38;
		case 39: goto st39;
		case 40: goto st40;
		case 1: goto st1;
		case 2: goto st2;
		case 3: goto st3;
		case 4: goto st4;
		case 41: goto st41;
		case 42: goto st42;
		case 5: goto st5;
		case 6: goto st6;
		case 7: goto st7;
		case 8: goto st8;
		case 43: goto st43;
		case 9: goto st9;
		case 10: goto st10;
		case 11: goto st11;
		case 44: goto st44;
		case 45: goto st45;
		case 46: goto st46;
		case 12: goto st12;
		case 13: goto st13;
		case 14: goto st14;
		case 47: goto st47;
		case 15: goto st15;
		case 16: goto st16;
		case 17: goto st17;
		case 18: goto st18;
		case 19: goto st19;
		case 20: goto st20;
		case 21: goto st21;
		case 22: goto st22;
		case 23: goto st23;
		case 24: goto st24;
		case 25: goto st25;
		case 26: goto st26;
		case 27: goto st27;
		case 28: goto st28;
		case 29: goto st29;
		case 30: goto st30;
		case 31: goto st31;
		case 32: goto st32;
		case 33: goto st33;
		case 34: goto st34;
	default: break;
	}

	if ( ++p == pe )
		goto _test_eof;
_resume:
	switch ( cs )
	{
st35:
	if ( ++p == pe )
		goto _test_eof35;
case 35:
	switch( (*p) ) {
		case 40: goto tr9;
		case 46: goto tr10;
		case 63: goto st0;
		case 91: goto tr11;
		case 92: goto tr12;
		case 93: goto st0;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr8;
tr8:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr143:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr153:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr163:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr169:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr179:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr185:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr195:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr201:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr207:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr213:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
tr219:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st36;
st36:
	if ( ++p == pe )
		goto _test_eof36;
case 36:
#line 496 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr144;
		case 41: goto st0;
		case 42: goto tr145;
		case 43: goto tr146;
		case 46: goto tr147;
		case 63: goto tr148;
		case 91: goto tr149;
		case 92: goto tr150;
		case 93: goto st0;
		case 123: goto tr151;
		case 124: goto tr152;
		case 125: goto st0;
	}
	goto tr143;
tr5:
#line 38 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        parse_symclass(string_view(mark, p - mark), data->element->token.symclass);
    }
	goto st37;
tr9:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr144:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr154:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr164:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr170:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr180:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr186:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr196:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr202:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr208:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr214:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
tr220:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 37;goto st12;}
    }
	goto st37;
st37:
	if ( ++p == pe )
		goto _test_eof37;
case 37:
#line 902 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr154;
		case 41: goto st0;
		case 42: goto st38;
		case 43: goto st40;
		case 46: goto tr157;
		case 63: goto st42;
		case 91: goto tr159;
		case 92: goto tr160;
		case 93: goto st0;
		case 123: goto st6;
		case 124: goto tr162;
		case 125: goto st0;
	}
	goto tr153;
st0:
cs = 0;
	goto _out;
tr145:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st38;
tr171:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st38;
tr187:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st38;
st38:
	if ( ++p == pe )
		goto _test_eof38;
case 38:
#line 951 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr164;
		case 46: goto tr165;
		case 63: goto st0;
		case 91: goto tr166;
		case 92: goto tr167;
		case 93: goto st0;
		case 124: goto tr168;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr163;
tr10:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr147:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr157:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr165:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr173:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr181:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr189:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr197:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr203:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr209:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr215:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
tr221:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st39;
st39:
	if ( ++p == pe )
		goto _test_eof39;
case 39:
#line 1182 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr170;
		case 41: goto st0;
		case 42: goto tr171;
		case 43: goto tr172;
		case 46: goto tr173;
		case 63: goto tr174;
		case 91: goto tr175;
		case 92: goto tr176;
		case 93: goto st0;
		case 123: goto tr177;
		case 124: goto tr178;
		case 125: goto st0;
	}
	goto tr169;
tr146:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st40;
tr172:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st40;
tr188:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st40;
st40:
	if ( ++p == pe )
		goto _test_eof40;
case 40:
#line 1228 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr180;
		case 46: goto tr181;
		case 63: goto st0;
		case 91: goto tr182;
		case 92: goto tr183;
		case 93: goto st0;
		case 124: goto tr184;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr179;
tr11:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr149:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr159:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr166:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr175:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr182:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr191:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr198:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr204:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr210:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr216:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
tr222:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st1;
st1:
	if ( ++p == pe )
		goto _test_eof1;
case 1:
#line 1459 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 92: goto tr1;
		case 93: goto st0;
	}
	goto tr0;
tr0:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st2;
st2:
	if ( ++p == pe )
		goto _test_eof2;
case 2:
#line 1475 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 92: goto st3;
		case 93: goto tr5;
	}
	goto st2;
tr1:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st3;
st3:
	if ( ++p == pe )
		goto _test_eof3;
case 3:
#line 1491 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 120 )
		goto st0;
	goto st2;
tr12:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr150:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr160:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr167:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr176:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr183:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr192:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr199:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr205:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr211:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr217:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
tr223:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st4;
st4:
	if ( ++p == pe )
		goto _test_eof4;
case 4:
#line 1758 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 68: goto st41;
		case 83: goto st41;
		case 87: goto st41;
		case 100: goto st41;
		case 110: goto st41;
		case 119: goto st41;
		case 120: goto st0;
	}
	if ( 114 <= (*p) && (*p) <= 116 )
		goto st41;
	goto st36;
st41:
	if ( ++p == pe )
		goto _test_eof41;
case 41:
	switch( (*p) ) {
		case 40: goto tr186;
		case 41: goto st0;
		case 42: goto tr187;
		case 43: goto tr188;
		case 46: goto tr189;
		case 63: goto tr190;
		case 91: goto tr191;
		case 92: goto tr192;
		case 93: goto st0;
		case 123: goto tr193;
		case 124: goto tr194;
		case 125: goto st0;
	}
	goto tr185;
tr148:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st42;
tr174:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st42;
tr190:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st42;
st42:
	if ( ++p == pe )
		goto _test_eof42;
case 42:
#line 1820 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr196;
		case 46: goto tr197;
		case 63: goto st0;
		case 91: goto tr198;
		case 92: goto tr199;
		case 93: goto st0;
		case 124: goto tr200;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr195;
tr152:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr162:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr168:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr178:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr184:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr194:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr200:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr206:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr212:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr218:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
tr224:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st5;
st5:
	if ( ++p == pe )
		goto _test_eof5;
case 5:
#line 2028 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr9;
		case 46: goto tr10;
		case 63: goto st0;
		case 91: goto tr11;
		case 92: goto tr12;
		case 93: goto st0;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr8;
tr151:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st6;
tr177:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st6;
tr193:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st6;
st6:
	if ( ++p == pe )
		goto _test_eof6;
case 6:
#line 2073 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 44 )
		goto st7;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr14;
	goto st0;
st7:
	if ( ++p == pe )
		goto _test_eof7;
case 7:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr15;
	goto st0;
tr15:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st8;
st8:
	if ( ++p == pe )
		goto _test_eof8;
case 8:
#line 2096 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 125 )
		goto tr17;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st8;
	goto st0;
tr17:
#line 94 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[1]); }
	goto st43;
st43:
	if ( ++p == pe )
		goto _test_eof43;
case 43:
#line 2110 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr202;
		case 46: goto tr203;
		case 63: goto st0;
		case 91: goto tr204;
		case 92: goto tr205;
		case 93: goto st0;
		case 124: goto tr206;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr201;
tr14:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st9;
st9:
	if ( ++p == pe )
		goto _test_eof9;
case 9:
#line 2136 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 44: goto tr18;
		case 125: goto tr20;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st9;
	goto st0;
tr18:
#line 93 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[0]); }
	goto st10;
st10:
	if ( ++p == pe )
		goto _test_eof10;
case 10:
#line 2152 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 125 )
		goto st45;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr21;
	goto st0;
tr21:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st11;
st11:
	if ( ++p == pe )
		goto _test_eof11;
case 11:
#line 2168 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 125 )
		goto tr24;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st11;
	goto st0;
tr24:
#line 94 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[1]); }
	goto st44;
st44:
	if ( ++p == pe )
		goto _test_eof44;
case 44:
#line 2182 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr208;
		case 46: goto tr209;
		case 63: goto st0;
		case 91: goto tr210;
		case 92: goto tr211;
		case 93: goto st0;
		case 124: goto tr212;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr207;
st45:
	if ( ++p == pe )
		goto _test_eof45;
case 45:
	switch( (*p) ) {
		case 40: goto tr214;
		case 46: goto tr215;
		case 63: goto st0;
		case 91: goto tr216;
		case 92: goto tr217;
		case 93: goto st0;
		case 124: goto tr218;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr213;
tr20:
#line 93 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[0]); }
	goto st46;
st46:
	if ( ++p == pe )
		goto _test_eof46;
case 46:
#line 2225 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr220;
		case 46: goto tr221;
		case 63: goto st0;
		case 91: goto tr222;
		case 92: goto tr223;
		case 93: goto st0;
		case 124: goto tr224;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr219;
st12:
	if ( ++p == pe )
		goto _test_eof12;
case 12:
	switch( (*p) ) {
		case 40: goto tr26;
		case 41: goto tr27;
		case 46: goto tr28;
		case 63: goto st0;
		case 91: goto tr29;
		case 92: goto tr30;
		case 93: goto st0;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr25;
tr25:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr31:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr42:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr53:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr60:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr71:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr85:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr96:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr108:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr122:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr129:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
tr136:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st13;
st13:
	if ( ++p == pe )
		goto _test_eof13;
case 13:
#line 2523 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr32;
		case 41: goto tr33;
		case 42: goto tr34;
		case 43: goto tr35;
		case 46: goto tr36;
		case 63: goto tr37;
		case 91: goto tr38;
		case 92: goto tr39;
		case 93: goto st0;
		case 123: goto tr40;
		case 124: goto tr41;
		case 125: goto st0;
	}
	goto tr31;
tr82:
#line 38 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        parse_symclass(string_view(mark, p - mark), data->element->token.symclass);
    }
	goto st14;
tr26:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr32:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr43:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr54:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr61:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr72:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr86:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr97:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr109:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr123:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr130:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
tr137:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 58 "src/panda/uri/router/RegexpParse.rl"
	{
        if (p < pe-2 && p[1] == '?' && p[2] == ':') { 
            data->element->token.type = Regexp::Token::Type::Group;
            p += 2;
        } else {
            data->element->token.type = Regexp::Token::Type::Capture;
        }
        data->element->token.regexp = std::make_unique<Regexp>();
        data_stack.push_back({data->element->token.regexp.get()});
        data = &data_stack.back();
        stack.resize(top+1);
        {stack[top++] = 14;goto st12;}
    }
	goto st14;
st14:
	if ( ++p == pe )
		goto _test_eof14;
case 14:
#line 2929 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr43;
		case 41: goto tr44;
		case 42: goto st15;
		case 43: goto st17;
		case 46: goto tr47;
		case 63: goto st23;
		case 91: goto tr49;
		case 92: goto tr50;
		case 93: goto st0;
		case 123: goto st25;
		case 124: goto tr52;
		case 125: goto st0;
	}
	goto tr42;
tr27:
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr33:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr44:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr55:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr62:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr73:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr87:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr98:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr110:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr124:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr131:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
tr138:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
#line 72 "src/panda/uri/router/RegexpParse.rl"
	{
        data_stack.pop_back();
        data = &data_stack.back();
        stack.pop_back();
        {cs = stack[--top];goto _again;}
    }
	goto st47;
st47:
	if ( ++p == pe )
		goto _test_eof47;
case 47:
#line 3223 "src/panda/uri/router/RegexpParse.cc"
	goto st0;
tr34:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st15;
tr63:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st15;
tr88:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st15;
st15:
	if ( ++p == pe )
		goto _test_eof15;
case 15:
#line 3255 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr54;
		case 41: goto tr55;
		case 46: goto tr56;
		case 63: goto st0;
		case 91: goto tr57;
		case 92: goto tr58;
		case 93: goto st0;
		case 124: goto tr59;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr53;
tr28:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr36:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr47:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr56:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr65:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr74:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr90:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr99:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr111:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr125:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr132:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
tr139:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st16;
st16:
	if ( ++p == pe )
		goto _test_eof16;
case 16:
#line 3487 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr61;
		case 41: goto tr62;
		case 42: goto tr63;
		case 43: goto tr64;
		case 46: goto tr65;
		case 63: goto tr66;
		case 91: goto tr67;
		case 92: goto tr68;
		case 93: goto st0;
		case 123: goto tr69;
		case 124: goto tr70;
		case 125: goto st0;
	}
	goto tr60;
tr35:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st17;
tr64:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st17;
tr89:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st17;
st17:
	if ( ++p == pe )
		goto _test_eof17;
case 17:
#line 3533 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr72;
		case 41: goto tr73;
		case 46: goto tr74;
		case 63: goto st0;
		case 91: goto tr75;
		case 92: goto tr76;
		case 93: goto st0;
		case 124: goto tr77;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr71;
tr29:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr38:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr49:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr57:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr67:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr75:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr92:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr100:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr112:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr126:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr133:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
tr140:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
	goto st18;
st18:
	if ( ++p == pe )
		goto _test_eof18;
case 18:
#line 3765 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 92: goto tr79;
		case 93: goto st0;
	}
	goto tr78;
tr78:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st19;
st19:
	if ( ++p == pe )
		goto _test_eof19;
case 19:
#line 3781 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 92: goto st20;
		case 93: goto tr82;
	}
	goto st19;
tr79:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st20;
st20:
	if ( ++p == pe )
		goto _test_eof20;
case 20:
#line 3797 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 120 )
		goto st0;
	goto st19;
tr30:
#line 14 "src/panda/uri/router/RegexpParse.rl"
	{
        data->re->expressions.push_back({});
        data->expression = &data->re->expressions.back();
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr39:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr50:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr58:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr68:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr76:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr93:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr101:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr113:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr127:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr134:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
tr141:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 23 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression->elements.push_back({});
        data->element = &data->expression->elements.back();
    }
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st21;
st21:
	if ( ++p == pe )
		goto _test_eof21;
case 21:
#line 4064 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 68: goto st22;
		case 83: goto st22;
		case 87: goto st22;
		case 100: goto st22;
		case 110: goto st22;
		case 119: goto st22;
		case 120: goto st0;
	}
	if ( 114 <= (*p) && (*p) <= 116 )
		goto st22;
	goto st13;
st22:
	if ( ++p == pe )
		goto _test_eof22;
case 22:
	switch( (*p) ) {
		case 40: goto tr86;
		case 41: goto tr87;
		case 42: goto tr88;
		case 43: goto tr89;
		case 46: goto tr90;
		case 63: goto tr91;
		case 91: goto tr92;
		case 92: goto tr93;
		case 93: goto st0;
		case 123: goto tr94;
		case 124: goto tr95;
		case 125: goto st0;
	}
	goto tr85;
tr37:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st23;
tr66:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st23;
tr91:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st23;
st23:
	if ( ++p == pe )
		goto _test_eof23;
case 23:
#line 4126 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr97;
		case 41: goto tr98;
		case 46: goto tr99;
		case 63: goto st0;
		case 91: goto tr100;
		case 92: goto tr101;
		case 93: goto st0;
		case 124: goto tr102;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr96;
tr41:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr52:
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr59:
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr70:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr77:
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr95:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr102:
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr114:
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr128:
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr135:
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
tr142:
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	goto st24;
st24:
	if ( ++p == pe )
		goto _test_eof24;
case 24:
#line 4335 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr26;
		case 46: goto tr28;
		case 63: goto st0;
		case 91: goto tr29;
		case 92: goto tr30;
		case 93: goto st0;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 41 )
		goto st0;
	goto tr25;
tr40:
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
	goto st25;
tr69:
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
	goto st25;
tr94:
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
	goto st25;
st25:
	if ( ++p == pe )
		goto _test_eof25;
case 25:
#line 4380 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 44 )
		goto st26;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr104;
	goto st0;
st26:
	if ( ++p == pe )
		goto _test_eof26;
case 26:
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr105;
	goto st0;
tr105:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st27;
st27:
	if ( ++p == pe )
		goto _test_eof27;
case 27:
#line 4403 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 125 )
		goto tr107;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st27;
	goto st0;
tr107:
#line 94 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[1]); }
	goto st28;
st28:
	if ( ++p == pe )
		goto _test_eof28;
case 28:
#line 4417 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr109;
		case 41: goto tr110;
		case 46: goto tr111;
		case 63: goto st0;
		case 91: goto tr112;
		case 92: goto tr113;
		case 93: goto st0;
		case 124: goto tr114;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr108;
tr104:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st29;
st29:
	if ( ++p == pe )
		goto _test_eof29;
case 29:
#line 4444 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 44: goto tr115;
		case 125: goto tr117;
	}
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st29;
	goto st0;
tr115:
#line 93 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[0]); }
	goto st30;
st30:
	if ( ++p == pe )
		goto _test_eof30;
case 30:
#line 4460 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 125 )
		goto st33;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto tr118;
	goto st0;
tr118:
#line 10 "src/panda/uri/router/RegexpParse.rl"
	{
        mark = p;
    }
	goto st31;
st31:
	if ( ++p == pe )
		goto _test_eof31;
case 31:
#line 4476 "src/panda/uri/router/RegexpParse.cc"
	if ( (*p) == 125 )
		goto tr121;
	if ( 48 <= (*p) && (*p) <= 57 )
		goto st31;
	goto st0;
tr121:
#line 94 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[1]); }
	goto st32;
st32:
	if ( ++p == pe )
		goto _test_eof32;
case 32:
#line 4490 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr123;
		case 41: goto tr124;
		case 46: goto tr125;
		case 63: goto st0;
		case 91: goto tr126;
		case 92: goto tr127;
		case 93: goto st0;
		case 124: goto tr128;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr122;
st33:
	if ( ++p == pe )
		goto _test_eof33;
case 33:
	switch( (*p) ) {
		case 40: goto tr130;
		case 41: goto tr131;
		case 46: goto tr132;
		case 63: goto st0;
		case 91: goto tr133;
		case 92: goto tr134;
		case 93: goto st0;
		case 124: goto tr135;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr129;
tr117:
#line 93 "src/panda/uri/router/RegexpParse.rl"
	{ nsave(num[0]); }
	goto st34;
st34:
	if ( ++p == pe )
		goto _test_eof34;
case 34:
#line 4535 "src/panda/uri/router/RegexpParse.cc"
	switch( (*p) ) {
		case 40: goto tr137;
		case 41: goto tr138;
		case 46: goto tr139;
		case 63: goto st0;
		case 91: goto tr140;
		case 92: goto tr141;
		case 93: goto st0;
		case 124: goto tr142;
	}
	if ( (*p) > 43 ) {
		if ( 123 <= (*p) && (*p) <= 125 )
			goto st0;
	} else if ( (*p) >= 42 )
		goto st0;
	goto tr136;
	}
	_test_eof35: cs = 35; goto _test_eof; 
	_test_eof36: cs = 36; goto _test_eof; 
	_test_eof37: cs = 37; goto _test_eof; 
	_test_eof38: cs = 38; goto _test_eof; 
	_test_eof39: cs = 39; goto _test_eof; 
	_test_eof40: cs = 40; goto _test_eof; 
	_test_eof1: cs = 1; goto _test_eof; 
	_test_eof2: cs = 2; goto _test_eof; 
	_test_eof3: cs = 3; goto _test_eof; 
	_test_eof4: cs = 4; goto _test_eof; 
	_test_eof41: cs = 41; goto _test_eof; 
	_test_eof42: cs = 42; goto _test_eof; 
	_test_eof5: cs = 5; goto _test_eof; 
	_test_eof6: cs = 6; goto _test_eof; 
	_test_eof7: cs = 7; goto _test_eof; 
	_test_eof8: cs = 8; goto _test_eof; 
	_test_eof43: cs = 43; goto _test_eof; 
	_test_eof9: cs = 9; goto _test_eof; 
	_test_eof10: cs = 10; goto _test_eof; 
	_test_eof11: cs = 11; goto _test_eof; 
	_test_eof44: cs = 44; goto _test_eof; 
	_test_eof45: cs = 45; goto _test_eof; 
	_test_eof46: cs = 46; goto _test_eof; 
	_test_eof12: cs = 12; goto _test_eof; 
	_test_eof13: cs = 13; goto _test_eof; 
	_test_eof14: cs = 14; goto _test_eof; 
	_test_eof47: cs = 47; goto _test_eof; 
	_test_eof15: cs = 15; goto _test_eof; 
	_test_eof16: cs = 16; goto _test_eof; 
	_test_eof17: cs = 17; goto _test_eof; 
	_test_eof18: cs = 18; goto _test_eof; 
	_test_eof19: cs = 19; goto _test_eof; 
	_test_eof20: cs = 20; goto _test_eof; 
	_test_eof21: cs = 21; goto _test_eof; 
	_test_eof22: cs = 22; goto _test_eof; 
	_test_eof23: cs = 23; goto _test_eof; 
	_test_eof24: cs = 24; goto _test_eof; 
	_test_eof25: cs = 25; goto _test_eof; 
	_test_eof26: cs = 26; goto _test_eof; 
	_test_eof27: cs = 27; goto _test_eof; 
	_test_eof28: cs = 28; goto _test_eof; 
	_test_eof29: cs = 29; goto _test_eof; 
	_test_eof30: cs = 30; goto _test_eof; 
	_test_eof31: cs = 31; goto _test_eof; 
	_test_eof32: cs = 32; goto _test_eof; 
	_test_eof33: cs = 33; goto _test_eof; 
	_test_eof34: cs = 34; goto _test_eof; 

	_test_eof: {}
	if ( p == eof )
	{
	switch ( cs ) {
	case 37: 
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 36: 
#line 33 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Literal;
        assign_literal(data->element->token.literal, mark, p);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 39: 
#line 43 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        switch (*(p-1)) {
            case '.':
                data->element->token.symclass.ranges.push_back({CHAR_MIN, CHAR_MAX});
                break;
        }
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 41: 
#line 52 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->token.type = Regexp::Token::Type::Symclass;
        auto is_special = symclass_from_escaped(*(p-1), data->element->token.symclass);
        assert(is_special);
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 44: 
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 42: 
#line 90 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = 1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 38: 
#line 91 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 40: 
#line 92 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 1; num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 46: 
#line 95 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = num[0]; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 43: 
#line 96 "src/panda/uri/router/RegexpParse.rl"
	{ num[0] = 0; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
	case 45: 
#line 97 "src/panda/uri/router/RegexpParse.rl"
	{ num[1] = -1; }
#line 79 "src/panda/uri/router/RegexpParse.rl"
	{
        data->element->quant.min = num[0];
        data->element->quant.max = num[1];
    }
#line 28 "src/panda/uri/router/RegexpParse.rl"
	{
        maybe_join(data->expression->elements);
        data->element = nullptr;
    }
#line 19 "src/panda/uri/router/RegexpParse.rl"
	{
        data->expression = nullptr;
    }
	break;
#line 4793 "src/panda/uri/router/RegexpParse.cc"
	}
	}

	_out: {}
	}

#line 247 "src/panda/uri/router/RegexpParse.rl"
    
    if (cs < regexp_parser_first_final) {
        throw std::logic_error("bad regexp");
    }

    return ret;
}

}}}