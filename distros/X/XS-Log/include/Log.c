/***************************************************************************************
* Build  MD5 : 5fwVxA2qtRz4Alk3/+EnLw
* Build Time : 2025-09-23 13:31:15
* Version    : 5.090129
* Author     : H.Q.Wang
****************************************************************************************/
#include "Log.h"
#include <stdarg.h>
#include <time.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>	   // getenv()

#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h> // 提供 gettimeofday 用于获取毫秒级时间
#include <sys/file.h>
/***************************************************************************************
颜色				前景色		背景色
黑色				\033[30m	\033[40m
红色				\033[31m	\033[41m
绿色				\033[32m	\033[42m
黄色				\033[33m	\033[43m
蓝色				\033[34m	\033[44m
紫色				\033[35m	\033[45m
青色				\033[36m	\033[46m
浅灰				\033[37m	\033[47m
回退到发行版默认值	\033[39m	\033[49m
-------------------------------------------------------------------------------
颜色				背景色
深灰				\033[100m
浅红				\033[101m
浅绿				\033[102m
黄色				\033[103m
浅蓝				\033[104m
浅紫				\033[105m
蓝绿				\033[106m
白色				\033[107m
****************************************************************************************/

//echo -e "\e[1;43;32m背景色，前景色\e[0m"


// 日志模块全局状态
static struct {
    LogOptions options;
    FILE *log_file;
	int rep_file;
    
	char cur_rep_path[256];
	char cur_rep_dir[256];
	char cur_rep_day[9];
	char cur_rep_hour[3];
	char rep_dir[150];
	char rep_name[64];
	
	char cur_log_path[256];
	char cur_log_dir[256];
	char cur_log_day[9];
	char cur_log_hour[3];
    char log_path[256];
	char log_name[64];
	char log_dir[150];
	char log_ext[16];
	
    // 控制台颜色定义
    const char *color_trace;
    const char *color_debug;
    const char *color_info;
    const char *color_warn;
    const char *color_error;
    const char *color_fatal;
    const char *color_reset;
	const char *color_unkown;
} g_config = {
    .options = {
        .level = LOG_LEVEL_INFO,
		.mode = LOG_MODE_CYCLE,
        .targets = LOG_TARGET_CONSOLE,
        .use_color = true,
		.with_rep = false,
        .show_timestamp = true,
        .show_log_level = true,
        .show_file_info = false,
        .max_file_size = 100*1024*1024,  // 100MB
        .max_files = 10,
        .flush_immediately = false
    },
	
	.cur_rep_path= {0},
	.cur_rep_day = {0},
	.cur_rep_dir = {0},
	.cur_rep_hour= {0},
	
	.cur_log_path= {0},
	.cur_log_day = {0},
	.cur_log_dir = {0},
	.cur_log_hour= {0},
	
	.log_name    = {0},
	.log_dir     = {0},
	.log_ext     = {0},
    .log_file    = NULL,
	.rep_file    = -1,
    .color_trace = "\033[36m",        // 青色
    .color_info  = "\033[32m",        // 绿色
    .color_warn  = "\033[33m",        // 黄色
    .color_error = "\033[31m",        // 红色
    .color_fatal = "\033[35m",        // 紫色
	.color_unkown= "\033[37m",        // 灰色
    .color_debug = "\033[44;37m",     // 蓝色,青色
    .color_reset = "\033[0m"          // 重置
};

// 内部函数声明
static void rep_rotate_file(void);
static bool rep_open_file(void);
static void rep_close_file(void);

static void log_rotate_file(void);
static bool log_open_file(void);
static void log_close_file(void);

static void get_current_log_path();
static bool parse_filepath(const char* filepath);
static const char* log_level_to_string(LogLevel level);

