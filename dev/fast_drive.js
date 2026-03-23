Java.perform(function() {
    console.log("[*] Ultra-Fast Drive Automation Engine v2 Active");

    const View = Java.use("android.view.View");
    var clickedTags = {};

    function tryClick(view, identifier) {
        if (clickedTags[identifier]) return;
        
        console.log("[+] Auto-Clicking: " + identifier);
        view.performClick();
        clickedTags[identifier] = true;
        
        // 10초 후 초기화
        setTimeout(function() { delete clickedTags[identifier]; }, 10000);
    }

    // [방법 1] 화면 전수 조사 (Polling) - 떠 있는 팝업 처리용
    function scanAndClick() {
        Java.choose("android.view.View", {
            onMatch: function(view) {
                try {
                    var text = "";
                    if (view.getText) text = view.getText().toString();
                    var desc = "";
                    if (view.getContentDescription) desc = view.getContentDescription().toString();
                    
                    if (text === "확인" || text === "시작") {
                        tryClick(view, "Button_" + text);
                    } else if (desc === "Open navigation drawer") {
                        tryClick(view, "Menu_Drawer");
                    } else if (text === "북마크" || text === "경로" || text === "Target_Route_01") {
                        tryClick(view, "Item_" + text);
                    }
                } catch(e) {}
            },
            onComplete: function() {}
        });

        // ImageButton 전용 스캔 (Play 버튼용)
        Java.choose("android.widget.ImageButton", {
            onMatch: function(view) {
                try {
                    var resId = view.getResources().getResourceName(view.getId());
                    if (resId.includes("start_continuous_button")) {
                        tryClick(view, "Play_Button");
                    }
                } catch(e) {}
            },
            onComplete: function() {}
        });
    }

    // [방법 2] 뷰 생성 시 즉시 반응 (Event-based)
    View.onAttachedToWindow.implementation = function() {
        this.onAttachedToWindow();
        var view = this;
        setTimeout(function() {
            try {
                var text = "";
                if (view.getText) text = view.getText().toString();
                if (text === "확인" || text === "시작") {
                    tryClick(view, "Instant_Button_" + text);
                }
            } catch(e) {}
        }, 100);
    };

    // 0.5초마다 무한 스캔 시작
    setInterval(scanAndClick, 500);
    console.log("[*] Scanner Thread Started.");
});
