
const Tokeniser = @This();

buffer: [:0]const u8,
cursor: usize = 0,

pub fn init(buffer_: [:0]const u8) Tokeniser {
    return .{ .buffer = buffer_ };
}

pub const Token = @import("Token.zig");

pub fn is_eof(self: *Tokeniser) bool {
    return self.cursor == self.buffer.len;
}

const State = enum {
    start,
    invalid,
    identifier,
    numeric_literal,
    decimal_literal,
    extended_numeric_literal,
    string_literal
};

pub fn next(self: *Tokeniser) Token {
    var result: Token = .{
        .tag = undefined,
        .location = .{
            .start = self.cursor,
            .end = undefined } };
    var helper = Helper.init(self, &result);

    state: switch (State.start) {
        .start => switch (helper.current()) {
            0 => if (self.is_eof())
                helper.tag(.eof) else
                helper.tag_next(.unexpected_eof),

            ' ', '\t', '\r' => {
                helper.discard();
                continue :state .start;
            },

            // single character tags
            '\n' => helper.tag_next(.newline),
            '.' => helper.tag_next(.dot),
            ',' => helper.tag_next(.comma),
            ':' => helper.tag_next(.colon),
            ';' => helper.tag_next(.semicolon),
            '(' => helper.tag_next(.l_paran),
            ')' => helper.tag_next(.r_paran),
            '{' => helper.tag_next(.l_brace),
            '}' => helper.tag_next(.r_brace),
            '[' => helper.tag_next(.l_bracket),
            ']' => helper.tag_next(.r_bracket),
            '+' => helper.tag_next(.plus),
            '-' => helper.tag_next(.minus),
            '=' => helper.tag_next(.equals),
            '!' => helper.tag_next(.bang),
            '*' => helper.tag_next(.star),
            '&' => helper.tag_next(.ampersand),
            '^' => helper.tag_next(.caret),
            '%' => helper.tag_next(.percent),
            '|' => helper.tag_next(.bar),
            '/' => helper.tag_next(.slash),
            '~' => helper.tag_next(.tilde),

            // beginning of tags
            'a'...'z', 'A'...'Z', '_' => continue :state .identifier,
            '0'...'9' => continue :state .numeric_literal,
            '"' => continue :state .string_literal,

            else => continue :state .invalid
        },

        // Mark current token as invalid until a boundary character, after
        // which the tokeniser can continue (either providing as many errors to
        // the user, or abort the process).
        .invalid => if (helper.is_next_boundary())
            helper.tag_lookahead(.invalid) else
            continue :state .invalid,

        // Tags any token starting with a-zA-Z_ and continuing with a-zA-Z0-9_
        // as identifier, or if found, a (pseudo)instruction or builtin.
        .identifier => switch (helper.next()) {
            'a'...'z', 'A'...'Z', '0'...'9', '_'  => continue :state .identifier,
            else => helper.tag_lookahead(.identifier)
        },

        // Any decimal, binary, hexadecimal or octal notation.
        .numeric_literal => switch (helper.next()) {
            '0'...'9' => continue :state .decimal_literal,
            'b', 'x', 'o' => continue :state .extended_numeric_literal,
            '_', // separator _ is not parseable by std.fmt.parseInt()
            'a', 'c'...'n', 'p'...'w', 'y'...'z', // a-z without b, x, o
            'A'...'Z' => continue :state .invalid,
            else => helper.tag_lookahead(.numeric_literal)
        },

        .decimal_literal => switch (helper.next()) {
            '0'...'9' => continue :state .decimal_literal,
            'a'...'z', 'A'...'Z', '_' => continue :state .invalid,
            else => helper.tag_lookahead(.numeric_literal)
        },

        .extended_numeric_literal => switch (helper.next()) {
            '0'...'9', 'A'...'Z' => continue :state .extended_numeric_literal,
            'a'...'z', '_' => continue :state .invalid,
            else => helper.tag_lookahead(.numeric_literal)
        },

        // A string literal is just a range of characters.
        .string_literal => switch (helper.next()) {
            '"' => helper.tag_next(.string_literal),
            0 => helper.tag(.unexpected_eof),
            '\n' => continue :state .invalid,
            else => continue :state .string_literal
        }
    }

    return result;
}

const Helper = struct {

    tokeniser: *Tokeniser,
    token: *Token,

    pub fn init(tokeniser: *Tokeniser, token: *Token) Helper {
        return .{
            .tokeniser = tokeniser,
            .token = token };
    }

    pub inline fn is_next_boundary(self: *Helper) bool {
        return switch (self.next()) {
            0, '\n', '\t', '\r', ' ',
            '.', ',', ':', ';',
            '(', ')', '{', '}', '[', ']',
            '+', '-', '=', '!', '*', '&', '^', '%', '|', '/', '~' => true,

            else => false
        };
    }

    pub inline fn current(self: *Helper) u8 {
        return self.tokeniser.buffer[self.tokeniser.cursor];
    }

    pub inline fn next(self: *Helper) u8 {
        self.tokeniser.cursor += 1;
        return self.current();
    }

    pub inline fn tag(self: *Helper, tag_: Token.Tag) void {
        self.token.tag = tag_;
        self.token.location.end = self.tokeniser.cursor + 1;
    }

    pub inline fn tag_lookahead(self: *Helper, tag_: Token.Tag) void {
        self.token.tag = tag_;
        self.token.location.end = self.tokeniser.cursor;
    }

    pub inline fn tag_next(self: *Helper, tag_: Token.Tag) void {
        self.tag(tag_);
        self.tokeniser.cursor += 1;
    }

    pub inline fn discard(self: *Helper) void {
        self.tokeniser.cursor += 1;
        self.token.location.start = self.tokeniser.cursor;
    }
};

// Tests

const std = @import("std");