// 初始化日志系统
bool openLog(const char *log_filepath,const LogOptions* config) {
	if (log_filepath == NULL || strlen(log_filepath) == 0) {
        return false;
    }
	
    if (config == NULL) {
        return false;
    }
    memcpy(&g_config, config, sizeof(LogOptions));
    
    // 解析文件路径，分离基础路径、程序名和扩展名
    if (!parse_filepath(log_filepath)) {
        return false;
    }
    
    bool l = log_open_file();
	bool r = true;
	if(g_config.options.with_rep)
	{
		r = rep_open_file();
	}
    return l && r;
}
void setLogLevel(int level)
{
	g_config.options.level = level;
}
void setLogMode(int flag)
{
	g_config.options.mode = flag;
}
void setLogColor(int flag)
{
	g_config.options.use_color = flag;
}
void setLogTargets(int flag)
{
	g_config.options.targets = flag;
}
// 设置配置项的函数
bool setLogOptions(const char *key, long val) {
    if (!key) return false;

    // 比较键名并设置对应的值
    if (strcmp(key, "level") == 0) {
        g_config.options.level = (LogLevel)val;
    } else if (strcmp(key, "mode") == 0) {
        g_config.options.mode = (LogMode)val;
    } else if (strcmp(key, "targets") == 0) {
        g_config.options.targets = (LogTarget)val;
    } else if (strcmp(key, "use_color") == 0) {
        g_config.options.use_color = (bool)val;
    } else if (strcmp(key, "show_timestamp") == 0) {
        g_config.options.show_timestamp = (bool)val;
    } else if (strcmp(key, "show_log_level") == 0) {
        g_config.options.show_log_level = (bool)val;
    } else if (strcmp(key, "show_file_info") == 0) {
        g_config.options.show_file_info = (bool)val;
    } else if (strcmp(key, "max_file_size") == 0) {
        g_config.options.max_file_size = val;
    } else if (strcmp(key, "max_files") == 0) {
        g_config.options.max_files = (int)val;
    } else if (strcmp(key, "flush_immediately") == 0) {
        g_config.options.flush_immediately = (bool)val;
    } else {
        // 未知的配置项
        return false;
    }

    return true;
}
void closeLog() {
    flushLog();
    log_close_file();
	rep_close_file();
}
void flushLog() {
    if (g_config.log_file != NULL) {
        fflush(g_config.log_file);
    }
    fflush(stdout);
    fflush(stderr);
}

// 函数定义
int confirmAction() {
    char input[10];  // 缓冲区较大，以容纳潜在的额外输入
    
    printf("确认操作请按 'y' 或 'Y'，否则直接按回车键以取消： ");
    if (fgets(input, sizeof(input), stdin) != NULL) {
        // 若仅输入回车键，fgets 会捕捉到一个换行符
        if (input[0] == '\n') {
            return 0; // 空输入（仅回车）表示取消
        }
        // 检查用户输入的第一个字符是否是 'y' 或 'Y'
        if (input[0] == 'y' || input[0] == 'Y') {
            return 1; // 确认操作
        }
    }
    return 0; // 任何其他情况都表示取消
}

bool makeDir(const char* dir) {
	if (dir == NULL || strlen(dir) == 0) {
        return false;
    }
    char tmp[256];
    char* p = NULL;
    size_t len;
    
    // 复制路径到临时变量
    snprintf(tmp, sizeof(tmp), "%s", dir);
    len = strlen(tmp);
    
    // 去除末尾的斜杠
    if (tmp[len - 1] == '/') {
        tmp[len - 1] = 0;
    }
    
    // 逐级创建目录
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;  // 临时截断路径
            
            // 创建当前级别的目录
            if (mkdir(tmp, 0755) != 0 && errno != EEXIST) {
                return false;
            }
            
            *p = '/';  // 恢复斜杠
        }
    }
    
    // 创建最终目录
    if (mkdir(tmp, 0755) != 0 && errno != EEXIST) {
        return false;
    }
    
    return true;
}

