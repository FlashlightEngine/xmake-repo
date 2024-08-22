package("flutils")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/Pixfri/FLUtils")
    set_description("Header-only utilities for FlashlightEngine.")
    set_license("MIT")

    add_urls("https://github.com/FlashlightEngine/FLUtils.git")

    add_versions("2024.08.22", "c8c76dfd5765f92e8d464106d0f06ffc6da42536")

    set_policy("package.strict_compatibility", true)

    on_install(function (package)
        import("package.tools.xmake").install(package)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            void test() {
                Flashlight::Utils::u8 a = 1;
                Flashlight::Utils::u32 b = Flashlight::Utils::ToU32<Flashlight::Utils::u8>(a);
            }
        ]]}, {configs = {language = "c++20"}, includes = "FLUtils/Helpers.hpp"}))
    end)