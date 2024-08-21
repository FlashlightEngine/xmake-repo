package("flashlightengine")
    set_homepage("https://github.com/FlashlightEngine/FlashlightEngine")
    set_description("A Windows and Linux compatible engine made for real-time 3D rendering")
    set_license("MIT")
    set_policy("package.librarydeps.strict_compatibility", true)

    add_urls("https://github.com/FlashlightEngine/FlashlightEngine.git")

    add_versions("2024.08.21", "25d2917efb2d493e86265a991977d4fad853a36d")

    add_deps("flutils")
    add_deps("volk 1.3.290+0", "vk-bootstrap v1.3.290", "vulkan-memory-allocator v3.1.0", 
             "vulkan-utility-libraries v1.3.290", "glfw 3.4", "glm 1.0.1", "spdlog v1.9.0", "stb 2024.06.01")
    add_deps("imgui v1.91.0")

    add_configs("shared", {description = "Build the engine as a shared library.", default = true, type = "boolean"})

    on_fetch(function (package, opt)
        if not opt.system then
            return
        end

        local flengine = os.getenv("FL_ENGINE_PATH")
        if not flengine or not os.isdir(flengine) then
            return
        end

        local mode
        if package:is_debug() then
            mode = "debug"
        elseif package:config("symbols") then
            mode = "releasedbg"
        else
            mode = "release"
        end

        local versions = package:versions()
        table.sort(versions, function (a, b) return a > b end)

        local binFolder = string.format("%s_%s_%s", mode, package:plat(), package:arch())
        local fetchInfo = {
            version = versions[1] or os.date("%Y.%m.%d"),
            sysincludedirs = { path.join(flengine, "include") },
            linkdirs = path.join(flengine, "bin", binFolder),
            components = {}
        }
        local baseComponent = {}
        fetchInfo.components.__base = baseComponent

        if package:is_debug() then
            fetchInfo.defines = table.join(fetchInfo.defines or {}, "FL_DEBUG")
        end
        for name, component in pairs(package:components()) do
            fetchInfo.components[name] = {
                links = component:get("links"),
                syslinks = component:get("syslinks")
            }
        end
        for _, componentname in pairs(package:components_orderlist()) do
            local component = fetchInfo.components[componentname]
            for k,v in pairs(component) do
                fetchInfo[k] = table.join2(fetchInfo[k] or {}, v)
            end
        end

        baseComponent.defines = fetchInfo.defines
        baseComponent.linkdirs = fetchInfo.linkdirs
        baseComponent.sysincludedirs = fetchInfo.sysincludedirs

        package:set("policy", "package.librarydeps.strict_compatibility", false)

        return fetchInfo
    end)

    on_load(function (package)
        if not package:config("shared") then
            package:add("defines", "FL_STATIC")
        end
        
        if package:is_debug() then
            package:add("defines", "FL_DEBUG")
        end
    end)

    on_install("windows", "linux", function(package)
        local configs = {}

        if package:is_debug() then
            configs.mode = "debug"
        else
            configs.mode = "release"
        end

        import("package.tools.xmake").install(package, configs)
    end)