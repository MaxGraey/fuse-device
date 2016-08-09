using Uno;
using Uno.UX;
using Uno.Text;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;

[ForeignInclude(Language.Java, "android.app.Activity",
                               "android.content.Intent",
                               "java.lang.Object",
                               "java.util.regex",
                               "java.util.Locale")]

[UXGlobalModule]
[UXGlobalResource("Device")]
public sealed class Device : NativeModule {
    static readonly Device _instance;

    public Device() {
        if (_instance != null) return;
        Resource.SetGlobalKey(_instance = this, "Device");
        AddMember(new NativeProperty< string, object >("UUID", UUID));
        AddMember(new NativeProperty< string, object >("locale", GetCurrentLocale)); // return [language]-[region]-[variants] (e.g. zh-US-Hans, en-US, etc.)
    }

    // UUID platform specific implementations
    [Foreign(Language.Java)]
    public static extern(Android) string UUID()
    @{
        android.app.Activity context = com.fuse.Activity.getRootActivity();
        return android.provider.Settings.Secure.getString(context.getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
    @}

    [Foreign(Language.ObjC)]
    public static extern(iOS) string UUID()
    @{
        return [NSUUID.UUID UUIDString]; // iOS >= 6.x
    @}


    public static extern(!(iOS || Android)) string UUID() {
        // non-safe UUID version. According to RFC 4122 version 4
        Random rnd = new Random(43812467);
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
	public static extern(iOS) string GetCurrentLocale()
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
		return "Default";
    }
}
