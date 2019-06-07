module ddstar;

/// Application version, following MAJOR.MINOR.FIX[-tag]
enum APP_VERSION = "0.0.0";
/// Server API version
enum API_VERSION = "0.0.0";

debug
	/// For printing purposes
	enum BUILD_TYPE = "debug";	
else
	/// For printing purposes
	enum BUILD_TYPE = "release";

version (D_SIMD) {
	enum FEATURE_SIMD = " simd"; /// 
	pragma(msg, "* compiler: SIMD enabled");
} else 
	enum FEATURE_SIMD = ""; /// 

version (CRuntime_Bionic)
	enum C_RUNTIME = "Bionic";	/// Printable C runtime string
else
version (CRuntime_DigitalMars)
	enum C_RUNTIME = "DigitalMars";	/// Printable C runtime string
else
version (CRuntime_Glibc)
	enum C_RUNTIME = "Glibc";	/// Printable C runtime string
else
version (CRuntime_Microsoft)
	enum C_RUNTIME = "Microsoft";	/// Printable C runtime string
else
version (CRuntime_Musl)
	enum C_RUNTIME = "musl";	/// Printable C runtime string
else
version (CRuntime_UClibc)
	enum C_RUNTIME = "uClibc";	/// Printable C runtime string
else
	enum C_RUNTIME = "UNKNOWN";	/// Printable C runtime string

pragma(msg, "* compiler: ", C_RUNTIME, " runtime");

version (X86) {
	enum PLATFORM = "x86";	/// Platform string
} else
version (X86_64) {
	enum PLATFORM = "amd64";	/// Platform string
} else
version (ARM) {
	version (LittleEndian) enum PLATFORM = "aarch32le";	/// Platform string
	version (BigEndian) enum PLATFORM = "aarch32be";	/// Platform string
} else
version (AArch64) {
	version (LittleEndian) enum PLATFORM = "aarch64le";	/// Platform string
	version (BigEndian) enum PLATFORM = "aarch64be";	/// Platform string
} else { // Unknown/untested platform
	enum PLATFORM = "unknown";	/// Platform string
}