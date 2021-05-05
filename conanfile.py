from conans import ConanFile, AutoToolsBuildEnvironment
from conans import tools
import os

class ATSConan(ConanFile):
    name = "ats-http"
    version = "0.1"
    settings = "os", "compiler", "build_type", "arch"
    generators = "make"
    exports_sources = "*"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": False}
    requires = "ats-threadpool/0.1@randy.valis/testing", "ats-epoll/0.1@randy.valis/testing", "ats-libz/0.1@randy.valis/testing", "hashtable-vt/0.1@randy.valis/testing", "ats-pthread-extensions/0.1@randy.valis/testing", "ats-shared-vt/0.1@randy.valis/testing"

    def build(self):
        atools = AutoToolsBuildEnvironment(self)
        atools.libs.append("pthread")
        var = atools.vars
        var['ATSFLAGS'] = self._format_ats()
        atools.make(vars=var)

    def package(self):
        self.copy("*.hats", dst="", src="")
        self.copy("*.dats", dst="", src="")
        self.copy("*.sats", dst="", src="")
        self.copy("*.cats", dst="", src="")
        if self.options.shared:
            self.copy("*.so", dst="lib", keep_path=False)
        else:
            self.copy("*.a", dst="lib", keep_path=False)

    def package_info(self):
        self.cpp_info.libs = ["ats-http"]
        self.cpp_info.cxxflags = "-IATS {}".format(self.build_folder)
        self.cpp_info.includedirs = ["src"]
        # self.cpp_info.exelinkflags = ["libats-shared-vt.a"]

    def _format_ats(self):
        return " ".join([ f"-IATS {path}src" for path in self.deps_cpp_info.build_paths ])
