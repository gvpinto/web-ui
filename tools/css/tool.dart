// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('csstool');

#import('dart:io');
#import('package:args/args.dart');
#import('../lib/file_system.dart');
#import('../lib/file_system_vm.dart');
#import('../lib/world.dart');
#import('../lib/utils.dart');
#import('../lib/source.dart');
#import('../lib/cmd_options.dart');
#import('css.dart');

FileSystem files;

/** Invokes [callback] and returns how long it took to execute in ms. */
num time(callback()) {
  final watch = new Stopwatch();
  watch.start();
  callback();
  watch.stop();
  return watch.elapsedInMs();
}

printStats(num elapsed, [String filename = '']) {
  print('Parsed ${GREEN_COLOR}${filename}${NO_COLOR} in ${elapsed} msec.');
}

/**
 * Run from the `tools/css` directory.
 *
 * Under google3 the location of the Dart VM is:
 *
 *   /home/<your name>/<P4 enlist dir>/google3/blaze-bin/third_party/dart_lang
 *
 * To use this tool your PATH must point to the location of the Dart VM:
 *
 *   export PATH=$PATH:/home/terry/src/google3/blaze-bin/third_party/dart_lang
 *
 * To run the tool CD to the location of the .scss file (e.g., lib/ui/view):
 *
 *   dart_bin ../tools/css/tool.dart --gen=view_lib_css view.scss
 *
 */
void main() {
  // tool.dart [options...] <css file>
  var args = commandOptions();
  ArgResults results = args.parse(new Options().arguments);

  if (results['help']) {
    print('Usage: [options...] <css input file>\n');
    print(args.getUsage());
    return;
  }

  // Compute the real output directory.
  String outputPath = results['out'];
  if (outputPath != null) {
    if (!outputPath.endsWith('/')) {
      outputPath = '$outputPath/';
    }
  } else {
    outputPath = "";
  }

  // genName used for library name, base filename for .css and .dart files.
  String genName = results['gen'];

  // CSS file to generate.
  String outputCssFn = '$outputPath$genName.css';

  // Dart file to generate.
  String outputDartFn = '$outputPath$genName.dart';

  // CSS input file to process.
  String sourceFullFn = results.rest[0];

  String sourcePath;
  String sourceFilename;
  int idxBeforeFilename = sourceFullFn.lastIndexOf('/');
  if (idxBeforeFilename >= 0) {
    sourcePath = sourceFullFn.substring(0, idxBeforeFilename + 1);
    sourceFilename = sourceFullFn.substring(idxBeforeFilename + 1);
  }

  // TODO(terry): Pass on switches first parameter in parseOptions.
  initCssWorld(parseOptions(results, files));

  files = new VMFileSystem();
  if (!files.fileExists(sourceFullFn)) {
    // Display colored error message if file is missing.
    print("\033[31mCSS source file missing - ${sourceFullFn}\033[0m");
  } else {
    String source = files.readAll(sourceFullFn);

    Stylesheet stylesheet;

    final elapsed = time(() {
      Parser parser = new Parser(
          new SourceFile(sourceFullFn, source), 0, files, sourcePath);
      stylesheet = parser.parse();
    });

    printStats(elapsed, sourceFullFn);

    StringBuffer buff = new StringBuffer(
      '/* File generated by SCSS from source ${sourceFilename}\n'
      ' * Do not edit.\n'
      ' */\n\n');
    buff.add(stylesheet.toString());

    files.writeString(outputCssFn, buff.toString());
    print("Generated file ${outputCssFn}");

    // Generate CSS.dart file.
    String genedClass = Generate.dartClass(stylesheet, sourceFilename, genName);

    // Write Dart file.
    files.writeString(outputDartFn, genedClass);

    print("Generated file ${outputDartFn}");
  }
}
