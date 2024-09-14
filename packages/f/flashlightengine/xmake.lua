package("flashlightengine")
    set_homepage("https://github.com/FlashlightEngine/FlashlightEngine")
    set_description("A Windows and Linux compatible engine made for real-time 3D rendering")
    set_license("MIT")
    set_policy("package.librarydeps.strict_compatibility", true)

    add_urls("https://github.com/FlashlightEngine/FlashlightEngine.git")

    add_versions("2024.09.14", "b53563767763f574c03783dc09e046d8108a7572")

    add_deps("flutils")

    add_configs("shared", {description = "Build the engine as a shared library.", default = true, type = "boolean"})
    add_configs("symbols", {description = "Enable debug symbols in release.", default = false, type = "boolean"})
    add_configs("optick", {description = "Enable the optick debugger.", default = false, type = "boolean"})

    local sanitizers = {
        asan = "address",
        lsan = "leak",
        tsan = "thread"
    }
    
    -- Asan
    add_configs("asan", {description = "Enable address sanitizer", default = false, type = "boolean"})

    if has_config("asan") then
        add_defines("FL_WITH_ASAN")
        set_policy("build.sanitizer.asan", true)
    end
    
    -- Lsan
    add_configs("lsan", {description = "Enable leak sanitizer", default = false, type = "boolean"})

    if has_config("asan") then
        add_defines("FL_WITH_LSAN")
        set_policy("build.sanitizer.lsan", true)
    end
    
    -- Tsan
    add_configs("tsan", {description = "Enable thread sanitizer", default = false, type = "boolean"})

    if has_config("asan") then
        add_defines("FL_WITH_TSAN")
        set_policy("build.sanitizer.tsan", true)
    end

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

        if package:config("asan") then
            configs.asan = true
        end

        if package:config("tsan") then
            configs.tsan = true
        end

        if package:config("lsan") then
            configs.lsan = true
        end

        import("package.tools.xmake").install(package, configs)
    end)