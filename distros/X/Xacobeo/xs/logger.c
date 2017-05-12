#include "logger.h"

#include <glib.h>
#include <glib/gprintf.h>
#include <string.h>

// For more codes see http://www.termsys.demon.co.uk/vtansi.htm
#define COLOR_RED    "\033[0;40;31m"
#define COLOR_GREEN  "\033[0;40;32m"
#define COLOR_YELLOW "\033[0;40;33m"
#define COLOR_CYAN   "\033[0;40;36m"
#define COLOR_NORMAL "\033[0m"


//
// Time units, used for formatting the logging messages
//
typedef struct _MyLoggerTimeUnits {
	int         limit;
	const char *unit;
} MyLoggerTimeUnits;


static MyLoggerTimeUnits TIME_UNITS [] = {
	{1000, "\u03BCs"},
	{1000, "ms"},
};


//
// Logging function do not use directly, instead use the macros:
// TRACE, DEBUG, INFO, WARN and ERROR.
//
// NOTE: DO NOT USE any of the debugging macros within this function otherwise
//       an infinite recusion will happen.
//
void
my_logger_log (
	const char *file, 
	int         line, 
	const char *function, 
	const char *level, 
	const char *format, 
	...
) {

	static GTimeVal last = {0, 0};

	// Format the user's string
	va_list args;
	va_start(args, format);
	gchar * message = g_strdup_vprintf(format, args);
	va_end (args);


	// Calculate the elapsed time since the last logging statement
	GTimeVal now;
	g_get_current_time(&now);
	glong elapsed = 0;
	if (last.tv_sec) {
		// Calculate the number of micro seconds spent since the last time
		elapsed = (now.tv_sec - last.tv_sec) * 1000000; // Seconds
		elapsed += now.tv_usec - last.tv_usec; // Microseconds
	}

		
	// Find the best unit for the elapsed time
	const char *units = "";
	int units_count = sizeof(TIME_UNITS)/sizeof(MyLoggerTimeUnits);
	for (int i = 0; i < units_count; ++i) {
		MyLoggerTimeUnits time_units = TIME_UNITS[i];

		units = time_units.unit;
		
		if (elapsed < time_units.limit) {
			break;
		}
		else if (i + 1 != units_count) {
			elapsed /= time_units.limit;
		}
	}
	
	const char *color = COLOR_NORMAL;
	if (strcmp(level, "INFO") == 0) {
		color = COLOR_GREEN;
	}
	else if (strcmp(level, "WARN") == 0) {
		color = COLOR_YELLOW;
	}
	else if (strcmp(level, "ERROR") == 0) {
		color = COLOR_RED;
	}
	else if (strcmp(level, "NOTE") == 0) {
		color = COLOR_CYAN;
	}
 
	
	// Display the logging message
	g_printf("%s%-5s %5li%-2s %s [%s:%d %s]" COLOR_NORMAL "\n", color, level, elapsed, units, message, file, line, function);
	g_free(message);
	
	last = now;
}
