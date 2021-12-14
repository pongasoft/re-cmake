// Implementation note: when doing jbox builds, loguru.cpp cannot be compiled because it relies on includes
// (like atomic) which are not part of the RE SDK due to sandboxing, as a result we disable logging in this instance
#if LOCAL_NATIVE_BUILD && DEBUG
// local native build => loguru debugging enabled
#define LOGURU_DEBUG_LOGGING 1
#define LOGURU_DEBUG_CHECKS 1
#else
// jbox build => loguru debugging disabled
#define LOGURU_DEBUG_LOGGING 0
#define LOGURU_DEBUG_CHECKS 0
#endif // LOCAL_NATIVE_BUILD

#include "loguru.hpp"
