package("flutils")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/Pixfri/FLUtils")
    set_description("Header-only utilities for FlashlightEngine.")
    set_license("MIT")

    add_urls("https://github.com/FlashlightEngine/FLUtils.git")

    add_versions("1.1.0", "c597c52c76efbb8c7e3ae1d4ace3d6e18f51b989")
    add_versions("1.0.0", "c33f608545d5528a8e288090431051066ed1756a")

    set_policy("package.strict_compatibility", true)

    on_install(function (package)
        import("package.tools.xmake").install(package)
    end)
