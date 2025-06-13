#!/bin/bash

# 定義你的專案路徑 (請根據你 Mac Mini 上的實際路徑調整)
# 確保這是包含你的 .xcodeproj 或 .xcworkspace 檔案的資料夾
PROJECT_DIR="/Users/adonis/Documents/personal-asset-management" 

# 定義你的專案名稱，通常和 .xcodeproj 檔案名相同 (不含副檔名)
PROJECT_NAME="個人資產管理" # 如果你的專案名叫 "personal-asset-management"，這裡就填 "personal-asset-management"

# 定義要運行應用程式的 Scheme 名稱
# 這通常是你的專案名稱，或者你自定義的 Scheme 名稱
SCHEME_NAME="$PROJECT_NAME" 

# 定義模擬器名稱 (可選，如果沒有特定偏好，xcodebuild會選一個預設的)
# 例如: "iPhone 15 Pro" 或 "iPhone 14 Pro Max"
SIMULATOR_NAME="iPhone 15 Pro" 

# --- 以下是腳本執行部分，通常不需要修改 ---

echo "正在進入專案目錄: $PROJECT_DIR"
cd "$PROJECT_DIR" || { echo "錯誤: 無法進入專案目錄 $PROJECT_DIR"; exit 1; }

echo "正在清除 Xcode 衍生數據 (DerivedData)..."
# 找到並刪除專案特定的 DerivedData 資料夾
# 或者你可以直接刪除所有 DerivedData (較慢但更徹底)
# rm -rf ~/Library/Developer/Xcode/DerivedData/*
PROJECT_DERIVED_DATA_PATH="$(xcodebuild -workspace "$PROJECT_NAME.xcworkspace" -scheme "$SCHEME_NAME" -showBuildSettings | grep -oE 'BUILD_DIR = .*' | awk '{ print $3 }' | sed 's/\(.*\)\/Build\/Products/\1\/Build\/Intermediates.noindex/')"
if [ -d "$PROJECT_DERIVED_DATA_PATH" ]; then
    echo "正在刪除: $PROJECT_DERIVED_DATA_PATH"
    rm -rf "$PROJECT_DERIVED_DATA_PATH"
else
    echo "未找到專案特定的 DerivedData，跳過清理。"
fi
# 確保清理用戶數據
echo "正在清理 Xcode 用戶數據..."
if [ -d "$PROJECT_NAME.xcodeproj/xcuserdata" ]; then
    rm -rf "$PROJECT_NAME.xcodeproj/xcuserdata"
    echo "已刪除 $PROJECT_NAME.xcodeproj/xcuserdata"
fi


echo "正在構建專案: $PROJECT_NAME (Scheme: $SCHEME_NAME)..."
# 使用 xcodebuild 構建專案
# -workspace 用於 .xcworkspace 檔案 (Podfile 專案常見)
# -project 用於 .xcodeproj 檔案 (如果沒有 Podfile)
# 優先使用 .xcworkspace
if [ -d "$PROJECT_NAME.xcworkspace" ]; then
    BUILD_COMMAND="xcodebuild -workspace \"$PROJECT_NAME.xcworkspace\" -scheme \"$SCHEME_NAME\" -destination \"platform=iOS Simulator,name=$SIMULATOR_NAME\" build"
else
    BUILD_COMMAND="xcodebuild -project \"$PROJECT_NAME.xcodeproj\" -scheme \"$SCHEME_NAME\" -destination \"platform=iOS Simulator,name=$SIMULATOR_NAME\" build"
fi

eval $BUILD_COMMAND

if [ $? -ne 0 ]; then
    echo "錯誤: 專案構建失敗。"
    exit 1
fi

echo "構建成功，正在運行應用程式..."
# 運行應用程式 (假設你構建的是到模擬器)
xcrun simctl launch booted "$(osascript -e 'id of app "'$PROJECT_NAME'"')" 2>/dev/null || \
xcrun simctl launch booted "$(xcodebuild -workspace "$PROJECT_NAME.xcworkspace" -scheme "$SCHEME_NAME" -showBuildSettings | grep -oE 'PRODUCT_BUNDLE_IDENTIFIER = .*' | awk '{ print $3 }')"

echo "應用程式運行完畢。"
