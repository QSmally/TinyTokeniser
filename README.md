
# Tiny Tokeniser

Tiny, language-agnostic tokeniser

## Description

A trivial tokeniser for simple languages or DSLs.

Supports the following tokens:

* Newline
* Eof
* Dot (`.`)
* Comma (`,`)
* Colon (`:`)
* Semicolon (`;`)
* Lparan (`(`) and Rparan (`)`)
* Lbrace (`{`) and Rbrace (`}`)
* Lbracket (`[`) and Rbracket (`]`)
* Plus (`+`)
* Minus (`-`)
* Equals (`=`)
* Bang (`!`)
* Star (`*`)
* Ampersand (`&`)
* Caret (`^`)
* Percent (`%`)
* Bar (`|`)
* Slash (`/`)
* Tilde (`~`)
* Identifier (`a-zA-Z_` + `0-9`)
* Numeric literal (`0-9` + [`0b` `0x`] + `0-9`)
* String literal (`".*"`)

## Installation

`zig fetch --save git+https://github.com/QSmally/TinyTokeniser`

```zig
const tinytokeniser = b.dependency("tinytokeniser", .{ ... });
exec.root_module.addImport("tinytokeniser", tinytokeniser.module("tinytokeniser"));
// ...
```

```zig
const TinyTokeniser = @import("tinytokeniser");

const tokeniser = TinyTokeniser.init(
    \\set window(3840, 2160) "foo"
);

tokeniser.next(); // .identifier
tokeniser.next(); // .identifier
tokeniser.next(); // .l_paran
tokeniser.next(); // .numeric_literal
tokeniser.next(); // .comma
tokeniser.next(); // .numeric_literal
tokeniser.next(); // .r_paran
tokeniser.next(); // .string_literal
tokeniser.next(); // .eof
```

Commit HEAD compiled with Zig `0.14.1`.

I bashed this out of my [`QSmally/QCPU-CLI`](https://github.com/QSmally/QCPU-CLI) language for
common use.
