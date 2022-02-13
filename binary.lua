-- Source: https://gist.github.com/minism/3646479

function modgen.decode_uint8(str, ofs)
    ofs = ofs or 0
    return string.byte(str, ofs + 1)
end

function modgen.decode_uint16(str, ofs)
    ofs = ofs or 0
    local a, b = string.byte(str, ofs + 1, ofs + 2)
    return a + b * 0x100
end

function modgen.decode_uint32(str, ofs)
    ofs = ofs or 0
    local a, b, c, d = string.byte(str, ofs + 1, ofs + 4)
    return a + b * 0x100 + c * 0x10000 + d * 0x1000000
end

function modgen.encode_uint8(int)
    return string.char(int)
end

function modgen.encode_uint16(int)
    local a, b = int % 0x100, int / 0x100
    return string.char(a, b)
end

function modgen.encode_uint32(int)
    local a, b, c, d =
        int % 0x100,
        int / 0x100 % 0x100,
        int / 0x10000 % 0x100,
        int / 0x1000000
    return string.char(a, b, c, d)
end