fn testTokenise(input: [:0]const u8, expected_tokens: []const Token.Tag) !void {
    var tokeniser = Tokeniser.init(input);
    for (expected_tokens) |expected_token|
        try std.testing.expectEqual(expected_token, tokeniser.next().tag);
}

const SlicedToken = struct { Token.Tag, []const u8 };

fn testTokeniseSlices(input: [:0]const u8, expected_slices: []const SlicedToken) !void {
    var tokeniser = Tokeniser.init(input);

    for (expected_slices) |expected_slice| {
        const token = tokeniser.next();
        try std.testing.expectEqual(expected_slice[0], token.tag);
        if (token.tag != .newline) try std.testing.expectEqualSlices(u8, expected_slice[1], token.location.slice(input));
    }
}

test "eof" {
    try testTokenise("", &.{ .eof });
    try testTokenise("   ", &.{ .eof });
    try testTokenise("$", &.{ .invalid, .eof });
    try testTokenise("\x00", &.{ .unexpected_eof, .eof });
    try testTokenise("", &.{ .eof, .eof, .eof, .eof });
}

test "invalid" {
    try testTokenise("$", &.{ .invalid, .eof });
    try testTokenise("$aaaa", &.{ .invalid, .eof });
    try testTokenise("$+-", &.{ .invalid, .plus, .minus, .eof });
    try testTokenise("$;+", &.{ .invalid, .semicolon, .plus, .eof });
    try testTokenise("+$;+", &.{ .plus, .invalid, .semicolon, .plus, .eof });
}

test "single characters" {
    try testTokenise("+", &.{ .plus, .eof });
    try testTokenise("+-!", &.{ .plus, .minus, .bang, .eof });
    try testTokenise("foo == bar", &.{ .identifier, .equals, .equals, .identifier, .eof });
    try testTokenise("*=", &.{ .star, .equals, .eof });
    try testTokenise("=something", &.{ .equals, .identifier, .eof });
    try testTokenise("=9hello", &.{ .equals, .invalid, .eof });
    try testTokenise("=9xhello", &.{ .equals, .invalid, .eof });
    try testTokenise("=9x=hello", &.{ .equals, .numeric_literal, .equals, .identifier, .eof });
    try testTokenise("=&hello", &.{ .equals, .ampersand, .identifier, .eof });
    try testTokenise("=9&", &.{ .equals, .numeric_literal, .ampersand, .eof });
    try testTokenise("^%", &.{ .caret, .percent, .eof });
    try testTokenise("||", &.{ .bar, .bar, .eof });
    try testTokenise("//0b00", &.{ .slash, .slash, .numeric_literal, .eof });
    try testTokenise("0/5", &.{ .numeric_literal, .slash, .numeric_literal, .eof });
    try testTokenise("~&foo", &.{ .tilde, .ampersand, .identifier, .eof });
}

test "identifiers" {
    try testTokenise("x", &.{ .identifier, .eof });
    try testTokenise("x.", &.{ .identifier, .dot, .eof });
    try testTokenise("x.y", &.{ .identifier, .dot, .identifier, .eof });
    try testTokenise("x. y", &.{ .identifier, .dot, .identifier, .eof });
    try testTokenise("x,y", &.{ .identifier, .comma, .identifier, .eof });
    try testTokenise("x, y", &.{ .identifier, .comma, .identifier, .eof });
    try testTokenise("  x", &.{ .identifier, .eof });
}

test "numeric literals" {
    try testTokenise("6", &.{ .numeric_literal, .eof });
    try testTokenise("666", &.{ .numeric_literal, .eof });
    try testTokenise("0xFF", &.{ .numeric_literal, .eof });
    try testTokenise("0b10101111", &.{ .numeric_literal, .eof });
    try testTokenise("0x69", &.{ .numeric_literal, .eof });
    try testTokenise("x0FF", &.{ .identifier, .eof });
    try testTokenise("0x", &.{ .numeric_literal, .eof }); // TODO: fix
    try testTokenise("5x", &.{ .numeric_literal, .eof }); // TODO: fix
    try testTokenise("5x0", &.{ .numeric_literal, .eof }); // TODO: fix
    try testTokenise("0xxx", &.{ .invalid, .eof });
    try testTokenise("5xbx", &.{ .invalid, .eof });
    try testTokenise("50x", &.{ .invalid, .eof });
    try testTokenise("00A", &.{ .invalid, .eof });
}

test "string literals" {
    try testTokenise(" \" foo bar \" ", &.{ .string_literal, .eof });
    try testTokenise(" \" foo, bar, \" ", &.{ .string_literal, .eof });
    try testTokenise("\"hello world!\" 0x00 ", &.{ .string_literal, .numeric_literal, .eof });
    try testTokenise("\"0 && bar\"", &.{ .string_literal, .eof });
    try testTokenise("\" foo bar ", &.{ .unexpected_eof, .eof });
    try testTokenise("\" foo bar \n", &.{ .invalid, .eof });
    try testTokenise("\" foo bar '", &.{ .unexpected_eof, .eof });
}

test "full fledge" {
    try testTokeniseSlices(
        \\set window(1920, 1080) "foo"
        \\set attribute(.floating)
    , &.{
        .{ .identifier, "set" },
        .{ .identifier, "window" },
        .{ .l_paran, "(" },
        .{ .numeric_literal, "1920" },
        .{ .comma, "," },
        .{ .numeric_literal, "1080" },
        .{ .r_paran, ")" },
        .{ .string_literal, "\"foo\"" },
        .{ .newline, "" },
        .{ .identifier, "set" },
        .{ .identifier, "attribute" },
        .{ .l_paran, "(" },
        .{ .dot, "." },
        .{ .identifier, "floating" },
        .{ .r_paran, ")" },
    });
}
