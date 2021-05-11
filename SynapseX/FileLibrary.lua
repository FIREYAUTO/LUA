--[[

Synapse X FileLibrary

Programmed by FIREYAUTO

Not tested yet, so it might not work

Documentation:

    >FileSystem:

        *FileSystem.new(Path: <String>) --Creates a new "File" object
    
    >File
    
        *File.Name -> String --The name of the file
        *File.Type -> String --The file extension type
        *File.IsNew -> Boolean --Whether or not the file exists yet
        *File.Path -> String --The raw path of the file
    
        *File:IsFolder() -> Boolean --Returns true if the file is a folder
        *File:IsFile() -> Boolean --Returns true if the file is a file
        *File:GetSource() -> String --Returns the source of the file
        *File:SetSource(Source: <String>) -> Void --Sets the source of the file
        *File:Create(Type: <String>) -> Void --Creates the file if it does not exist
        *File:Delete() -> Void --Deletes the file if it exists, the "File" object will not be deleted
        *File:IsValidPath() -> Boolean --Returns true if the file is a valid path (if it exists)
        *File:GetFiles() -> Table --Returns a table of "File" objects inside of the "File" object (If it's a folder)

]]
local FileSystem = {
    Cache={},
    FileMethods={
        GetSource = function(self)
            if not self:IsValidPath() then return end
            if not self:IsFile() then return end
            return readfile(self.Path)
        end,
        SetSource = function(self,Source)
            if not self:IsValidPath() then return end
            if not self:IsFile() then return end
            return writefile(self.Path,Source)
        end,
        IsFolder = function(self)
            return isfolder(self.Path)
        end,
        IsFile = function(self)
            return isfile(self.Path)
        end,
        IsValidPath = function(self)
            return self:IsFolder() or self:IsFile()
        end,
        Create = function(self,Type)
            if self:IsValidPath() then return end
            if not self.IsNew then return end
            Type = Type:lower()
            if Type == "file" then
                writefile(self.Path)
            elseif Type == "folder" then
                makefolder(self.Path)
            end
        end,
        Delete = function(self)
            if not self:IsValidPath() then return end
            local IsFolder,IsFile = self:IsFolder(),self:IsFile()
            if IsFolder then
                delfolder(self.Path)
            elseif IsFile then
                delfile(self.Path)
            end
        end,
        GetFiles = function(self)
            if not self:IsValidPath() then return end
            if not self:IsFolder() then return end
            local RawFiles = listfiles(self.Path)
            local Files = {}
            for k,v in pairs(RawFiles) do
                Files[k] = FileSystem.new(v)
            end
            return Files
        end,
    }
}

function FileSystem:GetFileName(Path)
    local Start,End = Path:find("%\\")
    while Start do
        Path  = Path:sub(End+1)
        Start,End = Path:find("%\\")
    end
    Start,End = Path:find("%.")
    if Start then
        Path = Path:sub(1,Start-1)
    end
    return Path
end

function FileSystem:GetFileType(Path)
    local Start,End = Path:find("%\\")
    while Start do
        Path  = Path:sub(End+1)
        Start,End = Path:find("%\\")
    end
    Start,End = Path:find("%.")
    if Start then
        Path = Path:sub(End+1)
    else
        Path = "None"
    end
    return Path
end

function FileSystem.new(Path)
    for k,v in pairs(FileSystem.Cache) do
        if v.Path == Path then
            return v
        end
    end
    local Proxy = {
        Name=FileSystem:GetFileName(Path),
        Type=FileSystem:GetFileType(Path),
        Path=Path,
        IsNew=false,
    }
    for k,v in pairs(FileSystem.FileMethods) do
        Proxy[k] = v
    end
    if not isfile(Path) and not isfolder(Path) then
        Proxy.IsNew = true
    end
    local NewFile = setmetatable({},{
        __index=Proxy,
        __newindex=function(self,Name,Value)
            return error(("Cannot set property %q in File!"):format(v))
        end,
        __eq=function(self,Value)
            return rawequal(self,Value) or rawequal(Proxy,Value)
        end,
        __tostring=function(self)
            return self.Path
        end,
        __metatable="Locked",
    })
    table.insert(FileSystem.Cache,NewFile)
    return NewFile
end

local ChatSettings = FileSystem.new("ChatSystemSettings.json")
local ChatScripts = FileSystem.new("ChatSystemScripts")
ChatSettings:Create("File")
ChatScripts:Create("Folder")
