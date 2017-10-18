#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend default {
  .host = "backend-host";
  .port = "80";
}

acl purge {
  "localhost";
  "127.0.0.1";
  "172.0.0.0"/8;
}

sub vcl_recv {
  set req.backend_hint = default;
  set req.http.X-Forwarded-Proto = "http";
  set req.http.Cache-Control = "max-age=86400, public=true";
  unset req.http.Accept-Language;
  unset req.http.User-Agent;
  unset req.http.cookie;
  unset req.http.Vary;

  if (req.method == "PURGE") {
    if (!client.ip ~ purge) {
      return(synth(405,"Not allowed."));
    }

    return (purge);
  }

  return(hash);
}

sub vcl_hash {
  hash_data(req.url);
  if (req.http.X-Forwarded-For ~ "67\.249\.255\..*") {
    hash_data("blacklist");
  }

  return (lookup);
}

# Drop any cookies Wordpress tries to send back to the client.
sub vcl_backend_response {
  set beresp.http.X-Cacheable = "yes";
  set beresp.http.X-Forwarded-For = bereq.http.X-Forwarded-For;
  set beresp.do_esi = false;
  unset beresp.http.set-cookie;
  unset beresp.http.cookie;

  if (bereq.http.X-Forwarded-For ~ "67\.249\.255\..*") {
    set beresp.do_esi = false;
  }

  set beresp.http.Cache-Control = "max-age=86400, public=true";
  set beresp.ttl = 1h;
  set beresp.grace = 1h;
}


sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
  set resp.http.Access-Control-Allow-Origin = "*";
}
sub vcl_hit {
  if (req.method == "PURGE") {
    return(synth(200,"OK"));
  }
}

sub vcl_miss {
  if (req.method == "PURGE") {
    return(synth(404,"Not cached"));
  }
}
