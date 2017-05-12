
#include "base/logging.h"

// THIS IS A STUBBED IMPLEMENTATION of the logging functions
// required to build the googleurl source. Eventually might want to 
// implement system appropriate logging instead

namespace logging {

// An assert handler override specified by the client to be called instead of
// the debug message dialog.
LogAssertHandlerFunction log_assert_handler = NULL;

// Called by logging functions to ensure that debug_file is initialized
// and can be used for writing. Returns false if the file could not be
// initialized. debug_file will be NULL in this case.

void InitLogging(const TCHAR* new_log_file, LoggingDestination logging_dest,
                 LogLockingState lock_log, OldFileDeletionState delete_old) {
}

void SetMinLogLevel(int level) {
}

void SetLogFilterPrefix(char* filter)  {
}

void SetLogItems(bool enable_process_id, bool enable_thread_id,
                 bool enable_timestamp, bool enable_tickcount) {
}

void SetLogAssertHandler(LogAssertHandlerFunction handler) {
}


LogMessage::LogMessage(const char* file, int line, LogSeverity severity,
                       int ctr)
    : severity_(severity) {
  Init(file, line);
}

LogMessage::LogMessage(const char* file, int line, const CheckOpString& result)
    : severity_(LOG_FATAL) {
  Init(file, line);
  stream_ << "Check failed: " << (*result.str_);
}

LogMessage::LogMessage(const char* file, int line)
     : severity_(LOG_INFO) {
  Init(file, line);
}

LogMessage::LogMessage(const char* file, int line, LogSeverity severity)
    : severity_(severity) {
  Init(file, line);
}

// writes the common header info to the stream
void LogMessage::Init(const char* file, int line) {
}

LogMessage::~LogMessage() {
}

void CloseLogFile() {
}

} // namespace logging

std::ostream& operator<<(std::ostream& out, const wchar_t* wstr) {
  return out;
}
