package("flashlightengine")
    set_homepage("https://github.com/FlashlightEngine/FlashlightEngine")
    set_description("A Windows and Linux compatible engine made for real-time 3D rendering")
    set_license("MIT")
    set_policy("package.librarydeps.strict_compatibility", true)

    add_urls("https://github.com/FlashlightEngine/FlashlightEngine.git")

    add_versions("2024.08.21", "3203f75efd17c79ae904a4e75897c88176440794")

    add_deps("flutils")
    add_deps("volk 1.3.290+0", "vk-bootstrap v1.3.290", "vulkan-memory-allocator v3.1.0", 
             "vulkan-utility-libraries v1.3.290", "glfw 3.4", "glm 1.0.1", "spdlog v1.9.0", "stb 2024.06.01")
    add_deps("imgui v1.91.0")

    add_configs("shared", {description = "Build the engine as a shared library.", default true, type = "boolean"})

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