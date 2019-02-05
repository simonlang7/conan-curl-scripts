from conans import ConanFile, tools

class CurlConan(ConanFile):
    name = "curl"
    settings = "os", "compiler", "build_type", "arch"
#    options = {"shared": [False],
#                "android_ndk": "ANY", "android_stl_type":["c++_static", "c++_shared"]}
#    default_options = "shared=False", "android_ndk=None"
    description = "cURL is a free client-side URL transfer library."
    url = "https://github.com/simonlang7/conan-curl-scripts"
    license = "cURL license"

    def package(self):
        self.copy("*", dst="include", src='conan/include')
        self.copy("*.lib", dst="lib", src='conan/lib', keep_path=False)
        self.copy("*.dll", dst="bin", src='conan/lib', keep_path=False)
        self.copy("*.so", dst="lib", src='conan/lib', keep_path=False)
        self.copy("*.dylib", dst="lib", src='conan/lib', keep_path=False)
        self.copy("*.a", dst="lib", src='conan/lib', keep_path=False)
        
    def package_info(self):
        self.cpp_info.libs = tools.collect_libs(self)
        self.cpp_info.includedirs = ['include']

#    def config_options(self):
#        # remove android specific option for all other platforms
#        if self.settings.os != "Android":
#            del self.options.android_ndk
#            del self.options.android_stl_type
