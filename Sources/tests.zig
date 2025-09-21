
pub const Tokeniser = @import("tinytokeniser");
pub const Token = Tokeniser.Token;

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
