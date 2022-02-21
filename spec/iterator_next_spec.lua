require("mineunit")

mineunit("core")
sourcefile("init")

describe("iterator_next test", function()
	it("returns the proper coordinates", function()
        local pos = nil
		local pos1 = { x=4, y=0, z=0 }
		local pos2 = { x=4, y=0, z=1 }

        pos = modgen.iterator_next(pos1, pos2, pos)
        assert.equal(4, pos.x)
        assert.equal(0, pos.y)
        assert.equal(0, pos.z)

        pos = modgen.iterator_next(pos1, pos2, pos)
        assert.equal(4, pos.x)
        assert.equal(0, pos.y)
        assert.equal(1, pos.z)
	end)
end)
