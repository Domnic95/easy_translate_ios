import 'dart:async';
import 'dart:io';

import 'package:easy_translate/models/translation.dart';

import 'deps.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class OcrProvider extends ChangeNotifier {
  final _picker = ImagePicker();
  String? imagePath;
  String recognized = '';
  Translation? result;
  bool isLoading = false;
  String? error;

  void applyDefaults() {
    source = currentAppSettings.defaultSource;
    target = currentAppSettings.defaultTarget;
    imagePath = null;
    recognized = '';
    result = null;
    error = null;
    notifyListeners();
  }

  String source = currentAppSettings.defaultSource;
  int _reqId = 0;

  void reset() {
    _reqId++;
    imagePath = null;
    recognized = '';
    result = null;
    isLoading = false;
    error = null;
    notifyListeners();
  }

  String target = currentAppSettings.defaultTarget;

  void setSource(String c) {
    source = c;
    notifyListeners();

    if (recognized.trim().isNotEmpty) _retranslate();
  }

  void setTarget(String c) {
    target = c;
    notifyListeners();
    if (recognized.trim().isNotEmpty) _retranslate();
  }

  Future<void> _retranslate() async {
    final req = ++_reqId;
    final text = recognized;
    final previousId = result?.id;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final (out, detected) = await translator.translate(
        text: text,
        source: source,
        target: target,
      );
      if (req != _reqId) return;

      final effectiveSource = source == 'auto' ? detected : source;
      result = Translation(
        id: previousId ?? uuid.v4(),
        sourceText: text,
        translatedText: out,
        sourceLang: effectiveSource,
        targetLang: target,
        createdAt: DateTime.now(),
        origin: result?.origin ?? TranslationOrigin.camera,
      );
      if (currentAppSettings.saveHistory) {
        unawaited(historyRepo.save(result!));
      }
      if (currentAppSettings.autoSpeak) {
        unawaited(
          tts.speak(out, lang: target, rate: currentAppSettings.speechRate),
        );
      }
    } catch (e) {
      if (req == _reqId) error = e.toString();
    } finally {
      if (req == _reqId && isLoading) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> pickGallery() => _run(ImageSource.gallery);
  Future<void> capture() => _run(ImageSource.camera);

  Future<void> _run(ImageSource s) async {
    final req = ++_reqId;
    try {
      final picked = await _picker.pickImage(source: s, imageQuality: 90);
      if (picked == null || req != _reqId) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop to text',
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop to text', aspectRatioLockEnabled: false),
        ],
      );
      if (req != _reqId) return;
      final finalPath = cropped?.path ?? picked.path;

      final prev = imagePath;
      if (prev != null && prev != finalPath) {
        try {
          final f = File(prev);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      if (cropped != null && cropped.path != picked.path) {
        try {
          final f = File(picked.path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }

      imagePath = finalPath;
      isLoading = true;
      error = null;
      recognized = '';
      result = null;
      notifyListeners();

      final text = await ocr.recognizeForLanguage(finalPath, source: source);
      if (req != _reqId) return;
      recognized = text;
      if (text.trim().isEmpty) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final (out, detected) = await translator.translate(
        text: text,
        source: source,
        target: target,
      );
      if (req != _reqId) return;
      final effectiveSource = source == 'auto' ? detected : source;
      result = Translation(
        id: uuid.v4(),
        sourceText: text,
        translatedText: out,
        sourceLang: effectiveSource,
        targetLang: target,
        createdAt: DateTime.now(),
        origin: s == ImageSource.camera
            ? TranslationOrigin.camera
            : TranslationOrigin.gallery,
      );
      if (currentAppSettings.saveHistory) {
        unawaited(historyRepo.save(result!));
      }
      if (currentAppSettings.autoSpeak) {
        unawaited(
          tts.speak(out, lang: target, rate: currentAppSettings.speechRate),
        );
      }
    } catch (e) {
      if (req == _reqId) error = e.toString();
    } finally {
      if (req == _reqId && isLoading) {
        isLoading = false;
        notifyListeners();
      }
    }
  }
}
