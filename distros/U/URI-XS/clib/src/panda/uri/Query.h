#pragma once
#include <panda/string.h>
#include <panda/string_map.h>
#include <panda/string_view.h>

namespace panda { namespace uri {

struct Query : panda::string_multimap<string, string> {
    using Base = panda::string_multimap<key_type,mapped_type>;
    uint32_t rev = 1;

    using Base::Base;
    Query (const Query&) = default;
    Query (Query&&)      = default;

    Query& operator= (const Query& x) {
        rev++;
        Base::operator=(x);
        return *this;
    }

    iterator insert (const value_type& val)                        { rev++; return Base::insert(val); }
    template <class P>
    iterator insert (P&& value)                                    { rev++; return Base::insert(std::forward(value)); }
    iterator insert (const_iterator hint, const value_type& value) { rev++; return Base::insert(hint, value); }
    template <class P>
    iterator insert (const_iterator hint, P&& value)               { rev++; return Base::insert(hint, std::forward(value)); }
    template <class InputIt>
    void     insert (InputIt first, InputIt last)                  { rev++; Base::insert(first, last); }
    void     insert (std::initializer_list<value_type> ilist)      { rev++; return Base::insert(ilist); }

    template <class... Args>
    iterator emplace (Args&&... args) { rev++; return Base::emplace(std::forward<Args>(args)...); }

    template <class... Args>
    iterator emplace_hint (const_iterator hint, Args&&... args) { rev++; return Base::emplace(hint, std::forward(args)...); }

    iterator  erase (const_iterator pos)                        { rev++; return Base::erase(pos); }
    iterator  erase (const_iterator first, const_iterator last) { rev++; return Base::erase(first, last); }
    size_type erase (const key_type& key)                       { rev++; return Base::erase(key); }
    size_type erase (const string_view& sv)                     { rev++; return Base::erase(sv); }

    void swap (Query& x) {
        rev++;
        x.rev++;
        Base::swap(x);
    }

    void clear () { rev++; Base::clear(); }

    using Base::begin;
    using Base::rbegin;
    using Base::end;
    using Base::rend;
    using Base::find;
    using Base::lower_bound;
    using Base::upper_bound;
    using Base::equal_range;

    iterator         begin  () { rev++; return Base::begin(); }
    reverse_iterator rbegin () { rev++; return Base::rbegin(); }
    iterator         end    () { rev++; return Base::end(); }
    reverse_iterator rend   () { rev++; return Base::rend(); }

    iterator find                            (const key_type& k) { rev++; return Base::find(k); }
    iterator lower_bound                     (const key_type& k) { rev++; return Base::lower_bound(k); }
    iterator upper_bound                     (const key_type& k) { rev++; return Base::upper_bound(k); }
    std::pair<iterator,iterator> equal_range (const key_type& k) { rev++; return Base::equal_range(k); }

    template <class X, typename = typename std::enable_if<std::is_same<X,string_view>::value>::type>
    iterator find                            (X k) { rev++; return Base::find(k); }
    template <class X, typename = typename std::enable_if<std::is_same<X,string_view>::value>::type>
    iterator lower_bound                     (X k) { rev++; return Base::lower_bound(k); }
    template <class X, typename = typename std::enable_if<std::is_same<X,string_view>::value>::type>
    iterator upper_bound                     (X k) { rev++; return Base::upper_bound(k); }
    template <class X, typename = typename std::enable_if<std::is_same<X,string_view>::value>::type>
    std::pair<iterator,iterator> equal_range (X k) { rev++; return Base::equal_range(k); }
};

}}
