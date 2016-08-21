using Uno;
using Uno.UX;
using Uno.Text;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;

[ForeignInclude(Language.Java, "android.app.Activity",
                               "android.provider.Settings",
                               "android.telephony.TelephonyManager",
                               "android.content.*",
                               "android.net.wifi.*",
                               "java.security.*",
                               "java.util.regex.*",
                               "java.util.*",
                               "java.net.*",
                               "java.nio.*",
                               "java.io.*")]

[ForeignInclude(Language.ObjC, "sys/types.h", "sys/sysctl.h")]

[UXGlobalModule]
public sealed class Device : NativeModule {
    static readonly Device _instance;

    static string cachedVendorName;
    static string cachedModelName;
    static string cachedSystemName;
    static string cachedSystemVersion;
    static string cachedSDKVersion;
    static double cachedNumProcessorCores = 0f;

    static string cachedUUID;

    public Device() : base() {
        if (_instance != null) return;
        Resource.SetGlobalKey(_instance = this, "Device");

        AddMember(new NativeProperty< string, object >("vendor", Vendor));
        AddMember(new NativeProperty< string, object >("model", Model));
        AddMember(new NativeProperty< string, object >("system", System));
        AddMember(new NativeProperty< string, object >("systemVersion", SystemVersion));
        AddMember(new NativeProperty< string, object >("SDKVersion", SDKVersion));
        AddMember(new NativeProperty< double, object >("cores", NumProcessorCores));
        AddMember(new NativeProperty< double, object >("displayScale", PixelsPerPoint));
        AddMember(new NativeProperty< bool,   object >("isRetina", IsRetina));

        AddMember(new NativeProperty< string, object >("UUID", UUID));
        // [language]-[region]-[variants] (e.g. zh-EN-Hans, en-US, etc.)
        AddMember(new NativeProperty< string, object >("locale", GetCurrentLocale));
    }


    public static string UUID() {
        if (cachedUUID != null) {
            return cachedUUID;
        }
        cachedUUID = GetUUID();
        return cachedUUID;
    }

    public static string Vendor() {
        if (cachedVendorName != null) {
            return cachedVendorName;
        }
        cachedVendorName = GetVendor();
        return cachedVendorName;
    }

    public static string Model() {
        if (cachedModelName != null) {
            return cachedModelName;
        }
        cachedModelName = GetModel();
        return cachedModelName;
    }

    public static string System() {
        if (cachedSystemName != null) {
            return cachedSystemName;
        }
        cachedSystemName = GetSystem();
        return cachedSystemName;
    }

    public static string SystemVersion() {
        if (cachedSystemVersion != null) {
            return cachedSystemVersion;
        }
        cachedSystemVersion = GetSystemVersion();
        return cachedSystemVersion;
    }

    public static string SDKVersion() {
        if (cachedSDKVersion != null) {
            return cachedSDKVersion;
        }
        cachedSDKVersion = GetSDKVersion();
        return cachedSDKVersion;
    }

    public static double NumProcessorCores() {
        if (cachedNumProcessorCores != 0f) {
            return cachedNumProcessorCores;
        }

        cachedNumProcessorCores = (double)GetNumProcessorCores();
        return cachedNumProcessorCores;
    }

    public static bool IsRetina() {
        return Device.PixelsPerPoint() > 1f;
    }

    public static double PixelsPerPoint() {
        return App.Current.RootViewport.PixelsPerPoint;
    }


