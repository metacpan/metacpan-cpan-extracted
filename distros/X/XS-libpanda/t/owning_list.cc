#include "test.h"
#include <panda/log.h>
#include <panda/owning_list.h>

using panda::owning_list;
using test::Tracer;

TEST_CASE("empty owning_list" , "[owning_list]") {
    owning_list<int> list;
    REQUIRE(list.size() == 0);
    for (auto iter = list.begin(); iter != list.end(); ++iter) {
        FAIL("list must be empty");
    }
    REQUIRE(true);
}

TEST_CASE("simple owning_list" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(10);
    REQUIRE(list.size() == 1);
    auto iter = list.begin();
    for (; iter != list.end(); ++iter) {
        REQUIRE(*iter == 10);
        break;
    }
    REQUIRE(++iter == list.end());
}

TEST_CASE("2 elements owning_list" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(1);
    REQUIRE(list.size() == 2);
    auto iter = list.begin();
    size_t i = 0;
    for (; iter != list.end(); ++iter) {
        REQUIRE(*iter == i);
        ++i;
    }
    REQUIRE(iter == list.end());
}

TEST_CASE("owning_list::remove 0" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(10);
    list.remove(10);
    for (auto iter = list.begin(); iter != list.end(); ++iter) {
        FAIL("list must be empty");
    }
    REQUIRE(list.size() == 0);
}


TEST_CASE("owning_list::remove 1" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(2);
    list.remove(2);
    list.push_back(1);
    size_t i = 0;
    for (auto iter = list.begin(); iter != list.end(); ++iter) {
        REQUIRE(*iter == i++);
    }
    REQUIRE(list.size() == 2);
}

TEST_CASE("owning_list::remove in iteration" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(2);
    list.push_back(1);
    for (auto iter = list.begin(); iter != list.end(); ++iter) {
        list.remove(2);
    }
    size_t i = 0;
    for (auto iter = list.begin(); iter != list.end(); ++iter) {
        REQUIRE(*iter == i++);
    }

    REQUIRE(list.size() == 2);
}

TEST_CASE("owning_list::remove in iteration 2" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(1);
    list.push_back(2);
    auto iter = list.begin();
    list.remove(1);
    list.remove(2);
    ++iter;
    REQUIRE(iter == list.end());
    REQUIRE(list.size() == 1);
}

TEST_CASE("owning_list::remove in iteration reverse" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(1);
    list.push_back(2);
    auto iter = list.rbegin();
    list.remove(1);
    list.remove(2);
    REQUIRE(*iter == 2);
    //++iter is invalid
    REQUIRE(list.size() == 1);
}

TEST_CASE("owning_list::remove in iteration reverse ++" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(1);
    list.push_back(2);
    auto iter = list.rbegin();
    list.remove(2);
    REQUIRE(*iter++ == 2);
    REQUIRE(*iter++ == 1);
    REQUIRE(*iter++ == 0);
    //++iter is invalid
    REQUIRE(list.size() == 2);
}

TEST_CASE("owning_list::erase in iteration reverse ++" , "[owning_list]") {
    owning_list<int> list;
    list.push_back(0);
    list.push_back(1);
    list.push_back(2);
    auto iter = list.rbegin();
    list.erase(iter);
    REQUIRE(*iter++ == 2);
    REQUIRE(*iter++ == 1);
    REQUIRE(*iter++ == 0);
    //++iter is invalid
    REQUIRE(list.size() == 2);
}

TEST_CASE("owning_list::clear Tracer" , "[owning_list]") {
    Tracer::refresh();
    owning_list<Tracer> list;
    list.push_back(Tracer(0));
    list.push_back(Tracer(1));
    list.push_back(Tracer(2));
    list.clear();
    REQUIRE(Tracer::ctor_total() == Tracer::dtor_calls);

    //++iter is invalid
    REQUIRE(list.size() == 0);
}

TEST_CASE("owning_list::remove Tracer" , "[owning_list]") {
    Tracer::refresh();
    owning_list<Tracer> list;
    list.push_back(Tracer(0));
    list.push_back(Tracer(1));
    list.push_back(Tracer(2));
    list.remove(Tracer(0));
    list.remove(Tracer(2));
    REQUIRE(Tracer::ctor_total() == Tracer::dtor_calls + 1);

    //++iter is invalid
    REQUIRE(list.size() == 1);
}
