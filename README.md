fuse-device
============

Use the basic Device functions such as UUID and current localization from Fuse.


## Installation

Using [fusepm](https://github.com/bolav/fusepm)

    $ fusepm install https://github.com/MaxGraey/fuse-device

### Support
- **iOS**
- **Android**
- **Preview**


### JavaScript

```js
    var Device = require('Device');

    console.log('Current device language: ' + Device.locale); // format in BCP-47 for all platforms
    console.log('Device UUID: ' + Device.UUID);

    console.log('Vendor name: ' + Device.vendor);
    console.log('Model name: '  + Device.model);
    console.log('Model name: '  + Device.system);
    console.log('Model name: '  + Device.systemVersion);
```
