#include <string>
#include <vector>
#include <sstream>

#include <dtl/dtl.hpp>

std::string diff_sequence(
        const std::vector<std::string> &lines_a,
        const std::vector<std::string> &lines_b
        )
{
    dtl::Diff<std::string> diff(lines_a, lines_b);
    diff.onHuge();
    diff.compose();
    diff.composeUnifiedHunks();

    std::ostringstream out;
    diff.printUnifiedFormat(out);

    return out.str();
}