static bool rep_open_file() {

	if(!(g_config.options.targets & LOG_TARGET_FILE)) return true;
	
    // 获取当前日志文件路径并打开
	
    get_current_log_path();

    if (strlen(g_config.cur_rep_path) == 0) {
		return false;
	}
    if (!makeDir(g_config.cur_rep_dir)) {
        return false;
    }
	rep_close_file();
	g_config.rep_file = open(g_config.cur_rep_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (g_config.rep_file < 0) {
        printf("Failed to open rep file %s\n",g_config.cur_rep_path);
		return false;
    }
	
	return true;
}

static void rep_close_file() {
    if (g_config.rep_file >= 0) {
        close(g_config.rep_file);
        g_config.rep_file = -1;
    }
}

static bool log_open_file() {

	if(!(g_config.options.targets & LOG_TARGET_FILE)) return true;
	
    // 获取当前日志文件路径并打开
	
    get_current_log_path();

    if (strlen(g_config.cur_log_path) == 0) {
		return false;
	}
    if (!makeDir(g_config.cur_log_dir)) {
        return false;
    }
	log_close_file();
    g_config.log_file = fopen(g_config.cur_log_path, "a+");
    if (g_config.log_file == NULL) {
        printf("Failed to open log file %s\n",g_config.cur_log_path);
		return false;
    }
	
	return true;
}

static void log_close_file() {
    if (g_config.log_file != NULL) {
		fputs("*************************************\n"
			  "* 安全关闭日志文件\n"
			  "*************************************\n", g_config.log_file);
		fflush(g_config.log_file);
        fclose(g_config.log_file);
        g_config.log_file = NULL;
    }
}

// 获取当前日志文件路径
static void get_current_log_path() {
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    g_config.cur_log_path[0] = '\0';

	if(g_config.options.with_rep)
	{
		g_config.cur_rep_path[0] = '\0';
	}

    switch (g_config.options.mode) {
        case LOG_MODE_CYCLE:{
            snprintf(g_config.cur_log_path, sizeof(g_config.cur_log_path), "%s/%s.%s", 
                    g_config.log_dir, g_config.log_name, g_config.log_ext);
			
			//snprintf(g_config.cur_log_dir, sizeof(g_config.cur_log_dir), "%s",g_config.log_dir);
			// 等价以上，推荐用：
			strncpy(g_config.cur_log_dir, g_config.log_dir, sizeof(g_config.cur_log_dir) - 1);
			g_config.cur_log_dir[sizeof(g_config.cur_log_dir) - 1] = '\0'; // 确保字符串以 null 结尾
			
			
			if(g_config.options.with_rep)
			{
				snprintf(g_config.cur_rep_path, sizeof(g_config.cur_rep_path), "%s/%s.rep", 
                    g_config.rep_dir, g_config.rep_name);
				snprintf(g_config.cur_rep_dir, sizeof(g_config.cur_rep_dir), "%s",g_config.rep_dir);
			}
					
			
            break;
		}
        case LOG_MODE_DAILY: {
            char date_str[9];
            strftime(date_str, sizeof(date_str), "%Y%m%d", tm_info);
            snprintf(g_config.cur_log_path, sizeof(g_config.cur_log_path), "%s/%s/%s.%s", 
                    g_config.log_dir, date_str, g_config.log_name, g_config.log_ext);
			
			snprintf(g_config.cur_log_dir, sizeof(g_config.cur_log_dir), "%s/%s", 
                    g_config.log_dir, date_str);
			//snprintf(g_config.cur_log_day, sizeof(g_config.cur_log_day), date_str);
			// 等价以上，推荐用：
			strncpy(g_config.cur_log_day, date_str, sizeof(g_config.cur_log_day) - 1);
			g_config.cur_log_day[sizeof(g_config.cur_log_day) - 1] = '\0'; // 确保字符串以 null 结尾
			
			if(g_config.options.with_rep)
			{
				snprintf(g_config.cur_rep_path, sizeof(g_config.cur_rep_path), "%s/%s/%s.rep", 
                    g_config.rep_dir, date_str, g_config.rep_name);
				snprintf(g_config.cur_rep_dir, sizeof(g_config.cur_rep_dir), "%s/%s", 
                    g_config.rep_dir, date_str);
				
				//有warning用下面方式赋值
				//snprintf(g_config.cur_rep_day, sizeof(g_config.cur_rep_day), date_str);
				strncpy(g_config.cur_rep_day, date_str, sizeof(g_config.cur_rep_day) - 1);
				g_config.cur_rep_day[sizeof(g_config.cur_rep_day) - 1] = '\0'; // 确保字符串以 null 结尾
			
			}
			
            break;
        }
            
        case LOG_MODE_HOURLY: {
            char date_str[9];
            char hour_str[3];
            strftime(date_str, sizeof(date_str), "%Y%m%d", tm_info);
            strftime(hour_str, sizeof(hour_str), "%H", tm_info);
            snprintf(g_config.cur_log_path, sizeof(g_config.cur_log_path), "%s/%s/%s.%s.%s", 
                    g_config.log_dir, date_str, g_config.log_name, hour_str, g_config.log_ext);
			
			snprintf(g_config.cur_log_dir, sizeof(g_config.cur_log_dir), "%s/%s", 
                    g_config.log_dir, date_str);
			//snprintf(g_config.cur_log_day, sizeof(g_config.cur_log_day), date_str);
			//snprintf(g_config.cur_log_hour, sizeof(g_config.cur_log_hour), hour_str);
			
			// 等价以上，推荐用：
			strncpy(g_config.cur_log_day, date_str, sizeof(g_config.cur_log_day) - 1);
			g_config.cur_log_day[sizeof(g_config.cur_log_day) - 1] = '\0'; // 确保字符串以 null 结尾
			
			strncpy(g_config.cur_log_hour, hour_str, sizeof(g_config.cur_log_hour) - 1);
			g_config.cur_log_hour[sizeof(g_config.cur_log_hour) - 1] = '\0'; // 确保字符串以 null 结尾
			
			
			if(g_config.options.with_rep)
			{
				snprintf(g_config.cur_rep_path, sizeof(g_config.cur_rep_path), "%s/%s/%s.%s.rep", 
                    g_config.rep_dir, date_str, g_config.rep_name, hour_str);
				snprintf(g_config.cur_rep_dir, sizeof(g_config.cur_rep_dir), "%s/%s", 
                    g_config.rep_dir, date_str);
					
				//snprintf(g_config.cur_rep_day, sizeof(g_config.cur_rep_day), date_str);
				//snprintf(g_config.cur_rep_hour, sizeof(g_config.cur_rep_hour), hour_str);
				
				strncpy(g_config.cur_rep_day, date_str, sizeof(g_config.cur_rep_day) - 1);
				g_config.cur_rep_day[sizeof(g_config.cur_rep_day) - 1] = '\0'; // 确保字符串以 null 结尾
				
				strncpy(g_config.cur_rep_hour, hour_str, sizeof(g_config.cur_rep_hour) - 1);
				g_config.cur_rep_hour[sizeof(g_config.cur_rep_hour) - 1] = '\0'; // 确保字符串以 null 结尾
				
			}
			
			
            break;
        }
    }
}

// 解析文件路径，分离基础路径、程序名和扩展名
static bool parse_filepath(const char* filepath) {
    if (filepath == NULL || strlen(filepath) == 0) {
        return false;
    }
    // 复制文件路径用于处理
    char temp_path[128];
    strncpy(temp_path, filepath, sizeof(temp_path) - 1);
    temp_path[sizeof(temp_path) - 1] = '\0';
	
	strncpy(g_config.log_path, temp_path, sizeof(g_config.log_path) - 1);
    g_config.log_path[sizeof(g_config.log_path) - 1] = '\0';
	
    // 获取文件名（包含扩展名）
    char* filename = strrchr(temp_path, '/');
    if (filename == NULL) {
        filename = temp_path;
		if(g_config.options.with_rep)
		{
			strcpy(g_config.rep_dir, ".");
			strcpy(g_config.log_dir, "./LOG");
		}
		else
		{
			strcpy(g_config.log_dir, ".");	
		}
    } else {
        *filename = '\0';
        filename++;
		if(g_config.options.with_rep)
		{
			strncpy(g_config.rep_dir, temp_path, sizeof(g_config.rep_dir) - 1);
			g_config.rep_dir[sizeof(g_config.rep_dir) - 1] = '\0';
			snprintf(g_config.log_dir, sizeof(g_config.log_dir), "%s/LOG", 
                    temp_path);
		}
		else
		{
			strncpy(g_config.log_dir, temp_path, sizeof(g_config.log_dir) - 1);
			g_config.log_dir[sizeof(g_config.log_dir) - 1] = '\0';
		}

    }
    // 分离程序名和扩展名: 
    char* dot = strrchr(filename, '.');
	//带扩展名的情况
    if (dot != NULL) {
        *dot = '\0';
        strncpy(g_config.log_name, filename, sizeof(g_config.log_name) - 1);
        g_config.log_name[sizeof(g_config.log_name) - 1] = '\0';
        strncpy(g_config.log_ext, dot + 1, sizeof(g_config.log_ext) - 1);
        g_config.log_ext[sizeof(g_config.log_ext) - 1] = '\0';
		//rep日志名称
		if(g_config.options.with_rep)
		{
			//可能TongSMT.P02.log，需要再次分离文件名称
			dot = strrchr(filename, '.');
			strncpy(g_config.rep_name, filename, sizeof(g_config.rep_name) - 1);
			g_config.rep_name[sizeof(g_config.rep_name) - 1] = '\0';
		}
    } 
	//不带扩展名的情况
	else 
	{
        strncpy(g_config.log_name, filename, sizeof(g_config.log_name) - 1);
        g_config.log_name[sizeof(g_config.log_name) - 1] = '\0';
        strcpy(g_config.log_ext, "log"); // 默认扩展名
		//rep日志名称
		if(g_config.options.with_rep)
		{
			strncpy(g_config.rep_name, filename, sizeof(g_config.rep_name) - 1);
			g_config.rep_name[sizeof(g_config.rep_name) - 1] = '\0';
		}
    }
    return true;
}

static const char* log_level_to_string(LogLevel level) {
    switch (level) {
        case LOG_LEVEL_TRACE: return "TRC";
        case LOG_LEVEL_DEBUG: return "BUG";
        case LOG_LEVEL_INFO:  return "INF";
        case LOG_LEVEL_WARN:  return "WRN";
        case LOG_LEVEL_ERROR: return "ERR";
        case LOG_LEVEL_FATAL: return "FAL";
        default:              return "UNK";
    }
}
// 判断是否需要备份日志日志文件
static void rep_rotate_file() {
    if (g_config.options.max_files <= 0) {
        remove(g_config.cur_rep_path);
        return;
    }

    // 删除最旧的日志文件
    char old_name[512];
    char new_name[512];
    
    snprintf(old_name, sizeof(old_name), "%s/%s.%d.rep", 
                    g_config.cur_rep_dir, g_config.rep_name, g_config.options.max_files);
    remove(old_name);

    // 重命名其他日志文件
    for (int i = g_config.options.max_files - 1; i >= 1; i--) {
        snprintf(new_name, sizeof(old_name), "%s/%s.%d.rep", 
                 g_config.cur_rep_dir, g_config.rep_name,i);
        snprintf(old_name, sizeof(new_name), "%s/%s.%d.rep", 
                 g_config.cur_rep_dir, g_config.rep_name,i - 1);
        rename(old_name, new_name);
    }

    // 重命名当前日志文件
    snprintf(new_name, sizeof(new_name), "%s/%s.%d.rep", 
                 g_config.cur_rep_dir, g_config.rep_name,1);
    rename(g_config.cur_rep_path, new_name);
}

// 判断是否需要备份日志日志文件
static void log_rotate_file() {
    if (g_config.options.max_files <= 0) {
        remove(g_config.cur_log_path);
        return;
    }

    // 删除最旧的日志文件
    char old_name[512];
    char new_name[512];
    
    snprintf(old_name, sizeof(old_name), "%s/%s.%d.%s", 
                    g_config.cur_log_dir, g_config.log_name, g_config.options.max_files,g_config.log_ext);
    remove(old_name);

    // 重命名其他日志文件
    for (int i = g_config.options.max_files - 1; i >= 1; i--) {
        snprintf(new_name, sizeof(old_name), "%s/%s.%d.%s", 
                 g_config.cur_log_dir, g_config.log_name,i,g_config.log_ext);
        snprintf(old_name, sizeof(new_name), "%s/%s.%d.%s", 
                 g_config.cur_log_dir, g_config.log_name,i - 1,g_config.log_ext);
        rename(old_name, new_name);
    }

    // 重命名当前日志文件
    snprintf(new_name, sizeof(new_name), "%s/%s.%d.%s", 
                 g_config.cur_log_dir, g_config.log_name,1,g_config.log_ext);
    rename(g_config.cur_log_path, new_name);
}

void log_print(LogLevel level, const char *file, int line, const char *format, ...) {
	if(level == LOG_LEVEL_OFF) return;
	if(level != LOG_LEVEL_TEXT)
	{
		if (level > g_config.options.level) {
			return;
		}
	}
    va_list args;
    char buf[1024];
    
    
    // 格式化日志头
    int pos = 0;
    
	time_t now;
	struct tm *tm_now;
	
	// 获取当前时间
	time(&now);
	tm_now = localtime(&now);
		
    if (g_config.options.show_timestamp && level != LOG_LEVEL_TEXT) {

		struct timeval tv;
		gettimeofday(&tv, NULL);
        pos += strftime(buf + pos, sizeof(buf) - pos, "[%Y-%m-%d %H:%M:%S", tm_now);
		
		pos += snprintf(buf + pos,sizeof(buf) - pos,".%03ld]", tv.tv_usec / 1000);
    }
    
    if (g_config.options.show_log_level && level != LOG_LEVEL_TEXT) {
        const char *color = "";
        const char *color_reset = "";
        
        if (g_config.options.use_color && g_config.options.targets & LOG_TARGET_CONSOLE) {
            switch (level) {
                case LOG_LEVEL_TRACE: color = g_config.color_trace; break;
                case LOG_LEVEL_DEBUG: color = g_config.color_debug; break;
                case LOG_LEVEL_INFO:  color = g_config.color_info;  break;
                case LOG_LEVEL_WARN:  color = g_config.color_warn;  break;
                case LOG_LEVEL_ERROR: color = g_config.color_error; break;
                case LOG_LEVEL_FATAL: color = g_config.color_fatal; break;
                default: color = ""; break;
            }
            color_reset = g_config.color_reset;
        }
        
        pos += snprintf(buf + pos, sizeof(buf) - pos, "[%s%s%s] ", 
                       color, log_level_to_string(level), color_reset);
    }
    
    if (g_config.options.show_file_info && level != LOG_LEVEL_TEXT) {
        pos += snprintf(buf + pos, sizeof(buf) - pos, "(%s:%d) ", file, line);
    }
    
    // 格式化用户提供的日志内容
    va_start(args, format);
    pos += vsnprintf(buf + pos, sizeof(buf) - pos, format, args);
    va_end(args);
    
    // 确保以换行符结尾
    if (pos >= sizeof(buf) - 2) {
        pos = sizeof(buf) - 2;
    }
    if (buf[pos-1] != '\n') {
        buf[pos++] = '\n';
        buf[pos] = '\0';
    }
    
    // 输出到控制台
    if (g_config.options.targets & LOG_TARGET_CONSOLE) {
        if (level >= LOG_LEVEL_ERROR) {
            fputs(buf, stderr);
        } else {
            fputs(buf, stdout);
        }
    }
    // 输出到文件
    if ((g_config.options.targets & LOG_TARGET_FILE) && g_config.log_file != NULL) {
		fputs(buf, g_config.log_file);
        
		switch (g_config.options.mode) {
			case LOG_MODE_CYCLE:{
				long size = ftell(g_config.log_file);
				
				if (size > g_config.options.max_file_size) {
					log_close_file();
					log_rotate_file();
					log_open_file();
				}
				break;
			}
			case LOG_MODE_DAILY: {
				char date_str[9];
				strftime(date_str, sizeof(date_str), "%Y%m%d", tm_now);
				if (date_str != g_config.cur_log_day) {
					log_close_file();
					log_open_file();
				}
				break;
			}
			case LOG_MODE_HOURLY: {
				char hour_str[3];
				strftime(hour_str, sizeof(hour_str), "%H", tm_now);
				if (hour_str != g_config.cur_log_hour) {
					log_close_file();
					log_open_file();
				}
				break;
			}
		}     
    }
    
    // 立即刷新缓冲
    if (g_config.options.flush_immediately) {
        flushLog();
    }
    
    // 如果是FATAL级别，终止程序
    if (level == LOG_LEVEL_FATAL) {
        closeLog();
        exit(EXIT_FAILURE);
    }
}

void log_write(LogLevel level, const char *file, int line, const char *message) {
	size_t len = strlen(message);
	if(message == NULL || len == 0) return;
	if(level == LOG_LEVEL_OFF) return;
	if(level != LOG_LEVEL_TEXT)
	{
		if (level > g_config.options.level) {
			return;
		}
	}
    char buf[1024];
    
    // 格式化日志头
    int pos = 0;
    
	time_t now;
	struct tm *tm_now;
	
	// 获取当前时间
	time(&now);
	tm_now = localtime(&now);
		
    if (g_config.options.show_timestamp && level != LOG_LEVEL_TEXT) {

		struct timeval tv;
		gettimeofday(&tv, NULL);
        pos += strftime(buf + pos, sizeof(buf) - pos, "[%Y-%m-%d %H:%M:%S", tm_now);
		
		pos += snprintf(buf + pos,sizeof(buf) - pos,".%03ld]", tv.tv_usec / 1000);
    }
    
    if (g_config.options.show_log_level && level != LOG_LEVEL_TEXT) {
        const char *color = "";
        const char *color_reset = "";
        
        if (g_config.options.use_color && g_config.options.targets & LOG_TARGET_CONSOLE) {
            switch (level) {
                case LOG_LEVEL_TRACE: color = g_config.color_trace; break;
                case LOG_LEVEL_DEBUG: color = g_config.color_debug; break;
                case LOG_LEVEL_INFO:  color = g_config.color_info;  break;
                case LOG_LEVEL_WARN:  color = g_config.color_warn;  break;
                case LOG_LEVEL_ERROR: color = g_config.color_error; break;
                case LOG_LEVEL_FATAL: color = g_config.color_fatal; break;
                default: color = ""; break;
            }
            color_reset = g_config.color_reset;
        }
        
        pos += snprintf(buf + pos, sizeof(buf) - pos, "[%s%s%s] ", 
                       color, log_level_to_string(level), color_reset);
    }
    
    if (g_config.options.show_file_info && level != LOG_LEVEL_TEXT) {
        pos += snprintf(buf + pos, sizeof(buf) - pos, "(%s:%d) ", file, line);
    }
	
	if (pos + len < sizeof(buf)) {
		memcpy(buf + pos, message, len);
		pos += len;
		buf[pos] = '\0'; // 记得补终止符
	}
    
    // 确保以换行符结尾
    if (pos >= sizeof(buf) - 2) {
        pos = sizeof(buf) - 2;
    }
    if (buf[pos-1] != '\n') {
        buf[pos++] = '\n';
        buf[pos] = '\0';
    }
    
    // 输出到控制台
    if (g_config.options.targets & LOG_TARGET_CONSOLE) {
        if (level >= LOG_LEVEL_ERROR) {
            fputs(buf, stderr);
        } else {
            fputs(buf, stdout);
        }
    }
    // 输出到文件
    if ((g_config.options.targets & LOG_TARGET_FILE) && g_config.log_file != NULL) {
		fputs(buf, g_config.log_file);
        
		switch (g_config.options.mode) {
			case LOG_MODE_CYCLE:{
				long size = ftell(g_config.log_file);
				
				if (size > g_config.options.max_file_size) {
					log_close_file();
					log_rotate_file();
					log_open_file();
				}
				break;
			}
			case LOG_MODE_DAILY: {
				char date_str[9];
				strftime(date_str, sizeof(date_str), "%Y%m%d", tm_now);
				if (date_str != g_config.cur_log_day) {
					log_close_file();
					log_open_file();
				}
				break;
			}
			case LOG_MODE_HOURLY: {
				char hour_str[3];
				strftime(hour_str, sizeof(hour_str), "%H", tm_now);
				if (hour_str != g_config.cur_log_hour) {
					log_close_file();
					log_open_file();
				}
				break;
			}
		}     
    }
    
    // 立即刷新缓冲
    if (g_config.options.flush_immediately) {
        flushLog();
    }
    
    // 如果是FATAL级别，终止程序
    if (level == LOG_LEVEL_FATAL) {
        closeLog();
        exit(EXIT_FAILURE);
    }
}

void rep_write(const char *message) {
	if (!g_config.options.with_rep) return;
    size_t len = strlen(message);
    if (len == 0) return;

    // 输出到控制台
    if (g_config.options.targets & LOG_TARGET_CONSOLE) 
	{
        fputs(message, stdout);
		if (message[len - 1] != '\n') 
		{
			fputs("\n", stdout);
		}
    }
	
    // 输出到文件
    if ((g_config.options.targets & LOG_TARGET_FILE) && g_config.rep_file >= 0) {
		flock(g_config.rep_file, LOCK_EX); 
		//write() 会直接进入内核缓冲区，不会被用户态的 stdio 缓冲影响。不需要 fflush()，因为根本没用到 FILE* 的缓冲。
		ssize_t wlen = write(g_config.rep_file, message, len);
		
		if (message[len - 1] != '\n') 
		{
			wlen = write(g_config.rep_file,"\n", 1);
		}
		
		flock(g_config.rep_file, LOCK_UN);   		// 解锁
		switch (g_config.options.mode) {
			case LOG_MODE_CYCLE:{
				//long size = ftell(g_config.rep_file);
				long size = (long)lseek(g_config.rep_file, 0, SEEK_END);
				if (size > g_config.options.max_file_size) {
					rep_close_file();
					rep_rotate_file();
					rep_open_file();
				}
				break;
			}
			case LOG_MODE_DAILY: {
				char date_str[9];
				
				time_t now;
				struct tm *tm_now;
				time(&now);
				tm_now = localtime(&now);
	
				strftime(date_str, sizeof(date_str), "%Y%m%d", tm_now);
				if (date_str != g_config.cur_rep_day) {
					rep_close_file();
					rep_open_file();
				}
				break;
			}
			case LOG_MODE_HOURLY: {
				char hour_str[3];
				
				time_t now;
				struct tm *tm_now;
				time(&now);
				tm_now = localtime(&now);
				
				strftime(hour_str, sizeof(hour_str), "%H", tm_now);
				if (hour_str != g_config.cur_rep_hour) {
					rep_close_file();
					rep_open_file();
				}
				break;
			}
		}     
    }
}
