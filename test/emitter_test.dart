// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * These are not quite unit tests, since we build on top of the analyzer and the
 * html5parser to build the input for each test.
 */
library emitter_test;

import 'package:html5lib/dom.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/analyzer.dart';
import 'package:web_components/src/emitters.dart';
import 'testing.dart';


main() {
  useVmConfiguration();
  useMockMessages();
  group('emit element field', () {
    group('declaration', () {
      test('id only, no data binding', () {
        var elem = parseSubtree('<div id="one"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter), equals(''));
      });

      test('action with no id', () {
        var elem = parseSubtree('<div data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter), equals('var ___e0;'));
      });

      test('action with id', () {
        var elem = parseSubtree('<div id="my-id" data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter), equals('var _myId;'));
      });

      test('1 way binding with no id', () {
        var elem = parseSubtree('<div class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter), equals('var ___e0;'));
      });

      test('1 way binding with id', () {
        var elem = parseSubtree('<div id="my-id" class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter), equals('var _myId;'));
      });

      test('2 way binding with no id', () {
        var elem = parseSubtree('<input data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter),
            equals('var ___e0;'));
      });

      test('2 way binding with id', () {
        var elem = parseSubtree(
          '<input id="my-id" data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_declarations(emitter),
            equals('var _myId;'));
      });
    });

    group('created', () {
      test('id only, no data binding', () {
        var elem = parseSubtree('<div id="one"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals(''));
      });

      test('action with no id', () {
        var elem = parseSubtree('<div data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals("___e0 = _root.query('#__e-0');"));
      });

      test('action with id', () {
        var elem = parseSubtree('<div id="my-id" data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals("_myId = _root.query('#my-id');"));
      });

      test('1 way binding with no id', () {
        var elem = parseSubtree('<div class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals("___e0 = _root.query('#__e-0');"));
      });

      test('1 way binding with id', () {
        var elem = parseSubtree('<div id="my-id" class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals("_myId = _root.query('#my-id');"));
      });

      test('2 way binding with no id', () {
        var elem = parseSubtree('<input data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals("___e0 = _root.query('#__e-0');"));
      });

      test('2 way binding with id', () {
        var elem = parseSubtree(
          '<input id="my-id" data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(elem, _elemInfo(elem));
        expect(_created(emitter), equals("_myId = _root.query('#my-id');"));
      });
    });
  });

  group('emit event listeners', () {
    test('declaration for action', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(elem, _elemInfo(elem));
      expect(_declarations(emitter), equals(
          'autogenerated.EventListener _listener_foo_1;'));
    });

    test('declaration for input value data-bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(elem, _elemInfo(elem));
      expect(_declarations(emitter),
        equals('autogenerated.EventListener _listener_input_1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(elem, _elemInfo(elem));
      expect(_created(emitter), equals(''));
    });

    test('inserted', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(elem, _elemInfo(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_listener_foo_1 = (e) { bar(e); autogenerated.dispatch(); }; '
          '___e0.on.foo.add(_listener_foo_1);'));
    });

    test('inserted for input value data bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(elem, _elemInfo(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_listener_input_1 = (e) { bar = ___e0.value; '
          'autogenerated.dispatch(); }; '
          '___e0.on.input.add(_listener_input_1);'));
    });

    test('removed', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(elem, _elemInfo(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '___e0.on.foo.remove(_listener_foo_1); '
          '_listener_foo_1 = null;'));
    });
  });

  group('emit data binding watchers', () {
    test('declaration', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(elem, _elemInfo(elem));
      expect(_declarations(emitter),
        equals('autogenerated.WatcherDisposer _stopWatcher___e0_1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(elem, _elemInfo(elem));
      expect(_created(emitter), equals(''));
    });

    test('inserted for attribute', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(elem, _elemInfo(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stopWatcher___e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { '
          '___e0.foo = e.newValue; });'));
    });

    test('inserted for data- attribute', () {
      var elem = parseSubtree('<div data-foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(elem, _elemInfo(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stopWatcher___e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { '
          '___e0.dataAttributes["foo"] = e.newValue; });'));
    });

    test('inserted for content', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new DataBindingEmitter(elem, _elemInfo(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          "_stopWatcher___e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { "
          "___e0.innerHTML = 'fo\${bar}o'; });"));
    });

    test('removed', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(elem, _elemInfo(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '_stopWatcher___e0_1();'));
    });
  });
}

_elemInfo(Element elem) {
  return analyzeNode(elem).elements[elem];
}

_declarations(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  return context.declarations.toString().trim();
}

_created(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitCreated(context);
  return context.createdMethod.toString().trim();
}

_inserted(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitInserted(context);
  return context.insertedMethod.toString().trim();
}

_removed(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitRemoved(context);
  return context.removedMethod.toString().trim();
}
