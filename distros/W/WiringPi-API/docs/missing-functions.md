# Missing WiringPi Function Wrappers

Generated: 2026-06-10

This lists every function declared in the WiringPi library headers that does
**not** have a corresponding wrapper in this distribution's `API.xs`.

## Scope

- Source: `~/repos/WiringPi` — library headers under `wiringPi/*.h` and `devLib/*.h`.
- Wrappers checked: the XS functions defined in `API.xs`.
- Not scanned: the `gpio` tool, `wiringPiD` daemon headers, `examples/`, test
  headers, and pure data/register headers (`font.h`, `scrollPhatFont.h`,
  `mcp23016reg.h`, `mcp23x08.h`, `mcp23x0817.h`).

## Summary

- Functions found in headers: **183**
- Already wrapped: **92**
- Missing wrappers: **91** (across 35 headers)

One function is wrapped under a different XS name and is therefore **not**
listed as missing:

- `wiringPiSPIDataRW` → wrapped by `spiDataRW`

`wiringPiISR` and `piThreadCreate` have **no** wrapper — the XS names once
claimed to wrap them never existed, and the interrupt path uses `wiringPiISR2`
(which *is* wrapped) instead. Both are listed as missing below.

---

## devLib/ds1302.h

- `ds1302clockRead`
- `ds1302clockWrite`
- `ds1302ramRead`
- `ds1302ramWrite`
- `ds1302rtcRead`
- `ds1302rtcWrite`
- `ds1302setup`
- `ds1302trickleCharge`

## devLib/gertboard.h

- `gertboardAnalogRead`
- `gertboardAnalogSetup`
- `gertboardAnalogWrite`
- `gertboardSPISetup`

## devLib/lcd.h

- `lcdPrintf`

## devLib/lcd128x64.h

- `lcd128x64circle`
- `lcd128x64clear`
- `lcd128x64ellipse`
- `lcd128x64getScreenSize`
- `lcd128x64line`
- `lcd128x64lineTo`
- `lcd128x64orientCoordinates`
- `lcd128x64point`
- `lcd128x64putchar`
- `lcd128x64puts`
- `lcd128x64rectangle`
- `lcd128x64setOrientation`
- `lcd128x64setOrigin`
- `lcd128x64setup`
- `lcd128x64update`

## devLib/maxdetect.h

- `maxDetectRead`
- `readRHT03`

## devLib/piFace.h

- `piFaceSetup`

## devLib/piGlow.h

- `piGlow1`
- `piGlowLeg`
- `piGlowRing`
- `piGlowSetup`

## devLib/piNes.h

- `readNesJoystick`
- `setupNesJoystick`

## devLib/scrollPhat.h

- `scrollPhatClear`
- `scrollPhatIntensity`
- `scrollPhatLine`
- `scrollPhatLineTo`
- `scrollPhatPoint`
- `scrollPhatPrintSpeed`
- `scrollPhatPrintf`
- `scrollPhatPutchar`
- `scrollPhatPuts`
- `scrollPhatRectangle`
- `scrollPhatSetup`
- `scrollPhatUpdate`

## wiringPi/drcNet.h

- `drcSetupNet`

## wiringPi/drcSerial.h

- `drcSetupSerial`

## wiringPi/ds18b20.h

- `ds18b20Setup`

## wiringPi/htu21d.h

- `htu21dSetup`

## wiringPi/max31855.h

- `max31855Setup`

## wiringPi/max5322.h

- `max5322Setup`

## wiringPi/mcp23008.h

- `mcp23008Setup`

## wiringPi/mcp23016.h

- `mcp23016Setup`

## wiringPi/mcp23017.h

- `mcp23017Setup`

## wiringPi/mcp23s08.h

- `mcp23s08Setup`

## wiringPi/mcp23s17.h

- `mcp23s17Setup`

## wiringPi/mcp3002.h

- `mcp3002Setup`

## wiringPi/mcp3004.h

- `mcp3004Setup`

## wiringPi/mcp3422.h

- `mcp3422Setup`

## wiringPi/mcp4802.h

- `mcp4802Setup`

## wiringPi/pcf8574.h

- `pcf8574Setup`

## wiringPi/pcf8591.h

- `pcf8591Setup`

## wiringPi/rht03.h

- `rht03Setup`

## wiringPi/sn3218.h

- `sn3218Setup`

## wiringPi/softServo.h

- `softServoSetup`
- `softServoWrite`

## wiringPi/wiringPi.h

- `piBoardRev`
- `piGpioLayoutOops`
- `piThreadCreate`
- `waitForInterrupt2`
- `waitForInterruptClose`
- `wiringPiFailure`
- `wiringPiFindNode`
- `wiringPiISR`
- `wiringPiNewNode`
- `wiringPiSetupPiFace`
- `wiringPiSetupPiFaceForGpioProg`

## wiringPi/wiringPiLegacy.h

- `GetPiRevisionLegacy`

## wiringPi/wiringPiSPI.h

- `wiringPiSPIxClose`
- `wiringPiSPIxDataRW`
- `wiringPiSPIxGetFd`
- `wiringPiSPIxSetup`
- `wiringPiSPIxSetupMode`

## wiringPi/wiringSerial.h

- `serialPrintf`

## wiringPi/wiringShift.h

- `shiftIn`
- `shiftOut`

## wiringPi/wpiExtensions.h

- `loadWPiExtension`

