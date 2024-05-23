// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Autogenerated from Pigeon (v19.0.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, unnecessary_import, no_leading_underscores_for_local_identifiers
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;
import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:file_selector_ios/src/messages.g.dart';

class _TestFileSelectorApiCodec extends StandardMessageCodec {
  const _TestFileSelectorApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is FileSelectorConfig) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return FileSelectorConfig.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class TestFileSelectorApi {
  static TestDefaultBinaryMessengerBinding? get _testBinaryMessengerBinding =>
      TestDefaultBinaryMessengerBinding.instance;
  static const MessageCodec<Object?> pigeonChannelCodec =
      _TestFileSelectorApiCodec();

  Future<List<String?>> openFile(FileSelectorConfig config);

  static void setUp(
    TestFileSelectorApi? api, {
    BinaryMessenger? binaryMessenger,
    String messageChannelSuffix = '',
  }) {
    messageChannelSuffix =
        messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> __pigeon_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.file_selector_ios.FileSelectorApi.openFile$messageChannelSuffix',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        _testBinaryMessengerBinding!.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(__pigeon_channel, null);
      } else {
        _testBinaryMessengerBinding!.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(__pigeon_channel,
                (Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.file_selector_ios.FileSelectorApi.openFile was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final FileSelectorConfig? arg_config =
              (args[0] as FileSelectorConfig?);
          assert(arg_config != null,
              'Argument for dev.flutter.pigeon.file_selector_ios.FileSelectorApi.openFile was null, expected non-null FileSelectorConfig.');
          try {
            final List<String?> output = await api.openFile(arg_config!);
            return <Object?>[output];
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
