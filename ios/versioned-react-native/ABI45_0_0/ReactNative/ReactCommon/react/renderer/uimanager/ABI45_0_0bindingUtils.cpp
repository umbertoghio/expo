/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include "ABI45_0_0bindingUtils.h"

#include <glog/logging.h>
#include <ABI45_0_0React/ABI45_0_0debug/ABI45_0_0React_native_assert.h>

namespace ABI45_0_0facebook::ABI45_0_0React {

static jsi::Value getModule(
    jsi::Runtime &runtime,
    std::string const &moduleName) {
  auto batchedBridge =
      runtime.global().getPropertyAsObject(runtime, "__fbBatchedBridge");
  auto getCallableModule =
      batchedBridge.getPropertyAsFunction(runtime, "getCallableModule");
  auto moduleAsValue = getCallableModule.callWithThis(
      runtime,
      batchedBridge,
      {jsi::String::createFromUtf8(runtime, moduleName)});
  if (!moduleAsValue.isObject()) {
    LOG(ERROR) << "getModule of " << moduleName << " is not an object";
  }
  ABI45_0_0React_native_assert(moduleAsValue.isObject());
  return moduleAsValue;
}

static bool checkBatchedBridgeIsActive(jsi::Runtime &runtime) {
  if (!runtime.global().hasProperty(runtime, "__fbBatchedBridge")) {
    LOG(ERROR)
        << "getPropertyAsObject: property '__fbBatchedBridge' is undefined, expected an Object";
    return false;
  }
  return true;
}

static bool checkGetCallableModuleIsActive(jsi::Runtime &runtime) {
  if (!checkBatchedBridgeIsActive(runtime)) {
    return false;
  }
  auto batchedBridge =
      runtime.global().getPropertyAsObject(runtime, "__fbBatchedBridge");
  if (!batchedBridge.hasProperty(runtime, "getCallableModule")) {
    LOG(ERROR)
        << "getPropertyAsFunction: function 'getCallableModule' is undefined, expected a Function";
    return false;
  }
  return true;
}

jsi::Value callMethodOfModule(
    jsi::Runtime &runtime,
    std::string const &moduleName,
    std::string const &methodName,
    std::initializer_list<jsi::Value> args) {
  if (checkGetCallableModuleIsActive(runtime)) {
    auto module = getModule(runtime, moduleName);
    if (module.isObject()) {
      jsi::Object object = module.asObject(runtime);
      ABI45_0_0React_native_assert(object.hasProperty(runtime, methodName.c_str()));
      if (object.hasProperty(runtime, methodName.c_str())) {
        auto method = object.getPropertyAsFunction(runtime, methodName.c_str());
        return method.callWithThis(runtime, object, args);
      } else {
        LOG(ERROR) << "getPropertyAsFunction: property '" << methodName
                   << "' is undefined, expected a Function";
      }
    }
  }

  return jsi::Value::undefined();
}

} // namespace ABI45_0_0facebook::ABI45_0_0React
