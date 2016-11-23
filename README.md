fuse-device
============

Use the basic Device functions such as UUID and current localization from Fuse.


## Installation

Using [fusepm](https://github.com/bolav/fusepm)

    $ fusepm install https://github.com/MaxGraey/fuse-device

Or manually copy **Device.uno** to your project and add link in .unoproj.
See example: https://github.com/MaxGraey/fuse-device/tree/master/example

### Support
- **iOS**
- **Android**
- **Preview**


### JavaScript

```js
    var Device = require('Device');

    console.log('Current device language: ' + Device.locale); // format in BCP-47 for all mobile platforms
    // output example: en-US
    
    console.log('Device UUID: '             + Device.UUID);
     // output example:
    // ios/android/preview: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

    console.log('Vendor name: '        + Device.vendor);
    console.log('Model name: '         + Device.model);
    console.log('System: '             + Device.system);
    console.log('System version: '     + Device.systemVersion);
    console.log('System SDK ver: '     + Device.SDKVersion);
    console.log('Logical processors: ' + Device.cores);
    console.log('is retina?: '         + Device.isRetina);
```
