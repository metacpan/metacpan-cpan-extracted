#pragma once

namespace panda {

template <typename Begin, typename End = Begin>
struct IteratorPair {
    Begin first;
    End   second;

    IteratorPair (Begin begin, End end) : first(std::move(begin)), second(std::move(end)) {}

    const Begin& begin () const { return first; }
    const End&   end   () const { return second; }

    Begin& begin () { return first; }
    End&   end   () { return second; }
};

template <typename Begin, typename End = Begin>
auto make_iterator_pair(Begin&& begin, End&& end) {
    return IteratorPair<std::decay_t<Begin>, std::decay_t<End>>(std::forward<Begin>(begin), std::forward<End>(end));
}

}
