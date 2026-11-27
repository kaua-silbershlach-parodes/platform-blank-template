fn main() {
    tauri_build::build();

    let target = std::env::var("TARGET").unwrap_or_default();
    let host = std::env::var("HOST").unwrap_or_default();

    // unrar_sys selects its Windows version helper with a host cfg. When this
    // app is cross-compiled to Windows from a non-Windows host, that helper is
    // omitted even though the target needs it. Compile the local shim only for
    // that cross-compilation case; native Windows builds keep using unrar's
    // own helper and must not see duplicate symbols.
    if target.contains("windows") && !host.contains("windows") {
        println!("cargo:rustc-link-lib=powrprof");
        println!("cargo:rustc-link-lib=shell32");
        println!("cargo:rustc-link-lib=shlwapi");

        cc::Build::new()
            .cpp(true)
            .file("native/unrar_windows_shim.cpp")
            .compile("unrar_windows_shim");
    }
}
