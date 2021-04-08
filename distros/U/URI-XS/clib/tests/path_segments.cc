#include "test.h"

using psv = decltype(URI().path_segments());

TEST_CASE("path-segments", "[path-segments]") {
    URI uri("https://ya.ru/my/path%2Ffak/cool/mf?a=b");
    CHECK(uri.path() == "/my/path%2Ffak/cool/mf");
    CHECK(uri.path_segments() == psv{"my", "path/fak", "cool", "mf"});

    uri = "https://ya.ru?a=b";
    CHECK(uri.path_segments() == psv{});

    uri = "https://ya.ru/?a=b";
    CHECK(uri.path_segments() == psv{});

    uri = "https://ya.ru/as/?a=b";
    CHECK(uri.path_segments() == psv{"as"});

    uri = "https://ya.ru/as?a=b";
    CHECK(uri.path_segments() == psv{"as"});

    uri.path_segments({"1","2","3","4"});
    CHECK(uri.to_string() == "https://ya.ru/1/2/3/4?a=b");

    uri.path_segments({});
    CHECK(uri.to_string() == "https://ya.ru?a=b");

    uri.path_segments({"jopa popa", "pizda/nah"});
    CHECK(uri.to_string() == "https://ya.ru/jopa%20popa/pizda%2Fnah?a=b");
}

