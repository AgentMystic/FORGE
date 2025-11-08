--alright.. this shall be the shift service.. it will seperate and store projects and shift between them when requested.. 
--by mys.tic
local ServerStorage = game:GetService("ServerStorage")


--A dictionary containing all projects by their unique ID. Mapping =   ID -> Module ID 
--Projects may have different names from the Project module, intentionally to allow multiple version to be created, but only one being assigned.
--As well as for same-purpose projects, two FP cameras with different functioning will not have duplicate Project entries as we never want both active at the same time.
--We create a module for each project with a built-in method to load the project.
--Projects can be scripts, or only builds, or maybe just user interface. 

local hasLoaded = false

local ShiftService = {}

ShiftService.Projects = {

    ["Tile Generation"] = "TileGenerationV0.2" ;
    ["FP Camera"] = "FPCameraV0.1"

}

ShiftService.Loaded = {"Tile Generation"}



--Loads a project through a project module's LoadProject() method. 
function ShiftService:LoadProject(projectName)

    local fileName = ShiftService.Projects[projectName]
    assert(fileName, "Project '"..projectName.."' does not exist in ShiftService!")
  
    local project = ServerStorage.ProjectStorage:FindFirstChild(fileName)
    assert(project, "Project '"..projectName.."' does not exist in ProjectStorage! lf;"..fileName)

    table.insert(ShiftService.Loaded,projectName)
    require(project).LoadProject()

end

--Unloads a project through a project module's UnloadProject() method. 
function ShiftService:UnloadProject(projectName)

    local fileName = ShiftService.Projects[projectName]
    assert(ShiftService.Loaded[projectName],"Project '"..projectName.."' can not be recognized as a loaded project!")

    local project = ServerStorage.ProjectStorage:FindFirstChild(fileName)
    assert(project, "Project '"..projectName.."' does not exist in ProjectStorage! lf;"..fileName)

    table.remove(ShiftService.Loaded,projectName)
    require(project).UnloadProject()

end


function _initLoad()

    for _,name in ShiftService.Loaded do

        local fileName = ShiftService.Projects[name]
        assert(fileName,"Loaded Project '"..name.."' does not exist in ShiftService!" )

        local project = ServerStorage.ProjectStorage:FindFirstChild(fileName)
        assert(project, "Project '"..name.."' does not exist in ProjectStorage! lf;"..fileName)

        require(project).LoadProject()
        
    end

end

function __init__()
    if not hasLoaded then
        hasLoaded = true
        _initLoad()
    end
    return ShiftService
    
end




return __init__
