local b=0;
function ob()b=b+1;end;
function cb()b=b-1;end;
local reg={};
function sreg(n,v,s)if s == nil then s = b;end;table.insert(reg,{n=n,v=v,s=s});end;
function ureg(n,nv,s)if s == nil then s = b;end;for k,v in pairs(reg) do if v.n == n and v.s == s then v.v = nv;return;end;end;end;
function creg(s)local nreg = {};for k,v in pairs(reg) do if v.s < s then table.insert(nreg,v);end;end;reg=nreg;end;
function greg(n,s)if s == nil then s = 0 end;local c = nil;for k,v in pairs(reg) do if v.n == n then if not c or c.s < v.s then c = v;end;end;end;if c ~= nil then return c.v end;return c;end;
function freg(c,p)return function(...)ob();local a = {...};for k,v in pairs(p) do sreg(v,a[k],b);end;c();creg(b);cb();end;end;
function fnlreg(n,a,f,c,d)for i=a,f,c do ob();sreg(n,i,b);d();creg(b);cb();end;end;
function ftlreg(a,f,c,d)for k,v in pairs(c) do ob();sreg(a,k,b);sreg(f,v,b);d();creg(b);cb();end;end;
function wlreg(a,f)while a() do ob();f();creg(b);cb();end;end;
function rlreg(a,f)repeat ob();f();creg(b);cb();until a();end;

fnlreg("i",1,10,1,function()
    print(greg("i"))
end)
