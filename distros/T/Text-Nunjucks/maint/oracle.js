#!/usr/bin/env node
// The oracle: runs cases through the pinned upstream Nunjucks and prints what
// the original does. The Perl port is measured against this output, never
// against a reading of the docs.
//
//   node maint/oracle.js < cases.json > results.json
//   node maint/oracle.js cases.json
//
// Input: one case object or an array of them.
//   { "name": "...",                       // echoed back
//     "mode": "render" | "lex" | "parse",  // default "render"
//     "template": "{{ a }}",               // source string, or
//     "render": "page.njk",                //   a name looked up in "templates"
//     "templates": { "base.njk": "..." },  // in-memory loader contents
//     "context": { ... },                  // JSON only -- no functions
//     "opts": { "autoescape": true, ... }, // Environment / lexer opts
//     "jinjaCompat": false }
//
// File-system render cases (k19) load through upstream's real loaders over
// fixture directories in the repository instead of the in-memory loader:
//     "fileSystemLoader": { "searchPaths": "t/data/loader/views",  // or [...]
//                           "opts": { "noCache": true } },       // any JSON
//                                  // -> new FileSystemLoader(searchPaths, opts)
//     "defaultLoader": true,      // -> new Environment(undefined, opts), whose
//                                 //    init adds FileSystemLoader('views')
//     "cwd": "t/data/loader",     // the case runs in this directory, relative
//                                 //    to the repository root (default: root)
// Relative search paths resolve against that cwd, as in node. A file-system
// case reports the absolute repository root as "<root>" in output, error
// message and stdout, so the committed expectation does not depend on where
// the checkout lives; t/corpus.t applies the same substitution.
//
// Output: an array, one result per case, in order.
//   { "name", "ok": true,  "output": <string | tokens | ast> }
//   { "name", "ok": false, "error": { "name", "message" } }
// plus "stdout": "<text>" when the case wrote to console.log (FileSystemLoader's
// boolean-opts warning).
'use strict';

const fs = require('fs');
const path = require('path');
const util = require('util');
const Module = require('module');

// The port is upstream installed without its optional peer dependency chokidar
// (ADR 0018), so the oracle hides it: FileSystemLoader's `watch` takes
// upstream's own no-chokidar branch ('watch requires chokidar to be
// installed') instead of starting a watcher, which would also keep node
// running after the last case.
const resolveFilename = Module._resolveFilename;
Module._resolveFilename = function(request, ...rest) {
  if (request === 'chokidar') {
    const e = new Error(`Cannot find module '${request}'`);
    e.code = 'MODULE_NOT_FOUND';
    throw e;
  }
  return resolveFilename.call(this, request, ...rest);
};

const nunjucks = require(path.join(__dirname, '..', 'upstream', 'nunjucks', 'nunjucks', 'index.js'));
const {lexer, parser, nodes} = nunjucks;

// The repository root as process.cwd() reports it (physical, no symlinks).
const root = fs.realpathSync(path.join(__dirname, '..'));

class MemoryLoader extends nunjucks.Loader {
  constructor(templates) {
    super();
    this.templates = templates || {};
  }
  getSource(name) {
    if (!Object.prototype.hasOwnProperty.call(this.templates, name)) {
      return null;
    }
    return {src: this.templates[name], path: name, noCache: true};
  }
}

function lex(c) {
  const tokens = [];
  const t = lexer.lex(c.template, c.opts);
  let tok;
  while ((tok = t.nextToken())) {
    tokens.push({type: tok.type, value: tok.value, lineno: tok.lineno, colno: tok.colno});
  }
  return tokens;
}

// AST as plain JSON: { type, lineno, colno, <fields in nodes.js order> }.
// NodeList-likes carry "children". Non-node field values pass through as-is;
// a RegExp literal becomes { regex: source, flags }.
function ast(n) {
  if (n instanceof nodes.Node) {
    const out = {type: n.typename, lineno: n.lineno, colno: n.colno};
    n.fields.forEach((f) => { out[f] = ast(n[f]); });
    return out;
  }
  if (Array.isArray(n)) {
    return n.map(ast);
  }
  if (n instanceof RegExp) {
    return {regex: n.source, flags: n.flags};
  }
  return n === undefined ? null : n;
}

function isFileSystemCase(c) {
  return c.fileSystemLoader !== undefined || c.defaultLoader !== undefined;
}

function environment(c) {
  if (c.defaultLoader) {
    return new nunjucks.Environment(undefined, c.opts);
  }
  if (c.fileSystemLoader !== undefined) {
    const l = c.fileSystemLoader;
    return new nunjucks.Environment(new nunjucks.FileSystemLoader(l.searchPaths, l.opts), c.opts);
  }
  return new nunjucks.Environment(new MemoryLoader(c.templates), c.opts);
}

// "<root>" for the absolute repository root (file-system cases only).
function rootless(s) {
  return typeof s === 'string' ? s.split(root).join('<root>') : s;
}

// Always the callback form: it is the only one that covers async tags and
// filters, and upstream defers the callback (asap) even for sync templates.
function render(c) {
  const env = environment(c);
  const ctx = c.context || {};
  return new Promise((resolve, reject) => {
    const cb = (err, res) => (err ? reject(err) : resolve(res));
    if (c.render !== undefined) {
      env.render(c.render, ctx, cb);
    } else {
      env.renderString(c.template, ctx, cb);
    }
  });
}

async function run(c) {
  const uninstall = c.jinjaCompat ? nunjucks.installJinjaCompat() : null;
  const fsCase = isFileSystemCase(c);
  const strip = fsCase ? rootless : (s) => s;
  const consoleLog = console.log;
  let stdout = '';
  console.log = (...args) => {
    stdout += util.format(...args) + '\n';
  };
  const result = {name: c.name};
  const cwd = process.cwd();
  try {
    if (fsCase) {
      process.chdir(path.join(root, c.cwd || '.'));
    }
    const mode = c.mode || 'render';
    const output = mode === 'lex' ? lex(c)
      : mode === 'parse' ? ast(parser.parse(c.template, [], c.opts))
        : await render(c);
    Object.assign(result, {ok: true, output: strip(output)});
  } catch (e) {
    Object.assign(result, {ok: false, error: {name: e.name, message: strip(e.message)}});
  } finally {
    console.log = consoleLog;
    process.chdir(cwd);
    if (uninstall) {
      uninstall();
    }
  }
  if (stdout !== '') {
    result.stdout = strip(stdout);
  }
  return result;
}

async function main() {
  const input = JSON.parse(fs.readFileSync(process.argv[2] || 0, 'utf8'));
  const cases = Array.isArray(input) ? input : [input];
  const results = [];
  // Sequential on purpose: installJinjaCompat patches global state.
  for (const c of cases) {
    results.push(await run(c));
  }
  process.stdout.write(JSON.stringify(results, null, 2) + '\n');
}

main();
