--[[

TODO: Fix Stack so it inherits functions of previous stack, this will allow you to name functions the same while in different stacks

]]

local VMTable = {
    {"new","BanMessage","You have been banned!"},
    {"new","Banned",{}},
    {"new","Whitelisted",{}},
    {"new","Commands",{}},
    {"new","Prefix","."},
    {"def","Find",{"Table","Value"},{
        {"return",{"rawcall",{"index",{"global","table"},"find"},{"get","Table"},{"get","Value"}}},
    }},
    {"def","AddCommand",{"Words","Callback"},{
        {"rawcall",{"index",{"global","table"},"insert"},{{"get","Words"},{"get","Callback"}}},
    }},
    {"def","Substring",{"a","b","c"},{
        {"return",{"rawcall",{"index",{"global","string"},"sub"},{"get","a"},{"get","b"},{"get","c"}}},
    }},
    {"def","CheckCommand",{"Player","Message"},{
        {"new","Split",{"rawcall",{"index",{"global","string"},"split"},{"get","Message"}," "}},
        {"if",{"neq",{"call","Substring",{"index",{"get","Split"},1},1,{"len",{"get","Prefix"}}},{"get","Prefix"}},{
            {"return"},
        }},
        {"setindex",{"get","Split"},1,{"call","Substring",{"index",{"get","Split"},1},{"add",{"len",{"get","Prefix"}},1}}},
        {"setindex",{"get","Split"},1,{"rawcall",{"index",{"global","string"},"lower"},{"index",{"get","Split"},1}}},
        {"forpairs","k","v",{"get","Commands"},{
            {"if",{"rawcall",{"index",{"global","table"},"find"},{"index",{"get","v"},1},{"index",{"get","Split"},1}},{
                {"rawcall",{"index",{"global","table"},"remove"},{"get","Split"},1},
                {"return",{"rawcall",{"index",{"get","v"},2},{"get","Player"},{"get","Split"}}},
            }},
        }},
    }},
    {"def","Ban",{"Player","Args"},{
        {"new","Username",{"index",{"get","Args"},1}},
        {"new","Found",{"selfcall",{"get","Players"},"FindFirstChild",{"get","Username"}}},
        {"if",{"get","Found"},{
            {"selfcall",{"get","Found"},"Kick",{"get","BanMessage"}},
        }},
        {"rawcall",{"index",{"global","table"},"insert"},{"get","Banned"},{"get","Username"}},
    }},
    {"call","AddCommand",{"ban"},{"getfunc","Ban"}},
    {"new","Players",{"selfcall",{"global","game"},"GetService","Players"}},
    {"def","Joined",{"Player"},{
        {"if",{"call","Find",{"get","Whitelisted"},{"index",{"get","Player"},"Name"}},{
            {"def","Chatted",{"Message"},{
                {"return",{"call","CheckCommand",{"get","Player"},{"get","Message"}}},
            }},
            {"selfcall",{"index",{"get","Player"},"Chatted"},"Connect",{"getfunc","Chatted"}},
            {"return"},
        }},
        {"if",{"call","Find",{"get","Banned"},{"index",{"get","Player"},"Name"}},{
            {"return",{"selfcall",{"get","Player"},"Kick",{"get","BanMessage"}}},
        }},
    }},
    {"selfcall",{"index",{"get","Players"},"PlayerAdded"},"Connect",{"getfunc","Joined"}},
    {"forpairs","k","v",{"selfcall",{"get","Players"},"GetPlayers"},{
        {"call","Joined",{"get","v"}},  
    }},
}
