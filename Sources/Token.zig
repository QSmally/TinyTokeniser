
const Token = @This();

pub const Tag = enum {

    invalid,
    newline,
    eof,
    unexpected_eof,

    dot,
    comma,
    colon,
    semicolon,
    l_paran,
    r_paran,

    identifier,
    numeric_literal,
    string_literal
};

pub const Location = struct {

    start: usize,
    end: usize,

    pub fn eql(self: Location, location: Location) bool {
        return self.start == location.start and self.end == location.end;
    }

    pub fn slice(self: Location, from_buffer: [:0]const u8) []const u8 {
        return from_buffer[self.start..self.end];
    }
};

tag: Tag,
location: Location
