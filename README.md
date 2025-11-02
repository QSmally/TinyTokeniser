
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
* Identifier
* Numeric literal
* String literal

## Installation

`zig fetch --save git+https://github.com/QSmally/TinyTokeniser`

```zig
const tinytokeniser = b.dependency("tinytokeniser", .{ ... });
exec.root_module.addImport("tinytokeniser", tinytokeniser.module("tinytokeniser"));
// ...
```

```zig
const TinyTokeniser = @import("tinytokeniser");
const Tag = TinyTokeniser.Token.Tag;

var tokeniser = TinyTokeniser.init(
    \\set window(3840, 2160) "foo"
);

try std.testing.expectEqual(Tag.identifier, tokeniser.next().tag);
try std.testing.expectEqual(Tag.identifier, tokeniser.next().tag);
try std.testing.expectEqual(Tag.l_paran, tokeniser.next().tag);
try std.testing.expectEqual(Tag.numeric_literal, tokeniser.next().tag);
try std.testing.expectEqual(Tag.comma, tokeniser.next().tag);
try std.testing.expectEqual(Tag.numeric_literal, tokeniser.next().tag);
try std.testing.expectEqual(Tag.r_paran, tokeniser.next().tag);
try std.testing.expectEqual(Tag.string_literal, tokeniser.next().tag);
try std.testing.expectEqual(Tag.eof, tokeniser.next().tag);
```

Commit HEAD compiled with Zig `0.14.1`.

I bashed this out of my [`QSmally/QCPU-CLI`](https://github.com/QSmally/QCPU-CLI) language for
common use.
