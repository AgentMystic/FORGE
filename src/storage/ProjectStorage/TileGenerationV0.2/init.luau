local Project = {
    ["TileGeneration"] = game.ServerScriptService
}


local Methods = {}

--The assumption is made that all files in Project are present under this modulescript, and the destination is real. 
Methods.LoadProject = function()

    for name, destination in pairs(Project) do

        local file = script:FindFirstChild(name)
        assert(file,"Project could not be loaded, file  '"..name.."' does not exist.")
        
        local type = typeof(file)
        if type == "Script" or type =="LocalScript" then
            file.Enabled = true
        end

        file.Parent = destination

    end

end

--Moves all files back under the module script. If any no longer exist a warning will be thrown, as loading the module again will raise an error. 
--Custom unloading functionality can be added, in case the project will contain more than the original files. 
Methods.UnloadProject = function()

    for name, destination in pairs(Project) do

        local file = destination:FindFirstChild(name)
        if not file then
            warn("Project file '"..name.."' could not be found, reloading project will cause an error.")
            continue
        end

        local type = typeof(file)
        if type == "Script" or type =="LocalScript" then
            file.Enabled = false
        end

        file.Parent = script



    end
end

Methods.AddFile = function(name,destination)

    Project[name] = destination

end

Methods.RemoveFile = function(param: string | Object) 
    local obj = param
    if typeof(param) == "string" then
        obj = script:FindFirstChild(param)
        assert(obj,"Could not find and remove file matching name: '"..param.."'")
    end
    
    Project[obj.Name] = nil
    obj:Destroy()

end

return Methods