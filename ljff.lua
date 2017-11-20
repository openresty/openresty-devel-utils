local vmdef = require "jit.vmdef"
if #arg == 0 then
    print("No argument specified.")
    return
end

for i = 1, #arg do
    local ffid = arg[i]
    print("FastFunc " .. vmdef.ffnames[tonumber(ffid)])
end
