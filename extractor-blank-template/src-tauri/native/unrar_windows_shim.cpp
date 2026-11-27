// Cross-compilation shim for the two Windows version helpers referenced by
// UnRAR. unrar_sys omits its own isnt.cpp when the build host is not Windows,
// so this file provides the same C++ symbols for Windows targets built from
// another host. Native Windows builds do not compile this file.

#include <windows.h>

namespace {

struct RtlOsVersionInfoW {
    ULONG dwOSVersionInfoSize;
    ULONG dwMajorVersion;
    ULONG dwMinorVersion;
    ULONG dwBuildNumber;
    ULONG dwPlatformId;
    WCHAR szCSDVersion[128];
};

using RtlGetVersionFn = LONG(WINAPI *)(RtlOsVersionInfoW *);

bool ReadVersion(RtlOsVersionInfoW &info) {
    info = {};
    info.dwOSVersionInfoSize = sizeof(info);

    HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
    if (ntdll == nullptr) {
        return false;
    }

    auto rtl_get_version = reinterpret_cast<RtlGetVersionFn>(
        GetProcAddress(ntdll, "RtlGetVersion"));
    if (rtl_get_version == nullptr) {
        return false;
    }

    return rtl_get_version(&info) == 0;
}

} // namespace

DWORD WinNT() {
    RtlOsVersionInfoW info;
    if (!ReadVersion(info) || info.dwPlatformId != VER_PLATFORM_WIN32_NT) {
        return 0;
    }

    return info.dwMajorVersion * 0x100 + info.dwMinorVersion;
}

bool IsWindows11OrGreater() {
    RtlOsVersionInfoW info;
    if (!ReadVersion(info)) {
        return false;
    }

    return info.dwMajorVersion > 10 ||
           (info.dwMajorVersion == 10 && info.dwBuildNumber >= 22000);
}
