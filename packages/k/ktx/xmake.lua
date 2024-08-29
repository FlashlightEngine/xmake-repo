package("ktx")
    set_homepage("https://github.com/KhronosGroup/KTX-Software/")
    set_description("The Khronos KTX library and tools.")
    
    add_urls("https://github.com/KhronosGroup/KTX-Software/archive/refs/tags/$(version).tar.gz", 
             "https://github.com/KhronosGroup/KTX-Software.git")

    add_versions("v4.3.2", "74a114f465442832152e955a2094274b446c7b2427c77b1964c85c173a52ea1f")

    add_deps("cmake")

    add_configs("ktx1", {description = "Enable KTX 1 support.", default = true, type = "boolean"})
    add_configs("ktx2", {description = "Enable KTX 2 support.", default = true, type = "boolean"})
    add_configs("vk-upload", {description = "Enable Vulkan texture upload.", default = true, type = "boolean"})
    add_configs("gl-upload", {description = "Enable OpenGL texture upload.", default = true, type = "boolean"})

    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DKTX_FEATURE_KTX1=" .. (package:config("ktx1") and "ON" or "OFF"))
        table.insert(configs, "-DKTX_FEATURE_KTX2=" .. (package:config("ktx2") and "ON" or "OFF"))
        table.insert(configs, "-DKTX_FEATURE_VK_UPLOAD=" .. (package:config("vk-upload") and "ON" or "OFF"))
        table.insert(configs, "-DKTX_FEATURE_GL_UPLOAD=" .. (package:config("gl-upload") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)