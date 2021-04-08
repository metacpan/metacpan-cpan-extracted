#pragma once
#include "../basic_string_view.h"

//#if __cpp_lib_string_view >= 201603L
//#   define PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 1
//// HACK! Clang contains <string_view> and includes it from <string>, but it does not define __cpp_lib_string_view
//#elif  __clang__ && defined(__has_include)
//#   if __has_include(<string_view>)
//#       define PANDA_LIB_USE_PANDA_LIB_STRING_VIEW 1
//#   endif
//#endif
//
//#if defined(PANDA_LIB_USE_PANDA_LIB_STRING_VIEW)
//#       include <string_view>
//#else
//#undef PANDA_LIB_USE_PANDA_LIB_STRING_VIEW
//#endif

namespace panda {
    using string_view    = basic_string_view<char>;
    using wstring_view   = basic_string_view<wchar_t>;
    using u16string_view = basic_string_view<char16_t>;
    using u32string_view = basic_string_view<char32_t>;
}
