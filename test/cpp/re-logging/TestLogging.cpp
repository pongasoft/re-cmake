/*
 * Copyright (c) 2022 pongasoft
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 *
 * @author Yan Pujante
 */

#include <gtest/gtest.h>
#include <logging.h>

TEST(Logging, init_for_test)
{
  // init_for_test changes abort into exception that can be caught
  loguru::init_for_test("[Logging.init_for_test]");
  ASSERT_THROW(loguru::log_and_abort(0, "test", __FILE__, __LINE__), std::runtime_error);
  DLOG_F(INFO, "output 1");
  DLOG_F(INFO, "output 2");
}

TEST(Logging, init_for_re)
{
  // init_for_re displays the name of the re
  loguru::init_for_re("[My RE]");
  DLOG_F(INFO, "output 1");
  DLOG_F(INFO, "output 2");
}