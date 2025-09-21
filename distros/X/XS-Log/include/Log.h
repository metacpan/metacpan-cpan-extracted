/***************************************************************************************
* Build  MD5 : t/lRzMRtc2aBjA2fg2wqQg
* Build Time : 2025-09-20 19:05:28
* Version    : 5.090114
* Author     : H.Q.Wang
----------------------------------------------------------------------------------------
## 功能说明

1. **多日志级别**：支持TRACE/DEBUG/INFO/WARN/ERROR/FATAL多种日志级别
2. **多输出目标**：可以同时输出到控制台和文件
3. **日志轮转**：支持按大小限制自动轮转日志文件
4. **彩色输出**：控制台支持彩色输出（可禁用）
5. **格式化信息**：支持显示时间戳、日志级别、文件行号等信息
6. **线程安全**：基本的线程安全（文件操作部分）
7. **易用API**：提供方便的宏定义简化调用

****************************************************************************************/
#ifndef LOG_H
#define LOG_H
#include <stdbool.h>
#include <stdio.h>

// 日志级别定义
typedef enum {
	LOG_LEVEL_OFF,		// 关闭日志
	LOG_LEVEL_FATAL,    // 严重错误
	LOG_LEVEL_ERROR,    // 错误信息
	LOG_LEVEL_WARN,     // 警告信息
	LOG_LEVEL_INFO,     // 一般信息
    LOG_LEVEL_TRACE,    // 最详细的日志信息
    LOG_LEVEL_DEBUG,    // 调试信息
	LOG_LEVEL_TEXT		// 原文输出
} LogLevel;

// 日志模式定义
typedef enum {
    LOG_MODE_CYCLE,     // 循环日志模式
    LOG_MODE_DAILY,     // 按天日志模式
    LOG_MODE_HOURLY     // 按小时日志模式
} LogMode;

// 日志输出目标选项
typedef enum {
    LOG_TARGET_CONSOLE = 0x01,  // 输出到控制台
    LOG_TARGET_FILE    = 0x02,  // 输出到文件
    LOG_TARGET_SYSLOG  = 0x04   // 输出到系统日志(暂未实现)
} LogTarget;

// 日志选项配置结构体
typedef struct {
    LogLevel level;             // 日志级别
	LogMode mode;				// 日志模式
    int targets;                // 输出目标组合(位掩码)
    bool use_color;             // 是否使用彩色输出(控制台)
    bool show_timestamp;        // 是否显示时间戳
    bool show_log_level;        // 是否显示日志级别
    bool show_file_info;        // 是否显示文件信息
    long max_file_size;          // 最大文件大小(KB)，0表示不限制
    int max_files;              // 最大文件数量，0表示不限制
    bool flush_immediately;     // 每次记录后立即刷新
} LogOptions;

int confirmAction();

bool openLog(const char *log_filepath,const LogOptions* config);
void closeLog(void);
void flushLog(void);
bool makeDir(const char* dir);
bool setLogOptions(const char *key, long val);
void setLogColor(int flag);
void setLogMode(int flag);
void setLogLevel(int level);
void setTargets(int flag);

void log_print(LogLevel level, const char *file, int line, const char *format, ...);
void log_write(LogLevel level, const char *file, int line, const char *message);
/*******************************
// 快捷日志宏
#define printNote(...)	log_write(LOG_LEVEL_TRACE, __FILE__, __LINE__, __VA_ARGS__)
#define printBug(...)	log_write(LOG_LEVEL_DEBUG, __FILE__, __LINE__, __VA_ARGS__)
#define printInf(...)	log_write(LOG_LEVEL_INFO,  __FILE__, __LINE__, __VA_ARGS__)
#define printWarn(...)	log_write(LOG_LEVEL_WARN,  __FILE__, __LINE__, __VA_ARGS__)
#define printErr(...)	log_write(LOG_LEVEL_ERROR, __FILE__, __LINE__, __VA_ARGS__)
#define printFail(...)	log_write(LOG_LEVEL_FATAL, __FILE__, __LINE__, __VA_ARGS__)
#define printText(...)	log_write(LOG_LEVEL_TEXT,  __FILE__, __LINE__, __VA_ARGS__)
*******************************/
#endif // LOG_H
