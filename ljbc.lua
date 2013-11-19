local vmdef = require "jit.vmdef"
local op = arg[1]
if not op then
    print("No argument specified.")
    return
end
print("opcode " .. op .. ":")
print(string.sub(vmdef.bcnames, op*6+1, op*6+6))

