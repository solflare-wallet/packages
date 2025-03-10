// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Build;
import android.webkit.RenderProcessGoneDetail;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

@RequiresApi(api = Build.VERSION_CODES.O)
public class RenderProcessGoneDetailProxyApi extends PigeonApiRenderProcessGoneDetail {
  public RenderProcessGoneDetailProxyApi(@NonNull ProxyApiRegistrar pigeonRegistrar) {
    super(pigeonRegistrar);
  }

  @Override
  public boolean didCrash(@NonNull RenderProcessGoneDetail pigeon_instance) {
    return pigeon_instance.didCrash();
  }

  @Override
  public long rendererPriorityAtExit(@NonNull RenderProcessGoneDetail pigeon_instance) {
    return pigeon_instance.rendererPriorityAtExit();
  }
}
