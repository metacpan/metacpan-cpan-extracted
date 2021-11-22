#include "RagelHelper.h"
#include <sstream>
#include "../../../ragel/fix_leaks.h"
#include "../../../ragel/rlscan.h"
#include "../../../ragel/xmlcodegen.h"

thread_local ragel_fix_leaks::AntiLeakPool* ragel_fix_leaks::anti_leak_pool;

namespace panda { namespace uri { namespace router {

RagelHelper::RagelHelper(string_view in) {
    // ragel source code is leaking on every possible line, there is no possibility of fixing it without rewriting all the ragel from scratch
    // here we use another approach: we create custom memory pool and make ragel use it for every memory allocation
    // when the process is complete we will free the whole pool
    ragel_fix_leaks::anti_leak_pool = new ragel_fix_leaks::AntiLeakPool();
    char nm[]         = "autogen-uri-router.rl";
    auto input_file   = nm;
    auto str_in       = std::string(in.data(), in.size());
    auto input        = std::stringstream(str_in);

    input_data = std::make_unique<InputData>();
    input_data->inputFileName = input_file;

    /* Make the first input item. */
    InputItem *firstInputItem = new InputItem();
    firstInputItem->type = InputItem::HostData;
    firstInputItem->loc.fileName = input_file;
    firstInputItem->loc.line = 1;
    firstInputItem->loc.col = 1;
    input_data->inputItems.append( firstInputItem );

    Scanner scanner( *input_data, input_file, input, 0, 0, 0, false );
    scanner.do_scan();

    /* Finished, final check for errors.. */
    assert(gblErrorCount == 0);

    /* Now send EOF to all parsers. */
    input_data->terminateAllParsers();

    /* Bail on above error. */
    assert(gblErrorCount == 0);

    /* Locate the backend program */
    /* Compiles machines. */
    input_data->prepareMachineGen();


    ParserDict::Iter parser = input_data->parserDict;
    parse_data = parser->value->pd;


    GenBase gd(input_file, parse_data, parse_data->sectionGraph);
    gd.reduceActionTables();
}

RagelHelper::~RagelHelper() {
    input_data.reset();
    delete ragel_fix_leaks::anti_leak_pool;
    ragel_fix_leaks::anti_leak_pool = nullptr;
}

}}}
