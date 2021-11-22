#include "Dfa.h"
#include "Regexp.h"
#include "RagelHelper.h"
#include <limits.h>
#include <cstdlib>

namespace panda { namespace uri { namespace router {

static inline void literal2ragel (string_view literal, string& ret) {
    //printf("RET BEFORE: %s\n", ret.c_str());
    bool spc = false;
    string litstr;
    for (auto c : literal) {
        //printf("LETARAL 2 RAGEL c=%d\n", (int)c);
        if (isprint(c)) {
        	if (c == '\\') litstr += '\\';
            litstr += c;
        }
        else switch(c) {
            case '\0': litstr += "\\0"; break;
            case '\a': litstr += "\\a"; break;
            case '\b': litstr += "\\b"; break;
            case '\t': litstr += "\\t"; break;
            case '\n': litstr += "\\n"; break;
            case '\v': litstr += "\\v"; break;
            case '\f': litstr += "\\f"; break;
            case '\r': litstr += "\\r"; break;
            default: {
                if (litstr) {
                    ret += '"';
                    ret += litstr;
                    ret += '"';
                    litstr.clear();
                    spc = true;
                }
                if (spc) ret += ' ';
                ret += panda::to_string(c);
            }
        }
    }
    if (litstr) {
        if (spc) ret += ' ';
        ret += '"';
        ret += litstr;
        ret += '"';
    }
    //printf("RET AFTER: %s\n", ret.c_str());
}

static inline bool cmp_range (const Regexp::Symclass& sc, const std::initializer_list<Regexp::Symclass::Range>& list) {
    if (sc.ranges.size() != list.size()) return false;
    size_t i = 0;
    for (auto r : list) {
        auto& r2 = sc.ranges[i++];
        if (r2.from != r.from || r2.to != r.to) return false;
    }
    return true;
}

static inline void symclass2ragel (const Regexp::Symclass& sc, string& ret) {
    if (!sc.inverse) {
        if (!sc.chars) {
            if (cmp_range(sc, {{CHAR_MIN, CHAR_MAX}}))              { ret += "any"; return; }
            if (cmp_range(sc, {{'0', '9'}}))                        { ret += "digit"; return; }
            if (cmp_range(sc, {{CHAR_MIN,'0'-1},{'9'+1,CHAR_MAX}})) { ret += "(any-digit)"; return; }
        }
        if (!sc.ranges.size() && sc.chars.size() == 1) return literal2ragel(sc.chars, ret);
    }

    if (sc.inverse) ret += "(any - ";
    ret += "(";
    for (auto c : sc.chars) {
        literal2ragel(string_view(&c, 1), ret);
        ret += "|";
    }
    for (auto& r : sc.ranges) {
        literal2ragel(string_view(&r.from, 1), ret);
        ret += "..";
        literal2ragel(string_view(&r.to, 1), ret);
        ret += "|";
    }
    ret.pop_back();
    ret += ")";
    if (sc.inverse) ret += ")";
}

static void regexp2ragel (const Regexp* re, size_t& capture_idx, string& ret) {
    auto sz = re->expressions.size();
    if (!sz) {
        ret += "\"\"";
        return;
    }

    for (size_t i = 0; i < sz; ++i) {
        auto& expr = re->expressions[i];
        for (auto& element : expr.elements) {
            ret += ' ';
            auto& t = element.token;
            auto& q = element.quant;
            switch (t.type) {
                case Regexp::Token::Type::Literal:
                    literal2ragel(t.literal, ret);
                    break;
                case Regexp::Token::Type::Symclass:
                    symclass2ragel(t.symclass, ret);
                    break;
                case Regexp::Token::Type::Group:
                    ret += "(";
                    regexp2ragel(t.regexp.get(), capture_idx, ret);
                    ret += " )";
                    break;
                case Regexp::Token::Type::Capture:
                    auto this_capture_idx = capture_idx++;
                    ret += "((";
                    regexp2ragel(t.regexp.get(), capture_idx, ret);
                    ret += " ) >cs";
                    ret += panda::to_string(this_capture_idx);
                    ret += " %c_";
                    ret += panda::to_string(this_capture_idx);
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
        if (i < re->expressions.size() - 1) ret += " |";
    }
}

void Dfa::compile(const std::vector<string>& regstrs) {
    states.clear();
    capture_bundles.clear();
    capture_ranges.clear();
    if (!regstrs.size()) return;

    captures_count = 0;
    string final;
    string lex = "%%{\n\n";

    lex += "machine m;\n\n";
    for (size_t i = 0; i < regstrs.size(); ++i) {
        lex += "action path" + panda::to_string(i) + "{}";
        lex += "\n";
    }
    lex += "\n";

    string rules;
    for (size_t i = 0; i < regstrs.size(); ++i) {
        auto captures_start = captures_count;
        auto re = Regexp::parse(regstrs[i]);
        //re->print();
        rules += "path";
        rules += panda::to_string(i);
        rules += " = (";
        regexp2ragel(re.get(), captures_count, rules);
        rules += ") %path";
        rules += panda::to_string(i);
        rules += ";\n";

        final += "path" + panda::to_string(i) + " | ";

        capture_ranges.push_back({captures_start, captures_count});
    }

    if (captures_count >= std::numeric_limits<int16_t>::max()) throw std::logic_error("too many capture groups in all regexp routes in total");

    for (size_t i = 0; i < captures_count; ++i) {
        lex += "action cs" + panda::to_string(i) + "{}\n";
        lex += "action c_" + panda::to_string(i) + "{}\n";
        lex += "\n";
    }

    lex += rules;

    if (final) final.offset(0, final.length() - 3);
    lex += "main := ";
    lex += final;
    lex += ";";
    lex += "\n\n}%%";

    //printf("nurls=%lu capts=%lu\n", regstrs.size(), captures_count);
    //printf("LEX GENERATED:\n%s\n", lex.c_str());

    fill_states(lex);
}

auto MAX_STATE = std::numeric_limits<uint16_t>::max();

void Dfa::fill_states(string_view ragel_machine) {
    router::RagelHelper rh(ragel_machine);
    auto fsm       = rh.parse_data->sectionGraph;
    start_state    = fsm->startState->alg.stateNum;
    auto err_state = fsm->errState;
    int i = 0;
    //printf("num states = %lu, start state = %d\n", fsm->stateList.size(), start_state);

    if (fsm->stateList.size() > MAX_STATE) throw std::logic_error("too many regexp/pattern routes");

    states.resize(fsm->stateList.size());

    auto find_best_path = [](const std::vector<uint16_t>& paths) -> uint16_t {
        uint16_t best = MAX_STATE;
        for (auto v : paths) if (v < best) best = v;
        //printf("BEST PATH IS %d\n", best);
        return best;
    };

    auto fill_capture = [this](const std::vector<uint16_t>& ncapts) -> uint16_t {
        if (!ncapts.size()) return MAX_STATE;
        if (ncapts.size() > 8) throw std::logic_error("too many recursive capture groups closing or starting at the same time");

        for (size_t i = 0; i < capture_bundles.size(); ++i) {
            auto& b = capture_bundles[i];
            if (b.count != ncapts.size()) continue;
            bool bad = false;
            for (size_t j = 0; j < b.count; ++j) {
                if (b.captures[j] != ncapts[j]) {
                    bad = true;
                    break;
                }
            }
            if (!bad) return i;
        }

        if (capture_bundles.size() >= MAX_STATE) throw std::logic_error("too many capture groups in all regexp routes in total");
        capture_bundles.push_back({});
        auto& b = capture_bundles.back();
        b.count = ncapts.size();
        for (size_t i = 0; i < b.count; ++i) b.captures[i] = ncapts[i];
        return capture_bundles.size() - 1;
    };

    auto fill_actions = [&, this](auto& actions, uint16_t& capture, uint16_t& path) {
        if (!actions.size()) return 0;
        std::vector<uint16_t> paths;
        std::vector<uint16_t> capts;
        for (ActionTable::Iter it = actions.first(); it.lte(); ++it) {
            auto name = string_view(it->value->name);
            //printf("ACTION %s\n", string(name).c_str());
            if (name.size() > 4 && name.substr(0, 4) == "path") {
                paths.push_back(0);
                auto r = from_chars(name.cbegin() + 4, name.cend(), paths.back());
                assert(!r.ec); (void)r;
                //printf("fill actons found path %d\n", paths.back());
            }
            else {
                assert(name.size() > 2 && name[0] == 'c');
                uint16_t capt;
                auto r = from_chars(name.cbegin()+2, name.cend(), capt);
                assert(!r.ec); (void)r;
                capts.push_back(name[1] == 's' ? capt : capt | 0x8000);
                //printf("fill actions found capture %d\n", capts.back());
            }
        }

        if (paths.size() == 1) {
            path = paths[0];
        }
        else if (paths.size() > 1) {
            path = find_best_path(paths);
            //printf("best path %d chosen from %lu items\n", path, paths.size());
            auto tmp = capts;
            capts.clear();
            for (auto v : tmp) {
                //printf("checking capture %d\n", v);
                uint16_t real = v & 0x7FFF;
                if (real < capture_ranges[path].from || real >= capture_ranges[path].to) continue;
                //printf("adding capture %d\n", v);
                capts.push_back(v);
            }
        }
        capture = fill_capture(capts);

        //printf("fill action bundle = %d for size %lu\n", capture, capts.size());
        return 0;
    };

    for (StateList::Iter st = fsm->stateList; st.lte(); st++, ++i) {
        auto ragel_state = st.ptr;
        if (ragel_state == err_state) { --i; continue; }

        //printf("state ID=%d\n", ragel_state->alg.stateNum);

        assert((size_t)ragel_state->alg.stateNum < states.size());
        auto& state = states[ragel_state->alg.stateNum];
        state.id = ragel_state->alg.stateNum;
        state.final = st->isFinState();
        fill_actions(st->eofActionTable, state.eof_capture, state.path);

        for (size_t i = 0; i < sizeof(state.trans) / sizeof(State::Trans); ++i) {
            state.trans[i].state = MAX_STATE;
            state.trans[i].capture = MAX_STATE;
        }

        for (TransList::Iter it = st->outList; it.lte(); it++) {
            auto to_state = it->toState->alg.stateNum;
            char from = it->lowKey.getVal();
            char to   = it->highKey.getVal();
            uint16_t unused = MAX_STATE;
            uint16_t capture = MAX_STATE;
            fill_actions(it->actionTable, capture, unused);
            assert(unused == MAX_STATE);
            //printf("TRANS LOW=%d HIGH=%d TOSTATE=%d CAPT=%d\n", from, to, to_state, capture);
            auto c = from;
            do {
                auto& t = state.trans[(unsigned char)c];
                t.state = to_state;
                t.capture = capture;
            } while (c++ != to);
        }
    }

    //dump_states();
}

void Dfa::dump_states () const {
    printf("====================================\nSTATES:\n");
    for (auto& state : states) {
        printf("STATE#%d%s EOFCAP=%d PATH=%d\n", state.id, state.final ? " FINAL" : "", state.eof_capture, state.path);
        for (size_t i = 0; i < sizeof(state.trans) / sizeof(State::Trans); ++i) {
            if (state.trans[i].state == MAX_STATE) continue;
            printf("    TRANS char %d -> %d capt %d\n", (char)(unsigned char)i, state.trans[i].state, state.trans[i].capture);
        }
    }
    printf("====================================\n");
}


optional<Dfa::Result> Dfa::find(string_view str) {
    if (!states.size()) return {};
    auto* state = &states[start_state];
    auto start = (const unsigned char*)str.data();
    auto p = start;
    auto end = p + str.length();

    struct Capture {
        const char* start;
        const char* end;
    };
    auto captures = (Capture*)alloca(sizeof(Capture) * captures_count);

    auto apply_capture = [&](uint16_t bcap) {
        if (bcap == MAX_STATE) return;
        //printf("APPLY BCAP %d\n", bcap);
        auto b = capture_bundles[bcap];
        for (short i = 0; i < b.count; ++i) {
            auto v = b.captures[i];
            //printf("APPLY CAPT %d\n", v);
            if (v & 0x8000) captures[v & 0x7FFF].end = (const char*)p;
            else            captures[v].start        = (const char*)p;
        }
    };

    while (p < end) {
        if (*p == '/' && p > start && *(p-1) == '/') { ++p; continue; }
        auto trans = state->trans[*p];
        //printf("STATE=%d TRYING %c NEWSTATE=%d\n", state->id, *p, trans.state);
        apply_capture(trans.capture);
        if (trans.state == MAX_STATE) return {};
        state = &states[trans.state];
        ++p;
    }
    //printf("LAST STATE ID=%d\n", state->id);

    if (!state->final) return {};
    apply_capture(state->eof_capture);

    Result res;
    res.nmatch = state->path;

    auto capture_range = capture_ranges[res.nmatch];
    res.captures.reserve(capture_range.to - capture_range.from);
    //printf("STRING: %s\n", string(str).c_str());
    //printf("THIS NMATCH HAS %d capts\n", capture_range.to - capture_range.from);
    for (size_t i = capture_range.from; i < capture_range.to; ++i) {
        //printf("CAPT#%d: %p %p\n", i, captures[i].start, captures[i].end);
        //printf("CAPT#%d: %lu %lu\n", i, captures[i].start - str.data(), captures[i].end - str.data());
        //printf("CAPT=%s\n", string(captures[i].start, captures[i].end - captures[i].start).c_str());
        res.captures.emplace_back(captures[i].start, captures[i].end - captures[i].start);
    }

    //printf("FOUND %d CAPT:%d-%d\n", res.nmatch, capture_range.from, capture_range.to);

    return res;
}

}}}
