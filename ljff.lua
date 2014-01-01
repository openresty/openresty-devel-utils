local vmdef = require "jit.vmdef"
local ffid = arg[1]
if not ffid then
    print("No argument specified.")
    return
end
print("FastFunc " .. vmdef.ffnames[tonumber(ffid)])

