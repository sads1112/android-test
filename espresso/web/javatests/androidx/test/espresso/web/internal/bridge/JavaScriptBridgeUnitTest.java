/*
 * Copyright (C) 2015 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package androidx.test.espresso.web.internal.bridge;

import androidx.test.espresso.web.bridge.JavaScriptBridge;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;

/** JSB unit test. */
@RunWith(AndroidJUnit4.class)
public class JavaScriptBridgeUnitTest {

  @Test
  public void testMakeConduit() {
    // this will throw an exception if the instrumentation cannot install the bridge.
    // so in essence we're testing all our hacky setup code in installbridge here.

    JavaScriptBridge.makeConduit();
  }
}
