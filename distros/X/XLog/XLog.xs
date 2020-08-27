#include <xs/xlog.h>
#include <xs/export.h>

using namespace xs;
using namespace panda;
using namespace panda::log;

MODULE = XLog                PACKAGE = XLog
PROTOTYPES: DISABLE

INCLUDE: xs/XLog.xsi

INCLUDE: xs/Logger.xsi

INCLUDE: xs/Formatter.xsi

INCLUDE: xs/Module.xsi

INCLUDE: xs/Console.xsi

INCLUDE: xs/Multi.xsi
