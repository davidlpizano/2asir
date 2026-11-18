vcl 4.1;

backend apache_m1 {
    .host = "172.31.16.51";
    .port = "80";
    .connect_timeout = 3s;
    .first_byte_timeout = 10s;
    .between_bytes_timeout = 5s;
    .probe = {
        .url = "/";
        .interval = 5s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}

acl purge_acl {
    "localhost";
    "127.0.0.1";
    "172.31.16.51";
}

sub vcl_recv {
    set req.backend_hint = apache_m1;

    if (req.method == "PURGE") {
        if (!client.ip ~ purge_acl) {
            return (synth(405, "Method Not Allowed"));
        }
        return (purge);
    }

    if (req.http.Host ~ "^davidservicios\.ddns\.net(:[0-9]+)?$") {
        set req.http.Host = "172.31.16.51";
    }
}

sub vcl_backend_response {
    if (beresp.ttl <= 0s && beresp.http.Cache-Control !~ "no-cache|no-store|private") {
        set beresp.ttl = 120s;
    }
    set beresp.grace = 30s;
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    set resp.http.X-Cache-Hits = obj.hits;
}
