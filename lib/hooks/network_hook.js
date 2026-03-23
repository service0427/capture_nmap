/* 
   Network Hook & Bypass (Frida) - ROBUST SSL BYPASS (Yesterday's Stable Version)
   - Bypasses SSL Pinning (Native + OkHttp3 + TrustManager + SSLContext)
   - NO Header Injection (Handled by mitmproxy)
   - NO Body Injection
   - Essential for "Network Connection Not Smooth" fix
*/

console.log("[*] Network Hook Script Loaded (Robust SSL Bypass)");

// =======================================================================
// Native Hooks
// =======================================================================
function hook_native_ssl() {
    var modules = Process.enumerateModules();
    modules.forEach(function (m) {
        var name = m.name.toLowerCase();
        if (name === "libssl.so" || name === "libboringssl.so") {
            try {
                var exports = m.enumerateExports();
                exports.forEach(function (exp) {
                    var n = exp.name;
                    if (n.indexOf("SSL_CTX_set_custom_verify") !== -1 || n.indexOf("SSL_set_custom_verify") !== -1 || n.indexOf("SSL_set_verify") !== -1) {
                        try {
                            Interceptor.attach(exp.address, { onEnter: function (args) { args[1] = ptr(0); } });
                        } catch (e) { }
                    }
                    if (n === "SSL_get_verify_result") {
                        try {
                            Interceptor.replace(exp.address, new NativeCallback(function (ssl) { return 0; }, 'long', ['pointer']));
                        } catch (e) { }
                    }
                });
            } catch (e) { }
        }
    });
}

// =======================================================================
// Java Hooks (Robust TrustManager Bypass)
// =======================================================================
function hook_java_all() {
    if (!Java.available) {
        console.log("[-] Java not available.");
        return;
    }

    Java.perform(function () {
        console.log("[*] In Java.perform - Initializing Robust SSL Hooks...");

        // --- 1. TrustManager Implementation (The Core Bypass) ---
        var X509TrustManager = Java.use('javax.net.ssl.X509TrustManager');
        var SSLContext = Java.use('javax.net.ssl.SSLContext');

        // Build a Permissive TrustManager
        var TrustManager = Java.registerClass({
            name: 'com.example.TrustManager',
            implements: [X509TrustManager],
            methods: {
                checkClientTrusted: function (chain, authType) { },
                checkServerTrusted: function (chain, authType) { },
                getAcceptedIssuers: function () { return []; }
            }
        });

        // Loop through TrustManagers to disable checkServerTrusted
        try {
            var TrustManagerImpl = Java.use('com.android.org.conscrypt.TrustManagerImpl');
            TrustManagerImpl.verifyChain.implementation = function (untrustedChain, trustAnchorChain, host, clientAuth, ocspData, tlsSctData) {
                return untrustedChain;
            };
            console.log("[+] Hooked TrustManagerImpl");
        } catch (e) { }

        // --- 2. SSLContext Hook ---
        try {
            var TrustManagers = [TrustManager.$new()];
            var SSLContext_init = SSLContext.init.overload('[Ljavax.net.ssl.KeyManager;', '[Ljavax.net.ssl.TrustManager;', 'java.security.SecureRandom');
            SSLContext_init.implementation = function (keyManager, trustManager, secureRandom) {
                SSLContext_init.call(this, keyManager, TrustManagers, secureRandom);
            };
            console.log("[+] Hooked SSLContext.init");
        } catch (e) { }

        // --- 3. OkHttp3 CertificatePinner Bypass ---
        try {
            var CertificatePinner = Java.use("okhttp3.CertificatePinner");
            CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function (hostname, certs) {
                return;
            };
            console.log("[+] Hooked okhttp3.CertificatePinner");
        } catch (e) {
            // Silently fail: Already handled by TrustManager hooks
        }

    });
}

hook_native_ssl();
setTimeout(hook_java_all, 500);
