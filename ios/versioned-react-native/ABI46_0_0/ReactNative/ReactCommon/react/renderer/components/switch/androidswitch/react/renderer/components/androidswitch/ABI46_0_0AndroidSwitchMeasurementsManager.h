/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <ABI46_0_0React/ABI46_0_0renderer/core/ConcreteComponentDescriptor.h>
#include <ABI46_0_0React/ABI46_0_0renderer/core/LayoutConstraints.h>
#include <ABI46_0_0React/ABI46_0_0utils/ContextContainer.h>

namespace ABI46_0_0facebook {
namespace ABI46_0_0React {

class AndroidSwitchMeasurementsManager {
 public:
  AndroidSwitchMeasurementsManager(
      const ContextContainer::Shared &contextContainer)
      : contextContainer_(contextContainer) {}

  Size measure(SurfaceId surfaceId, LayoutConstraints layoutConstraints) const;

 private:
  const ContextContainer::Shared contextContainer_;
  mutable std::mutex mutex_;
  mutable bool hasBeenMeasured_ = false;
  mutable Size cachedMeasurement_{};
};

} // namespace ABI46_0_0React
} // namespace ABI46_0_0facebook
