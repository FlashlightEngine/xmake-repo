package("moltenvk")
    set_homepage("https://github.com/KhronosGroup/MoltenVK")
    set_description("MoltenVK is a Vulkan Portability implementation.")
    set_license("Apache-2.0")

    add_urls("https://github.com/KhronosGroup/MoltenVK/archive/refs/tags/$(version).tar.gz",
             "https://github.com/KhronosGroup/MoltenVK.git")

    add_versions("v1.2.11", "bfa115e283831e52d70ee5e13adf4d152de8f0045996cf2a33f0ac541be238b1")

    if is_plat("macosx") then
        add_extsources("brew::molten-vk")
    end

    add_links("MoltenVKShaderConverter", "MoltenVK")

    if is_plat("macosx", "iphoneos") then
        add_frameworks("Metal", "Foundation", "QuartzCore", "CoreGraphics", "IOSurface")
        if is_plat("macosx") then
            add_frameworks("IOKit", "AppKit")
        else
            add_frameworks("UIKit")
        end
    end

    on_fetch("macosx", function (package, opt)
        if opt.system then
            import("lib.detect.find_path")
            local frameworkdir = find_path("vulkan.framework", "~/VulkanSDK/*/macOS/Frameworks")
            if frameworkdir then
                return {frameworkdirs = frameworkdir, frameworks = "vulkan", rpathdirs = frameworkdir}
            end
        end
    end)

    on_install("macosx", "iphoneos", function (package)
        local plat = package:is_plat("iphoneos") and "iOS" or "macOS"
        local configs = {"--" .. plat:lower()}
        if package:debug() then
            table.insert(configs, "--debug")
        end
        os.vrunv("./fetchDependencies", configs)
        local conf = package:debug() and "Debug" or "Release"
        os.vrun("xcodebuild build -quiet -project MoltenVKPackaging.xcodeproj -scheme \"MoltenVK Package (" ..plat .. " only)\" -configuration \"" .. conf)
        os.mv("Package/" .. conf .. "/MoltenVK/include", package:installdir())
        os.mv("Package/" .. conf .. "/MoltenVK/dylib/" ..plat .. "/*", package:installdir("lib"))
        os.mv("Package/" .. conf .. "/MoltenVK/MoltenVK.xcframework/" .. plat:lower() .. "-*/*.a", package:installdir("lib"))
        if package:config("shared") then
            os.mv("Package/" .. conf .. "/MoltenVK/dynamic/dylib/" .. plat .. "/*.dylib", package:installdir("lib"))
        else
            os.mv("Package/" .. conf .. "/MoltenVK/static/MoltenVK.xcframework/" .. plat:lower() .. "-*/*.a", package:installdir("lib"))
        end
        os.mv("Package/" .. conf .. "/MoltenVKShaderConverter/Tools/*", package:installdir("bin"))
        os.mv("Package/" .. conf .. "/MoltenVKShaderConverter/MoltenVKShaderConverter.xcframework/" .. plat:lower() .. "-*/*.a", package:installdir("lib"))
        os.mv("Package/" .. conf .. "/MoltenVKShaderConverter/include/*.h", package:installdir("include"))
        package:addenv("PATH", "bin")
    end)

    on_test(function (package)
        assert(package:has_cfuncs("vkGetDeviceProcAddr", {includes = "vulkan/vulkan_core.h"}))
    end)