    // UUID platform specific implementations
    [Foreign(Language.Java)]
    [Require("AndroidManifest.RootElement", "<uses-permission android:name=\"android.permission.READ_PHONE_STATE\"/>")]
    [Require("AndroidManifest.RootElement", "<uses-permission android:name=\"android.permission.ACCESS_WIFI_STATE\"/>")]
    [Require("AndroidManifest.RootElement", "<uses-permission android:name=\"android.permission.CHANGE_WIFI_STATE\"/>")]
    private static extern(Android) string GetUUID()
    @{
        final android.app.Activity context = com.fuse.Activity.getRootActivity();
        final TelephonyManager tm = (TelephonyManager)context.getSystemService(Context.TELEPHONY_SERVICE);
        final String deviceId     = "" + tm.getDeviceId();
        final String serialNum    = "" + tm.getSimSerialNumber();
        final String androidId    = "" + android.provider.Settings.Secure.getString(
                                            context.getContentResolver(),
                                            android.provider.Settings.Secure.ANDROID_ID
                                         );

        int macAdressId;

        try {
            // try to get MAC-address via NetworkInterface
            final InetAddress ip = InetAddress.getLocalHost();
            final NetworkInterface network = NetworkInterface.getByInetAddress(ip);
            macAdressId = network.getHardwareAddress().hashCode();
        } catch (Throwable e) {
            // else get MAC-address via WifiManager
            final WifiManager wifiManager = (WifiManager)context.getSystemService(Context.WIFI_SERVICE);
            final boolean     wifiEnabled = wifiManager.isWifiEnabled();

            if (!wifiEnabled)
                wifiManager.setWifiEnabled(true);

            macAdressId = wifiManager.getConnectionInfo().getMacAddress().hashCode();

            if (!wifiEnabled)
                wifiManager.setWifiEnabled(false);
        }

        long first  = ((long)macAdressId << 32)         + androidId.hashCode();
        long second = ((long)deviceId.hashCode() << 32) + serialNum.hashCode();

        byte[] bytes = ByteBuffer.allocate(2 * Long.SIZE / Byte.SIZE)
          			   .putLong(first)
          			   .putLong(second)
                       .array();

        byte[] hashedUUID = new byte[16];

        try {
            hashedUUID = MessageDigest.getInstance("MD5").digest(bytes);
        } catch (NoSuchAlgorithmException e) {}

        return UUID.nameUUIDFromBytes(hashedUUID).toString().toUpperCase();
    @}

    [Foreign(Language.ObjC)]
    private static extern(iOS) string GetUUID()
    @{
        return [NSUUID.UUID UUIDString]; // iOS >= 6.x
    @}

    // Preview version
    // UUID generate randomly every launch time
    private static extern(!(iOS || Android)) string GetUUID() {
        // According to RFC 4122 version 4
        Random rnd = new Random((int)(Time.FrameTime + 34525));
        byte[] bytes = new byte[16];
        const string chars = "abcdefghijklmnopqrstuwxyzABCDEFGHIJKLMNOPQRSTUWXYZ0123456789";
        int len = chars.Length;
        for (int i = 0; i < 16; ++i)
            bytes[i] = (byte)(chars[rnd.NextInt(len)]);

        bytes[6] = (bytes[6] & 0xF)  | 0x40;
        bytes[8] = (bytes[8] & 0x3F) | 0x80;

        StringBuilder result = new StringBuilder();
        for (int i = 0; i < 16; ++i)
            result.Append(String.Format("{0:X}", bytes[i]));

        return result.ToString().Insert(8,  "-").Insert(13, "-")
                                .Insert(18, "-").Insert(23, "-");
    }


    [Foreign(Language.Java)]
	public static extern(Android) string GetCurrentLocale()
	@{
		Locale loc = java.util.Locale.getDefault();

        final char separator = '-';
        String language = loc.getLanguage();
        String region   = loc.getCountry();
        String variant  = loc.getVariant();

        // special case for Norwegian Nynorsk since "NY" cannot be a variant as per BCP 47
        // this goes before the string matching since "NY" wont pass the variant checks
        if (language.equals("no") && region.equals("NO") && variant.equals("NY")) {
            language = "nn";
            region   = "NO";
            variant  = "";
        }

        if (language.isEmpty() || !language.matches("\\p{Alpha}{2,8}")) {
            language = "und"; // "und" for Undetermined
        } else if (language.equals("iw")) {
            language = "he";  // correct deprecated "Hebrew"
        } else if (language.equals("in")) {
            language = "id";  // correct deprecated "Indonesian"
        } else if (language.equals("ji")) {
            language = "yi";   // correct deprecated "Yiddish"
        }

        // ensure valid country code, if not well formed, it's omitted
        if (!region.matches("\\p{Alpha}{2}|\\p{Digit}{3}")) {
            region = "";
        }

         // variant subtags that begin with a letter must be at least 5 characters long
        if (!variant.matches("\\p{Alnum}{5,8}|\\p{Digit}\\p{Alnum}{3}")) {
            variant = "";
        }

        StringBuilder bcp47Tag = new StringBuilder(language);
        if (!region.isEmpty()) {
            bcp47Tag.append(separator).append(region);
        }

        if (!variant.isEmpty()) {
            bcp47Tag.append(separator).append(variant);
        }

        return bcp47Tag.toString();
	@}

