from atsconan import ATSConan

class ATSConan(ATSConan):
    name = "ats-http"
    version = "0.2"
    requires = [
        "ats-threadpool/0.1@randy.valis/testing",
        "ats-epoll/0.2.1@randy.valis/testing",
        "ats-libz/0.1@randy.valis/testing",
        "hashtable-vt/0.2@randy.valis/testing",
        "ats-pthread-extensions/0.1@randy.valis/testing",
        "ats-shared-vt/0.1@randy.valis/testing"
    ]

    def package_info(self):
        super().package_info()
        self.cpp_info.libs = ["ats-http"]
        self.cpp_info.includedirs = ["src"]
