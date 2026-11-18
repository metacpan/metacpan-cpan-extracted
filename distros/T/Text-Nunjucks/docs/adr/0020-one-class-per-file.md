# ADR 0020 — One class per .pm file: no inner packages, no generated node classes

- Status: decided
- Date: 2026-11-17
- Tags: structure, packaging, k116

## Context

Several modules declared more than one package: `Lexer.pm` held `Lexer::Token`
and `Lexer::Tokenizer`, `Parser.pm` held `Parser::Parser`, `Compiler.pm` held
`Compiler::Compiler`, `Runtime.pm` held `Runtime::{None,KwArgs,Regex,SafeString,Frame}`,
`Environment.pm` held `Context` and `Template`, and `Nodes.pm` held
`Nodes::{Node,Value,NodeList,FromImport,CallExtension,Set}` besides the
roughly sixty node types it generated from a table at load time (ADR 0002).

`dzil build` warned that 17 entries of the provides map did not map to `.pm`
files and might not be loadable at install time. The consequences are real, not
cosmetic: PAUSE indexes the name from the wrong file, `require
Text::Nunjucks::Lexer::Token` fails until some other module has been loaded, and
a CPAN client cannot find the file for a module name. Hiding the inner packages
from the index (`no_index`) would have silenced the warning and left the other
two problems.

## Decision

In Text::Nunjucks every class lives in its own `.pm` file, at the path its name
implies: `Text::Nunjucks::Lexer::Token` is
`lib/Text/Nunjucks/Lexer/Token.pm`. There are no inner `package` blocks and no
classes created at run time; that includes the AST node types, which are one
hand-written file per upstream `extend()` call in `nodes.js`.

Class names do not change (`Parser::Parser` and `Compiler::Compiler` stay what
they are). A parent module keeps loading the classes it uses, and every class
is loadable on its own with `require`.

An author check, `xt/one-class-per-file.t`, enforces the rule (k116).

## Consequences

- Partially supersedes ADR 0002: the sentence that the node types are
  generated from their field lists, "not sixty hand-written class files", no
  longer holds. The rest of ADR 0002 (Moo for every class, `object.js` not
  ported) stands.
- The distribution ships many small files; a node type's fields are read in
  its own file instead of in one table, in the same order as in `nodes.js`.
- The provides map and the PAUSE index name each module from its own file, and
  the `dzil build` warning is gone.
- Class names, and with them every `isa` check, `ref` result and `blessed`
  comparison, are unchanged; there is nothing template authors can observe, so
  this is not an entry in "DIFFERENCES FROM NUNJUCKS".
