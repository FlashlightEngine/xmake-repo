package("flutils")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/Pixfri/FLUtils")
    set_description("Header-only utilities for FlashlightEngine.")
    set_license("MIT")

    add_urls("https://github.com/FlashlightEngine/FLUtils.git")

    add_versions("2024.08.22", "1eb733253e378636ac180b39dce8ea6b41715086")

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