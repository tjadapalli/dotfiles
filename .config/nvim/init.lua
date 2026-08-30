print("🔥 Woohooo! Ba Bam Ba Bam!")
local start_time = vim.loop.hrtime()

-- load plugins
require("config")

local elapsed_ns = vim.loop.hrtime() - start_time  -- nanoseconds
local elapsed_ms = elapsed_ns / 1e6  -- convert to milliseconds

print(string.format("⚡ loaded in %.2f ms", elapsed_ms))

vim.fn.setenv("TZ", "America/Los_Angeles")
local pacific_time = os.date("%Y-%m-%d %I:%M %p")
print("🌅 Pacific Time: " .. pacific_time)
