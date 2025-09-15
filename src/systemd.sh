install_service() {
    # Check if we're using Alpine Linux (using OpenRC)
    if [[ $(type -P apk) ]]; then
        # Alpine Linux with OpenRC
        case $1 in
        $is_core)
            is_doc_site=https://sing-box.sagernet.org/
            cat >/etc/init.d/$is_core <<<"
#!/sbin/openrc-run

name=\"$is_core_name Service\"
description=\"$is_core_name Service\"
doc=\"$is_doc_site\"

command=\"$is_core_bin\"
command_args=\"run -c $is_config_json -C $is_conf_dir\"
command_background=true
pidfile=\"/run/$is_core.pid\"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --owner root:root --mode 0755 /run
}"
            chmod +x /etc/init.d/$is_core
            ;;
        caddy)
            cat >/etc/init.d/caddy <<<"
#!/sbin/openrc-run

name=\"Caddy\"
description=\"Caddy Web Server\"
doc=\"https://caddyserver.com/docs/\"

command=\"$is_caddy_bin\"
command_args=\"run --environ --config $is_caddyfile --adapter caddyfile\"
command_background=true
pidfile=\"/run/caddy.pid\"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath --directory --owner root:root --mode 0755 /run
}"
            chmod +x /etc/init.d/caddy
            ;;
        esac

        # enable service
        rc-update add $1 default
    else
        # Systemd-based systems
        case $1 in
        $is_core)
            is_doc_site=https://sing-box.sagernet.org/
            cat >/lib/systemd/system/$is_core.service <<<"
[Unit]
Description=$is_core_name Service
Documentation=$is_doc_site
After=network.target nss-lookup.target

[Service]
#User=nobody
User=root
NoNewPrivileges=true
ExecStart=$is_core_bin run -c $is_config_json -C $is_conf_dir
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target"
            ;;
        caddy)
            cat >/lib/systemd/system/caddy.service <<<"
#https://github.com/caddyserver/dist/blob/master/init/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart=$is_caddy_bin run --environ --config $is_caddyfile --adapter caddyfile
ExecReload=$is_caddy_bin reload --config $is_caddyfile --adapter caddyfile
TimeoutStopSec=5s
LimitNPROC=10000
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target"
            ;;
        esac

        # enable, reload
        systemctl enable $1
        systemctl daemon-reload
    fi
}
