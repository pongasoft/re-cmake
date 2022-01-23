#pragma once

#ifndef __Pongasoft_re_logging_h__
#define __Pongasoft_re_logging_h__

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

#include <JukeboxTypes.h>

/**
 * Implementation details
 */
namespace impl {
template<typename... Args>
inline void JBox_LogValues(const char iFile[], TJBox_Int32 iLine, char const *iMessage, Args&& ...iValues)
{
  TJBox_Value values[sizeof...(iValues)] { iValues... };
  JBox_TraceValues(iFile, iLine, iMessage, values, sizeof...(iValues));
}
}

#if DEBUG
/**
 * Allow to write simpler code:
 *
 * ```cpp
 *    // using JBOX_TRACEVALUES
 * 		TJBox_Value instanceIDValue = JBox_MakeNumber(JBox_GetNumber(iParams[0]));
 *		TJBox_Value array[1];
 *		array[0] = instanceIDValue;
 *		JBOX_TRACEVALUES("instance ID = ^0", array, 1);
 *
 *    // using JBOX_LOGVALUES
 *		JBOX_LOGVALUES("instance ID = ^0", iParams[0]));
 * ```
 */
#define JBOX_LOGVALUES(iMessage, ...) \
	::impl::JBox_LogValues(__FILE__, __LINE__, iMessage, __VA_ARGS__)
#else
#define JBOX_LOGVALUES(iMessage, ...)
#endif

#if LOGURU_DEBUG_CHECKS
namespace loguru {
/**
 * This function can be called when the device is created to make loguru output nicer (essentially replaces
 * the name of the thread which is useless, by the name of the rack extension which can be useful when you
 * have different REs using loguru) */
inline void init_for_re(char const *iREName = nullptr)
{
  loguru::g_preamble_thread = false;
//  loguru::g_preamble_prefix = iREName;
}

/**
 * This function can be used from tests to replace loguru aborts with exception (which can be checked) */
void init_for_test(char const *iPrefix = nullptr);

}
#endif

#endif