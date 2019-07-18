import 'dart:math';
import 'dart:ui';

import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'package:flare_flutter/flare_controls.dart';

class TeddyController extends FlareControls {
  // Yüz kontrol 
  ActorNode _faceControl;

  // global flutter koordinatlarını flare koordinatlarına almak için matris depoladık.
  Mat2D _globalToFlareWorld = Mat2D();

  // Fluter Global koordinatlar
  Vec2D _caretGlobal = Vec2D();

  // Flare koordinatlar
  Vec2D _caretWorld = Vec2D();

  
  Vec2D _faceOrigin = Vec2D();
  Vec2D _faceOriginLocal = Vec2D();

  bool _hasFocus = false;

  
  static const double _projectGaze = 60.0;

  String _password;

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    super.advance(artboard, elapsed);
    Vec2D targetTranslation;
    if (_hasFocus) {
      
      Vec2D.transformMat2D(_caretWorld, _caretGlobal, _globalToFlareWorld);

      // Dikey kayma
      _caretWorld[1] +=
          sin(new DateTime.now().millisecondsSinceEpoch / 300.0) * 70.0;

      // Yön vektörünü hesapla
      Vec2D toCaret = Vec2D.subtract(Vec2D(), _caretWorld, _faceOrigin);
      Vec2D.normalize(toCaret, toCaret);
      Vec2D.scale(toCaret, toCaret, _projectGaze);

      // Dönüşüm hesaplama
      Mat2D toFaceTransform = Mat2D();
      if (Mat2D.invert(toFaceTransform, _faceControl.parent.worldTransform)) {
       
        Vec2D.transformMat2(toCaret, toCaret, toFaceTransform);
        // ctrl_face yüzü çevirmek için + vyön vektörü
        targetTranslation = Vec2D.add(Vec2D(), toCaret, _faceOriginLocal);
      }
    } else {
      targetTranslation = Vec2D.clone(_faceOriginLocal);
    }

    // _faceControl.translation işlemini targetTranslation değerine ayarlayabilirim. ancak bunu bu hedee sorunsuz şekilde canladırmak istediğim için 
    //kare hızından bağımsız olarak hızı korumasıiçin ona zaman ekledim.
    Vec2D diff =
        Vec2D.subtract(Vec2D(), targetTranslation, _faceControl.translation);
    Vec2D frameTranslation = Vec2D.add(Vec2D(), _faceControl.translation,
        Vec2D.scale(diff, diff, min(1.0, elapsed * 5.0)));

    _faceControl.translation = frameTranslation;

    return true;
  }

  
  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    _faceControl = artboard.getNode("ctrl_face");
    if (_faceControl != null) {
      _faceControl.getWorldTranslation(_faceOrigin);
      Vec2D.copy(_faceOriginLocal, _faceControl.translation);
    }
    play("idle");
  }

  onCompleted(String name) {
    play("idle");
  }

  // Flare Actor çağırdım,değişiklikleri görmek için.
  // matrisi güncelledim ve Global-Flutter-coordinates olanı Flare-World-coordinates çevirdim.
  @override
  void setViewTransform(Mat2D viewTransform) {
    Mat2D.invert(_globalToFlareWorld, viewTransform);
  }

  // [Offset] [Vec2D]'ye dönüştür.
  // Eğer caret  provided değilse, [_hasFocus] indir.
  void lookAt(Offset caret) {
    if (caret == null) {
      _hasFocus = false;
      return;
    }
    _caretGlobal[0] = caret.dx;
    _caretGlobal[1] = caret.dy;
    _hasFocus = true;
  }

  void setPassword(String value) {
    _password = value;
  }

  bool _isCoveringEyes = false;
  coverEyes(cover) {
    if (_isCoveringEyes == cover) {
      return;
    }
    _isCoveringEyes = cover;
    if (cover) {
      play("hands_up");
    } else {
      play("hands_down");
    }
  }

  void submitPassword() {
    if (_password == "bears") {
      play("success");
    } else {
      play("fail");
    }
  }
}