	[Foreign(Language.ObjC)]
	private static extern(iOS) string GetCurrentLocale()
	@{
		NSString* language = NSLocale.preferredLanguages[0];

        if (language.length <= 2) {
            NSLocale* locale        = NSLocale.currentLocale;
            NSString* localeId      = locale.localeIdentifier;
            NSRange underscoreIndex = [localeId rangeOfString: @"_" options: NSBackwardsSearch];
            NSRange atSignIndex     = [localeId rangeOfString: @"@"];

            if (underscoreIndex.location != NSNotFound) {
                if (atSignIndex.length == 0)
                    language = [NSString stringWithFormat: @"%@%@", language, [localeId substringFromIndex: underscoreIndex.location]];
                else {
                    NSRange localeRange = NSMakeRange(underscoreIndex.location, atSignIndex.location - underscoreIndex.location);
                    language = [NSString stringWithFormat: @"%@%@", language, [localeId substringWithRange: localeRange]];
                }
            }
        }

        return [language stringByReplacingOccurrencesOfString: @"_" withString: @"-"];
	@}

	public static extern(!(iOS || Android)) string GetCurrentLocale() {
		return "en-EN";
    }


    // iOS's foreign implementations

    [Foreign(Language.ObjC)]
    private static extern(iOS) string GetVendor()
    @{
        return @"Apple";
    @}

    [Foreign(Language.ObjC)]
    private static extern(iOS) string GetModel()
    @{
        size_t hardwareModelSize;
        sysctlbyname("hw.machine", NULL, &hardwareModelSize, NULL, 0);
        char* hardwareModel = (char*)malloc(hardwareModelSize);

        sysctlbyname("hw.machine", hardwareModel, &hardwareModelSize, NULL, 0);
        NSString* model = [NSString stringWithUTF8String: hardwareModel];
        free(hardwareModel);

        return model;
    @}

    [Foreign(Language.ObjC)]
    private static extern(iOS) string GetSystem()
    @{
        return @"iOS";
    @}

    [Foreign(Language.ObjC)]
    private static extern(iOS) string GetSystemVersion()
    @{
        return UIDevice.currentDevice.systemVersion;
    @}

    [Foreign(Language.ObjC)]
    private static extern(iOS) string GetSDKVersion()
    @{
        return UIDevice.currentDevice.systemVersion;
    @}

    [Foreign(Language.ObjC)]
    private static extern(iOS) int GetNumProcessorCores()
    @{
        uint32_t ncpu = 0;
        size_t size = sizeof(uint32_t);
        if (sysctlbyname("hw.logicalcpu", &ncpu, &size, NULL, 0) != 0) {
            if (sysctlbyname("hw.ncpu", &ncpu, &size, NULL, 0) != 0) {
                ncpu = 1;
            }
        }

        return (int32_t)ncpu;
    @}

    // Android's foreign implementations

    [Foreign(Language.Java)]
    private static extern(Android) string GetVendor()
    @{
        return android.os.Build.MANUFACTURER;
    @}

    [Foreign(Language.Java)]
    private static extern(Android) string GetModel()
    @{
        return android.os.Build.MODEL;
    @}

    [Foreign(Language.Java)]
    private static extern(Android) string GetSystem()
    @{
        if (android.os.Build.MANUFACTURER.equals("Amazon")) {
            return "AmazonFireOS";
        }
        return "Android";
    @}

    [Foreign(Language.Java)]
    private static extern(Android) string GetSystemVersion()
    @{
        return android.os.Build.VERSION.RELEASE;
    @}

    [Foreign(Language.Java)]
    private static extern(Android) string GetSDKVersion()
    @{
        return android.os.Build.VERSION.SDK;
    @}


    [Foreign(Language.Java)]
    private static extern(Android) int GetNumProcessorCores()
    @{
        if (android.os.Build.VERSION.SDK_INT >= 17) {
            return Runtime.getRuntime().availableProcessors();
        } else {
            try {
                int cores = 1;
                Process proc = Runtime.getRuntime().exec("/usr/bin/nproc");
                BufferedReader input = new BufferedReader(new InputStreamReader(proc.getInputStream()));

                String line;
                while ((line = input.readLine()) != null)
                    cores = line.length() > 0 ? Integer.parseInt(line) : 1;

                input.close();
                proc.waitFor();
                return cores;

            } finally {
                return 1;
            }
        }
    @}


    // Preview's implementations

    private static extern(!(iOS || Android)) string GetVendor() {
        return "Fusetools";
    }

    private static extern(!(iOS || Android)) string GetModel() {
		return "Preview";
    }

    private static extern(!(iOS || Android)) string GetSystem() {
        return "Fuse";
    }

    private static extern(!(iOS || Android)) string GetSystemVersion() {
        return "";
    }

    private static extern(!(iOS || Android)) string GetSDKVersion() {
        return "";
    }

    private static extern(!(iOS || Android)) uint GetNumProcessorCores() {
        return 1;
    }
}
