/***************************************************************************************
* Build  MD5 : c3FWrkUbkeR3T/cVKKYoiQ
* Build Time : 2025-09-16 11:25:44
* Version    : 5.090107
* Author     : H.Q.Wang
****************************************************************************************/
// gcc -o test test.c Log.c
#include "Log.h"
#include <string.h>
#include <stdlib.h>   // getenv()

int main() {
    // 初始化日志系统
    LogOptions options = {
        .level = LOG_LEVEL_DEBUG,
        .targets = LOG_TARGET_CONSOLE,
        .use_color = true,
        .show_timestamp = true,
        .show_log_level = true,
        .show_file_info = true,
        .max_file_size = 100*1024*1024,  // 100MB
        .max_files = 3,
        .flush_immediately = false
    };
	const char *home = getenv("PL_HOME");
	if (!home) home = getenv("HOME");
	
	char *log_path = "log/Test/test.log";
	//snprintf(log_path, sizeof(log_path), "%s/log/Test/test.log", home);

    openLog(log_path,&options);
    
    // 使用日志
    printInf("这是一条INFO日志1\n");
	printInf("这是一条INFO日志2\n");
	printInf("这是一条INFO日志3\n");
    printBug("这是一条DEBUG日志\n");
	printNote("这是一条TRACE日志");
    printWarn("这是一条WARN日志");
    printErr("这是一条ERROR日志");
    
	
    int x = 42;
    printBug("变量x的值是: %d", x);
 
    
    // 关闭日志系统
    closeLog();
    
    return 0;
}
