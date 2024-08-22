package("flashlightengine")
    set_homepage("https://github.com/FlashlightEngine/FlashlightEngine")
    set_description("A Windows and Linux compatible engine made for real-time 3D rendering")
    set_license("MIT")
    set_policy("package.librarydeps.strict_compatibility", true)

    add_urls("https://github.com/FlashlightEngine/FlashlightEngine.git")

    add_versions("2024.08.22", "ef851f98e6904b5d787682d28c0350d0c9bc7df3")

    add_deps("flutils")

    add_configs("shared", {description = "Build the engine as a shared library.", default = true, type = "boolean"})
    add_configs("embed_rendererbackends", {description = "Update renderer backends into FLRenderer.", default = false, type = "boolean"})
    add_configs("symbols", {description = "Enable debug symbols in release.", default = false, type = "boolean"})
    add_configs("entt", {description = "Includes the EnTT package to use the ECS.", default = true, type = "boolean"})

    local components = {
        core = {
            name = "Core",
            custom = function (package)
                if package:is_plat("linux") then
                    package:add("deps", "libuuid", {private = true})
                end
            end,
            custom_comp = function (package, component)
                if package:is_plat("windows", "mingw") then
                    component:add("syslinks", "ole32")
                elseif package:is_plat("linux") then
                    component:add("syslinks", "pthread", "dl")
                end
            end,
            privatepkgs = {"spdlog", "frozen", "stb", "utfcpp"}
        },
        graphics = {
            option = "graphics",
            name = "Graphics",
            deps = {"renderer"}
        },
        platform = {
            option = "platform",
            name = "Platform",
            deps = {"core"},
            custom = function (package)
                if package:is_plat("linux") then
                    package:add("deps", "libxext", "wayland", {private = true, configs = {asan = false}})
                end
            end,
            privatepkgs = {"libsdl >=2.26.0"}
        },
        renderer = {
            option = "renderer",
            name = "Renderer",
            deps = {"platform"},
            custom_comp = function (package, component)
                if package:is_plat("windows", "mingw") then
                    package:add("syslinks", "gdi32", "user32", "advapi32")
                end
            end,
            privatepkgs = {"vulkan-headers", "vulkan-memory-allocator"}
        }
    }

    local function build_deps(component, deplist, inner)
        if component.deps then
            for _, depname in ipairs(component.deps) do
                table.insert(deplist, depname)
                build_deps(components[depname], deplist, true)
            end
        end
    end

    for name, compdata in table.orderpairs(components) do
        local deplist = {}
        build_deps(compdata, deplist)
        compdata.deplist = table.unique(deplist)

        if compdata.option then
            local depstring = #deplist > 0 and " (depends on " .. table.concat(compdata.deplist, ", ") .. ")" or ""
            add_configs(compdata.option, {description = "Use the" .. compdata.name .. " module " .. depstring, default = true, type = "boolean"})
        end

        on_component(name, function (package, component)
            local prefix = "FL"
            local suffix = package:config("shared") and "" or "-s"
            if package:debug() then
                suffix = suffix .. "-d"
            end

            component:add("deps", table.unwrap(compdata.deps))
            component:add("links", prefix .. compdata.name .. suffix)
            if compdata.custom_comp then
                compdata.custom_comp(package, component)
            end
        end)
    end

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

        local binFolder = string.format("%s_%s_%s", package:plat(), package:arch(), mode)
        local fetchInfo = {
            version = versions[1] or os.date("%Y.%m.%d"),
            sysincludedirs = { path.join(flengine, "Include") },
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
        for name, compdata in table.orderpairs(components) do
            if not compdata.option or package:config(compdata.option) then
                package:add("components", name)
                if compdata.privatepkgs then
                    package:add("deps", table.unpack(compdata.privatepkgs), {private = true})
                end
            end
        end

        if not package:config("shared") then
            package:add("defines", "FL_STATIC")
        end

        if package:config("entt") then
            package:add("defines", "FL_ENTT")
            package:add("deps", "entt 3.13.2")
        end

        if package:is_debug() then
            package:add("defines", "FL_DEBUG")
        end
    end)

    on_install("windows", "mingw", "linux", function (package)
        local configs = {}
        configs.override_runtime = false

        for name, compdata in table.orderpairs(components) do
            if compdata.option then
                if package:config(compdata.option) then
                    for _, dep in ipairs(compdata.deplist) do
                        local depcomp = components[dep]
                        if depcomp.option and not package:config(depcomp.option) then
                            raise("module \"" .. name "\" depends on disabled module \"" .. dep .. "\"")
                        end
                    end

                    configs[compdata.option] = true
                else
                    configs[compdata.option] = false
                end
            end
        end

        configs.embed_rendererbackends = package:config("embed_rendererbackends")

        if package:is_debug() then
            configs.mode = "debug"
        elseif package:config("symbols") then
            configs.mode = "releasedbg"
        else
            configs.mode = "release"
        end
        import("package.tools.xmake").install(package, configs)
    end)