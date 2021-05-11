function print_table(t,c)
    if not c then c = {} end
    for k,v in pairs(c) do
        if v == t then
            return print("cyclic reference detected: " .. tostring(t))    
        end
    end
    table.insert(c,t)
    for k,v in pairs(t) do
        if type(v) == "table" then
            print(("Opening table %q"):format(tostring(k)))
            print_table(v,c)
            print(("Closing table %q"):format(tostring(k)))
        else
            if type(k) ~= "number" then
                k = ("\"%s\""):format(tostring(k))
            end
            print(("[%s] = %s"):format(tostring(k),tostring(v)))
        end
    end
end

local t = {a="Hello",b="World",c={"Testing"}}
t.d = t
print_table(t)
