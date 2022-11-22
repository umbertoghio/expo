/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <ABI47_0_0React/ABI47_0_0renderer/components/unimplementedview/UnimplementedViewProps.h>
#include <ABI47_0_0React/ABI47_0_0renderer/components/view/ConcreteViewShadowNode.h>

namespace ABI47_0_0facebook {
namespace ABI47_0_0React {

extern const char UnimplementedViewComponentName[];

using UnimplementedViewShadowNode = ConcreteViewShadowNode<
    UnimplementedViewComponentName,
    UnimplementedViewProps>;

} // namespace ABI47_0_0React
} // namespace ABI47_0_0facebook
