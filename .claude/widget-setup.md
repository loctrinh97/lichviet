# Widget Extension — Xcode Setup

The Swift widget code is in `ios/LichVietWidget/`. It needs to be wired into Xcode manually (one-time setup, can't be done from CLI).

## Steps

1. **Open Xcode**: `open ios/Runner.xcworkspace`

2. **Add Widget Extension target**:
   - File → New → Target → Widget Extension
   - Product Name: `LichVietWidget`
   - Uncheck "Include Configuration App Intent"
   - Finish → Activate (the scheme prompt)

3. **Replace generated Swift file**:
   - Delete the auto-generated `LichVietWidget.swift` Xcode created
   - Add the existing `ios/LichVietWidget/LichVietWidget.swift` to the target

4. **Set Bundle ID** for the widget target:
   - Select `LichVietWidget` target → General → Bundle Identifier:
     `com.example.mobile_base.LichVietWidget`

5. **Add App Group** to BOTH targets (Runner + LichVietWidget):
   - Select target → Signing & Capabilities → + Capability → App Groups
   - Add: `group.com.example.mobile_base.lichviet`
   - Entitlements files are already created at:
     - `ios/Runner/Runner.entitlements`
     - `ios/LichVietWidget/LichVietWidget.entitlements`

6. **home_widget iOS pod**: Already added via `pubspec.yaml`. Run:
   ```bash
   cd ios && pod install
   ```

7. **Build & Run** — the widget appears in iPhone widget gallery under "Lịch Việt".

## Widget sizes supported

| Family              | Description                        |
|---------------------|------------------------------------|
| `systemSmall`       | Home screen small (dark card)      |
| `accessoryCircular` | Lock screen circular (day + lunar) |
| `accessoryRectangular` | Lock screen wide (full row)     |

## Data flow

`AppViewModel._init()` → `WidgetService.updateWidget()` → shared `UserDefaults(suiteName:)` → `LichVietProvider.entry()` → widget reloads timeline
