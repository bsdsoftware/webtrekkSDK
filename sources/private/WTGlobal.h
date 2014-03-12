// always logs a message to the console
#define WTLog   NSLog

// logs a warning to the console for the developer who uses the library
#define WTWarn  WTLog

// logs a message to the console which is only visible if the library was compiled in debug mode
#if DEBUG
#	define WTDebug WTLog
#else
#	define WTDebug(...)
#endif
