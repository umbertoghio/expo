#pragma once

#include <ABI45_0_0jsi/ABI45_0_0jsi.h>
#include <stdio.h>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>
#include "Scheduler.h"

using namespace ABI45_0_0facebook;

namespace ABI45_0_0reanimated {

class RuntimeManager;

struct StaticStoreUser {
  std::atomic<int> ctr;
  std::unordered_map<int, std::vector<std::shared_ptr<jsi::Value>>> store;
  std::recursive_mutex storeMutex;
};

class StoreUser {
  int identifier = 0;
  std::weak_ptr<Scheduler> scheduler;
  std::shared_ptr<StaticStoreUser> storeUserData;

 public:
  StoreUser(std::shared_ptr<Scheduler> s, const RuntimeManager &runtimeManager);

  std::weak_ptr<jsi::Value> getWeakRef(jsi::Runtime &rt);
  void removeRefs();

  virtual ~StoreUser();
};

} // namespace reanimated
