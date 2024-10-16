package("flashlightengine")
    set_homepage("https://github.com/FlashlightEngine/FlashlightEngine")
    set_description("A Windows and Linux compatible engine made for real-time 3D rendering")
    set_license("MIT")
    set_policy("package.librarydeps.strict_compatibility", true)

    add_urls("https://github.com/FlashlightEngine/FlashlightEngine.git")

    add_versions("2024.09.14", "66e587946f3f56be5f21893478df5c54b1118923")

    add_deps("flutils", 
             "spdlog v1.9.0",
	         "vulkan-memory-allocator", 
	         "volk",
             "stb",
             "glfw")

    add_configs("shared", {description = "Build the engine as a shared library.", default = true, type = "boolean"})
    add_configs("symbols", {description = "Enable debug symbols in release.", default = false, type = "boolean"})
    add_configs("optick", {description = "Enable the optick debugger.", default = false, type = "boolean"})

    on_install("windows", "mingw", "linux", function (package)
        local configs = {}
        configs.override_runtime = false

        if package:config("shared") then
            configs.static = false
        end

        if package:config("optick") then
            configs.optick = true
        end
        
        if package:is_debug() then
            configs.mode = "debug"
        elseif package:config("symbols") then
            configs.mode = "releasedbg"
        else
            configs.mode = "release"
        end

        import("package.tools.xmake").install(package, configs)
    end)